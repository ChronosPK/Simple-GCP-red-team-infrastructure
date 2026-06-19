# Student Lab Guide

This handout explains how to enroll, connect, verify access, use the lab, and disconnect.

## What you receive

The instructor sends each student:

- one WireGuard configuration file named for that student, such as `student01.conf`;
- the internal lab URL;
- one personal Mythic username and temporary password;
- the authorized lab time, assigned operation, and exercise instructions.

Your VPN profile and Mythic account are assigned only to you. Do not share them.

## What the lab contains

After connecting to WireGuard, you can access the following:

| Resource | Address | Student access |
| --- | --- | --- |
| WireGuard gateway | Public endpoint in your profile | UDP/51820, used by the VPN application |
| Nginx redirector | URL supplied by the instructor | HTTPS/443 and ICMP |
| Mythic web interface | Reached through the redirector | Log in with your individual Mythic account |
| Mythic team server | Private GCP address | No direct student access |
| Other students | Individual WireGuard addresses | No access |
| Administrative SSH | GCP IAP only | No student access |

This is a split-tunnel VPN. Only traffic for the lab subnet, currently `10.20.0.0/24`, uses the
VPN. Your normal internet traffic does not pass through the lab.

The base deployment does **not** include a target or victim machine. Do not scan the lab subnet
looking for one. If an exercise requires a target, payload execution, or an agent callback, the
instructor must give you a specific authorized target and scope.

## 1. Install WireGuard

Install the official WireGuard client for your operating system:

- Windows or macOS: install the WireGuard application;
- Linux: install the `wireguard-tools` package, which provides `wg` and `wg-quick`.

Do not use a shared computer account for this lab. Store all lab files in a folder that only your
local user can read.

## 2. Generate your WireGuard key pair

The private key proves your identity to the VPN. Generate it on your own computer and never send
it to anyone, including the instructor.

On Linux, macOS, or Windows Subsystem for Linux:

```bash
umask 077
wg genkey | tee student.key | wg pubkey > student.pub
```

This creates:

- `student.key`: your **private key**; keep it on your computer;
- `student.pub`: your **public key**; submit this to the instructor.

Display the public key when needed:

```bash
cat student.pub
```

If you use the WireGuard GUI to generate a tunnel, copy only the displayed public key. Do not
copy or photograph the private key.

## 3. Submit your public key

Use the Google Form, LMS assignment, or other private intake method chosen by the instructor.
Submit:

- your full name;
- your course email address;
- your assigned student ID or lab username, if provided;
- the single-line contents of `student.pub`;
- your operating system.

A valid WireGuard public key is a 44-character base64 value and normally ends with `=`.

Public keys are not passwords, but submit yours only through the designated intake method. Do
not paste keys into a class chat or edit another student's roster entry.

## 4. Complete your configuration

The instructor returns a file such as `student01.conf`. Open it in a plain-text editor and find:

```text
PrivateKey = REPLACE_WITH_STUDENT_PRIVATE_KEY
```

Replace only `REPLACE_WITH_STUDENT_PRIVATE_KEY` with the single-line contents of `student.key`.
Do not add quotation marks or spaces.

The completed file contains your private key and must not be uploaded to Google Drive, a shared
sheet, chat, source control, or the LMS. Restrict its permissions on Linux or macOS:

```bash
chmod 600 student01.conf student.key
```

## 5. Connect

Windows or macOS:

1. Open WireGuard.
2. Import your completed `.conf` file as a tunnel.
3. Activate the tunnel.

Linux:

```bash
sudo wg-quick up ./student01.conf
```

Replace `student01.conf` with your actual filename.

## 6. Verify access

In the Windows or macOS application, confirm that the tunnel is active. After opening the lab
URL, the tunnel should show a recent handshake and transferred data.

On Linux, check the same information with:

```bash
sudo wg show
```

Then test only the redirector address supplied by the instructor:

```bash
curl -kI https://REDIRECTOR_IP/
```

Replace `REDIRECTOR_IP` with the instructor-provided address. A successful response normally
contains an HTTP status such as `200` or `302`.

If the VPN connects but the page does not load:

1. confirm the tunnel is active;
2. confirm the profile still contains `AllowedIPs = 10.20.0.0/24`;
3. confirm you used the assigned profile and did not alter its address;
4. send the instructor the time of the attempt and the non-secret output of `wg show`;
5. never send your private key or completed `.conf` file while troubleshooting.

## 7. Log in and perform the exercise

Open the internal URL supplied by the instructor. The redirector uses a self-signed certificate,
so a browser certificate warning is expected. Confirm that the URL exactly matches the address
provided by the instructor before accepting the warning.

Log in with your personal Mythic account and change the temporary password if instructed. Select
only the operation assigned to your class or group.

During the exercise:

- follow the written exercise and the instructor's scope exactly;
- use only explicitly assigned targets, payloads, and operations;
- label activity with your own account and do not use another student's session;
- record the requested evidence, commands, and observations for your lab report;
- stop immediately and notify the instructor if you see another student's credentials, session,
  files, or data.

The Mythic interface alone does not authorize testing any internet or university system.

## 8. Disconnect and clean up

Windows or macOS: deactivate the tunnel in the WireGuard application.

Linux:

```bash
sudo wg-quick down ./student01.conf
```

After the class:

- log out of Mythic;
- deactivate the VPN;
- retain or delete artifacts according to the instructor's course policy;
- delete the completed profile when the instructor says the cohort has ended;
- report a lost device or suspected key exposure immediately so access can be revoked.

## Rules of engagement

- Work only during the authorized dates and times.
- Use only targets explicitly named by the instructor.
- Do not scan the GCP metadata service, lab management hosts, other students, the university
  network, or the internet.
- Do not attempt SSH access or direct access to the private Mythic team server.
- Do not disable logging, conceal activity, create persistence, or change shared infrastructure.
- Do not copy payloads, credentials, or course data outside the approved lab storage.
- Stop and report unexpected access, exposed services, or scope ambiguity immediately.
