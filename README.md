# Minimal GCP Red Team Classroom Lab

This repository provisions a small, internal-only teaching environment for 20–30 students:

- one WireGuard gateway with the only public IP;
- one private Nginx redirector;
- one private Mythic team server;
- IAP-only instructor SSH;
- per-student VPN peers and split-tunnel client profiles;
- VPC Flow Logs and Cloud NAT error logs.

The default deployment is intentionally not internet-facing C2 infrastructure. Students can
reach only the internal redirector over TCP/443. The team server has no public IP and accepts
the Mythic UI connection only from the redirector.

## Prerequisites

- a dedicated GCP project with billing enabled;
- `gcloud`, Terraform 1.8+, and WireGuard tools;
- permission to manage Compute Engine resources and use IAP;
- an instructor SSH key.

The instructor principal needs `roles/iap.tunnelResourceAccessor` plus OS Login permissions.
For an identity outside the GCP organization, an organization administrator must also grant
`roles/compute.osLoginExternalUser`. It also needs permission to enable project services during
the first apply.

Enable local Application Default Credentials:

```bash
gcloud auth application-default login
gcloud config set project csctf-2026
```

Generate the WireGuard server key pair:

```bash
./scripts/generate-wireguard-keypair.sh
export TF_VAR_wireguard_server_private_key="$(cat secrets/server.key)"
```

Create the variable file:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Set `project_id`, `admin_ssh_public_key`, and:

```hcl
wireguard_server_public_key = "value from secrets/server.pub"
```

## Documentation

- [Student lab guide](docs/STUDENT-ACCESS.md): key generation, connection, accessible network,
  troubleshooting, exercise boundaries, and disconnect steps.
- [Instructor runbook](docs/OPERATIONS.md): enrollment, Google Workspace intake, profile and
  credential delivery, class checklists, revocation, incidents, and teardown.
- [Architecture](docs/ARCHITECTURE.md): traffic paths and security boundaries.
- [Current deployment](docs/DEPLOYMENT.md): environment-specific addresses and verification.

The base deployment has no target/victim host. It gives students controlled access to the Mythic
web interface through the redirector. Exercises that require a callback or payload execution
need a separately provisioned, isolated, explicitly authorized target.

## Add students

Each student runs:

```bash
umask 077
wg genkey | tee student.key | wg pubkey > student.pub
```

They send only `student.pub` to the instructor through a private Google Form, LMS submission, or
equivalent authenticated intake channel. Do not request private keys. Add a unique peer to
`terraform/terraform.tfvars`:

```hcl
students = [
  {
    name       = "student01"
    public_key = "BASE64_PUBLIC_KEY"
    vpn_ip     = "10.20.100.10"
  }
]
```

The active variables file already reserves `student01` and `student02`. Paste each submitted
public key into the corresponding empty `public_key` field. Empty entries are ignored.

The current deployment uses `10.20.100.10` for the instructor. Use student addresses from
`10.20.100.11` onward.

## Deploy

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out lab.tfplan
terraform apply lab.tfplan
terraform output
```

Terraform renders profiles under `terraform/generated-clients/`. Deliver each template
individually through the LMS or another authenticated student-specific channel. Students replace
`REPLACE_WITH_STUDENT_PRIVATE_KEY` locally; the instructor never receives or stores student
private keys. Do not use a shared Google Sheet for private keys, completed profiles, or Mythic
passwords. See the [instructor runbook](docs/OPERATIONS.md) for a Google Form and private response
sheet workflow.

Changing the student list replaces the small VPN VM so its configuration remains declarative.
The reserved public IP stays unchanged. Expect a short VPN interruption during `terraform apply`.

Mythic installation can take 10–20 minutes after the VM is created. Check it with:

```bash
gcloud compute ssh labadmin@rt-lab-team-server \
  --zone europe-central2-a --tunnel-through-iap \
  --command 'sudo tail -f /var/log/redteam-lab-bootstrap.log'
```

After WireGuard connects, students open the `redirector_url` shown by `terraform output`.
The certificate is self-signed by design, so the browser will show a warning.

## Instructor access and initial Mythic account

Use the commands in `terraform output admin_commands`. On the team server:

```bash
cd /opt/mythic
sudo ./mythic-cli status
sudo grep '^MYTHIC_ADMIN_' .env
```

Log in through the internal redirector, change the generated administrator password, and create
one named Mythic operator account per student. Do not share the administrator account.

If `gcloud compute ssh` reports `importSshPublicKey` and asks for
`roles/compute.osLoginExternalUser`, project-level OS Login is enabled. An organization
administrator must grant that role at the organization level; project Owner cannot bypass it.

## Remove a student

Delete their object from `students`, then run `terraform apply`. Their WireGuard public key is
removed when the gateway is replaced. Disable or remove their Mythic operator account separately.

## Shut down

For a temporary pause, stop the three instances in GCP. Cloud NAT and the reserved external IP
can still incur small charges. For a complete teardown:

```bash
cd terraform
terraform destroy
```

Upstream documentation used for implementation decisions is listed in
[references](docs/REFERENCES.md).
