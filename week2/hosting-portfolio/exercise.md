# Week 2 — Host Your Portfolio on AWS

**Bootcamp:** July DevOps  
**Topic:** Static website on EC2 · Elastic IP · Route 53 · HTTPS with Certbot  
**Repo path:** `week2/hosting-portfolio/`  
**Class:** Jul 26, 2026

---

## Overview

Host your **personal portfolio** on a public EC2 instance with a **fixed IP**, map it to a **domain name**, and enable **HTTPS**.

This is a simple, low-cost setup — perfect for a blog or portfolio. You do **not** need load balancers or multi-AZ HA for this use case.

**Files in this folder:**

| File | Purpose |
|------|---------|
| `portfolio.html` | Your portfolio page — customize with your name, bio, and social links |
| `user-data.sh` | EC2 user-data script (auto-install nginx, git, certbot on launch) |
| `nginx.conf` | Example nginx SSL config (reference after certbot) |
| `readme.md` | Quick command reference from class |

---

## What You Will Build

```
Internet → Route 53 (your domain) → Elastic IP → EC2 (public subnet) → nginx → portfolio.html
                                                                              ↓
                                                                    HTTPS via Let's Encrypt
```

**AWS pieces:**

- VPC with **public subnet** + Internet Gateway + route table
- EC2 instance in public subnet
- **Elastic IP** (static public IP for DNS)
- Security group: SSH (22), HTTP (80), HTTPS (443)
- **Route 53** hosted zone + A record
- **Certbot** for free SSL certificate

---

## Prerequisites

- [ ] Custom VPC from Week 2 networking class (or default VPC for practice)
- [ ] Public subnet with route `0.0.0.0/0` → Internet Gateway
- [ ] SSH key pair (`.pem` file)
- [ ] Security group with port **22** open (your IP or `0.0.0.0/0` for lab)
- [ ] A **domain name** (~$1–2/year from GoDaddy, Namecheap, etc.)
- [ ] Your own `portfolio.html` (edit the template or create one with ChatGPT/Cursor)

---

## Part 1 — Prepare Your Portfolio

### Step 1.1: Customize `portfolio.html`

1. Open `portfolio.html` in this folder.
2. Replace name, bio, skills, and social links with **your** details.
3. Keep it as a single static HTML file (no backend needed).

**Deliverable:** Portfolio HTML ready to deploy.

---

## Part 2 — Launch EC2 with User Data

User data runs a bash script **automatically** when the instance first boots.

### Step 2.1: Review `user-data.sh`

```bash
cat user-data.sh
```

Important from class:

- Use **`yum`** on Amazon Linux — **not** `apt` (Ubuntu package manager).
- Order: install nginx → start → enable → install git → install certbot.

### Step 2.2: Launch the instance

1. EC2 Console → **Launch instance**
2. Name: `portfolio`
3. AMI: **Amazon Linux 2023** (or Amazon Linux 2)
4. Instance type: `t2.micro` or `t3.micro`
5. Key pair: your existing `.pem`
6. Network:
   - VPC: your custom VPC
   - Subnet: **public subnet** (subnet with IGW route)
   - Auto-assign public IP: **Enable** (you will attach Elastic IP later)
7. Security group: allow **SSH (22)** for now
8. Advanced details → **User data** → paste contents of `user-data.sh`
9. Launch

### Step 2.3: Verify user-data ran

SSH into the instance and check logs:

```bash
ssh -i ~/path/to/key.pem ec2-user@<PUBLIC_IP>

sudo cat /var/log/cloud-init-output.log
```

Look for nginx and certbot installation. If you see `command not found: apt`, fix `user-data.sh` to use `yum` and relaunch.

**Deliverable:** Screenshot or note confirming nginx installed (`curl localhost` shows default nginx page).

---

## Part 3 — Deploy Portfolio to nginx

### Step 3.1: Copy HTML to the server

**Option A — SCP from your laptop:**

```bash
scp -i ~/path/to/key.pem portfolio.html ec2-user@<PUBLIC_IP>:/home/ec2-user/
```

**Option B — Clone repo on EC2 (as in class):**

```bash
git clone https://github.com/akhileshmishrabiz/july-devops.git
cp july-devops/week2/hosting-portfolio/portfolio.html .
```

### Step 3.2: Replace default nginx page

```bash
sudo cp portfolio.html /usr/share/nginx/html/index.html
sudo systemctl reload nginx
```

Verify locally on the server:

```bash
curl localhost
```

You should see your portfolio HTML content.

### Step 3.3: Open HTTP in security group

Add inbound rule:

| Type | Port | Source |
|------|------|--------|
| HTTP | 80 | 0.0.0.0/0 |

Open `http://<PUBLIC_IP>` in your browser — portfolio should load.

**Deliverable:** Browser screenshot of portfolio via public IP.

---

## Part 4 — Attach Elastic IP

Temporary public IPs change when you stop/start the instance. DNS needs a **fixed** IP.

1. EC2 → **Elastic IPs** → **Allocate**
2. Select the new IP → **Actions** → **Associate Elastic IP address**
3. Choose your `portfolio` instance and its private IP
4. Confirm — browse `http://<ELASTIC_IP>` — same site should load

**Why Elastic IP?** If the IP changes, your Route 53 A record breaks. Elastic IP stays fixed until you release it.

**Note:** Release unused Elastic IPs to avoid charges.

**Deliverable:** Site working on Elastic IP.

---

## Part 5 — DNS with Route 53

### Step 5.1: Create hosted zone

1. AWS Console → **Route 53** → **Hosted zones** → **Create hosted zone**
2. Domain name: `yourdomain.in` (your purchased domain)
3. Type: **Public hosted zone**
4. Create

Route 53 gives you **4 NS (name server) records**.

### Step 5.2: Point domain registrar to Route 53

At GoDaddy / Namecheap / your registrar:

1. Go to DNS / Name servers
2. Change to **custom name servers**
3. Paste all 4 NS values from Route 53
4. Save

Propagation can take **30 minutes to a few hours**.

### Step 5.3: Create A record

In Route 53 hosted zone:

1. **Create record**
2. Record name: leave **blank** for root domain (`yourdomain.in`)
3. Record type: **A**
4. Value: your **Elastic IP**
5. Create

After propagation, `http://yourdomain.in` should show your portfolio.

**Deliverable:** Browser screenshot of portfolio loading via domain name (HTTP).

---

## Part 6 — HTTPS with Certbot (Let's Encrypt)

### Step 6.1: Install certbot (if not in user-data)

```bash
sudo yum install -y certbot python3-certbot-nginx
```

### Step 6.2: Request certificate

Replace with **your** domain:

```bash
sudo certbot --nginx -d yourdomain.in -d www.yourdomain.in
```

- Enter email when prompted
- Agree to terms
- Certbot validates via **HTTP ACME challenge** — Let's Encrypt hits your server on port 80 to confirm you own the domain
- Port **80 must be open** and nginx must be serving your site

Certificates are saved at:

```
/etc/letsencrypt/live/yourdomain.in/fullchain.pem
/etc/letsencrypt/live/yourdomain.in/privkey.pem
```

Logs: `/var/log/letsencrypt/letsencrypt.log`

### Step 6.3: Open HTTPS in security group

| Type | Port | Source |
|------|------|--------|
| HTTPS | 443 | 0.0.0.0/0 |

### Step 6.4: Verify

Open `https://yourdomain.in` — padlock should appear (no "Not secure" warning).

If certbot fails to auto-configure nginx, see `nginx.conf` in this folder for SSL block reference. Update `server_name` and certificate paths to match your domain.

**Deliverable:** Browser screenshot of portfolio over **HTTPS**.

---

## Part 7 — Short Notes (from class)

Answer these in your notes:

1. **Why Elastic IP for DNS?** What happens if you use a temporary public IP and restart the EC2?
2. **What is an A record?** What does it map?
3. **What is the ACME HTTP challenge?** Why must port 80 be open during certbot?
4. **Security Group vs NACL** — which is stateful? Which works at resource vs subnet level?
5. **Why `yum` not `apt`** on Amazon Linux user-data?

---

## Submission Checklist

- [ ] Custom `portfolio.html` with your info and social links
- [ ] EC2 launched with `user-data.sh` — nginx running
- [ ] Portfolio deployed to `/usr/share/nginx/html/index.html`
- [ ] Elastic IP attached and site loads on fixed IP
- [ ] Domain purchased and NS pointed to Route 53
- [ ] A record → Elastic IP — site loads on domain (HTTP)
- [ ] Certbot SSL — site loads on HTTPS
- [ ] Security group: ports 22, 80, 443 configured
- [ ] Part 7 questions answered

---

## Quick Reference

| Task | Command / Location |
|------|-------------------|
| User-data logs | `sudo cat /var/log/cloud-init-output.log` |
| Default web root | `/usr/share/nginx/html/index.html` |
| Deploy portfolio | `sudo cp portfolio.html /usr/share/nginx/html/index.html` |
| Reload nginx | `sudo systemctl reload nginx` |
| SSL certbot | `sudo certbot --nginx -d yourdomain.in` |
| Cert files | `/etc/letsencrypt/live/yourdomain.in/` |
| Certbot logs | `/var/log/letsencrypt/letsencrypt.log` |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| User-data failed — `apt: command not found` | Use `yum` in `user-data.sh` (Amazon Linux) |
| nginx not found after user-data | Check cloud-init log; install manually with `sudo yum install nginx -y` |
| Browser can't reach site | Open HTTP (80) in security group; confirm public subnet + IGW route |
| Domain not resolving | Wait for NS propagation; verify NS at registrar match Route 53 |
| Certbot challenge fails | Domain must point to this EC2 Elastic IP; port 80 open; nginx running |
| HTTPS 403 error | Check nginx `root` path and file permissions on `index.html` |
| "Not secure" in browser | Complete Part 6; ensure port 443 open |

---

## Optional: NAT Gateway Recap (from class start)

If you did yesterday's VPC assignment, you can optionally verify:

- NAT Gateway in **public subnet** with Elastic IP
- Private subnet route table: `0.0.0.0/0` → NAT Gateway
- Private EC2 can run `sudo yum update` outbound only (no inbound from internet)

This is **not required** for the portfolio exercise — your portfolio EC2 lives in a **public subnet**.

---

## Next Class Preview

Architecture for **scaling**: Auto Scaling Groups, Application Load Balancer, RDS, multi-AZ HA. Today's simple single-EC2 setup is the foundation — complexity comes when the business needs it.

Good luck — get your portfolio live on HTTPS.
