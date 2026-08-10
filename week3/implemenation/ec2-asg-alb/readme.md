# EC2 + ASG + ALB + RDS (Day 2 helpers)

**Full step-by-step lab:** [../exercise-day2.md](../exercise-day2.md)  
**App code:** `week3/src/`  
**Class:** Aug 9, 2026

---

## Files

| File | Purpose |
|------|---------|
| `user-data.sh` | Launch template user data (corrected) |
| `readme.md` | Quick reference |

---

## Corrected user data (summary)

- Bind app to **`0.0.0.0:8000`** (not 80)
- Target group: protocol HTTP, port **8000**, health path **`/health`**, success code **200**
- Private ASG subnets need **NAT Gateway** or `git` / `pip` fail
- Put real RDS endpoint in `DB_LINK` (do not commit production secrets)

```bash
export DB_LINK="postgresql://admin_user:Admin1234@<RDS_ENDPOINT>:5432/mydb"
nohup gunicorn run:app --bind 0.0.0.0:8000 > /var/log/flask-app.log 2>&1 &
```

---

## Build order (avoid class pitfalls)

1. Subnets: public ×2, private-app ×2, private-rds ×2 (two AZs)
2. IGW on public · **NAT** for private-app
3. Security groups: `sg-alb` → `sg-app:8000` → `sg-rds:5432`
4. RDS (private) + DB subnet group on RDS subnets
5. Launch template + `user-data.sh` + attach **`sg-app`**
6. **Smoke-test** one public instance from the template → `curl /health`
7. Target group (8000 + `/health`) → ALB (public) → listener :80 → TG
8. ASG (private-app) → attach **existing** TG · desired ≥ 2

---

## Verify

```bash
curl -s http://<ALB_DNS>/health
# {"status":"healthy","database":"connected"}
```

Cloud-init / app logs on an instance:

```bash
sudo cat /var/log/cloud-init-output.log
sudo tail -100 /var/log/flask-app.log
```

---

## Common failures

| Issue | Fix |
|-------|-----|
| Unhealthy targets | TG port 8000 + path `/health` |
| git clone fails in ASG | NAT + private route to NAT |
| 502 from ALB | `sg-app` allow 8000 from `sg-alb` |
| DB connection errors | RDS SG allow 5432 from `sg-app`; fix `DB_LINK` |
