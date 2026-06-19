# Current Deployment

Provisioned in `csctf-2026` on June 19, 2026.

- Region: `europe-central2`
- Zone: `europe-central2-a`
- VPN endpoint: `34.0.246.103:51820`
- Private redirector: `https://10.20.0.4/`
- Private team server: `10.20.0.2`
- Mythic version: `v3.4.0.5`
- Terraform resources: 18 created

Confirmed:

- all three instances are running;
- WireGuard installed, enabled, and started;
- IP forwarding is enabled on the VPN gateway;
- the private route and restrictive firewall rules were created;
- the instructor profile was generated with fresh keys.

The local instructor profile is:

```text
terraform/generated-clients/instructor.conf
```

Connect:

```bash
./scripts/connect-instructor-vpn.sh
```

Open:

```text
https://10.20.0.4/new/login
```

The certificate warning is expected.

## Readiness verification

Mythic first boot can take several minutes. Confirm completion with:

```bash
gcloud compute instances get-serial-port-output rt-lab-team-server \
  --project csctf-2026 \
  --zone europe-central2-a \
  | grep -E 'Successfully queried the GraphQL|Finished running startup scripts'
```

Then test through WireGuard:

```bash
curl -kI https://10.20.0.4/new/login
```

A ready deployment returns HTTP `200`.

## Instructor administration

```bash
gcloud compute ssh rt-lab-team-server \
  --project csctf-2026 \
  --zone europe-central2-a \
  --tunnel-through-iap
```

On the server:

```bash
cd /opt/mythic
sudo ./mythic-cli status
sudo grep '^MYTHIC_ADMIN_' .env
```
