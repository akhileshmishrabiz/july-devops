#!/bin/bash
# Launch-template user data for Week 3 Day 2 (ASG + ALB + RDS).
# Corrections from class:
#   - App listens on 8000 (target group must use 8000, not 80)
#   - Private subnets need NAT or git clone / pip will fail
#   - Replace <RDS_ENDPOINT> before use; prefer Secrets Manager in production
set -euxo pipefail

yum install -y git

cd /home/ec2-user
git clone https://github.com/akhileshmishrabiz/july-devops.git
cd july-devops/week3/src

python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate
pip install -r requirements.txt

# Example: postgresql://admin_user:Admin1234@xxxx.ap-south-1.rds.amazonaws.com:5432/mydb
export DB_LINK="postgresql://admin_user:Admin1234@<RDS_ENDPOINT>:5432/mydb"

# Health check path for ALB target group: /health (HTTP 200)
nohup gunicorn run:app --bind 0.0.0.0:8000 > /var/log/flask-app.log 2>&1 &
