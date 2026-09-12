# ALL infra layers 

2 zone setup. region ap-south-1 and zones a abd b

- VPC 10.0.0.0/16
- public subnets 10.0.1.0/24, 10.0.2.0/24 (ALB will come here)
- private subnets 10.0.3.0/24, 10.0.4.0/24 (ECS services will go here)
- rds subnets 10.0.5.0/24, 10.0.6.0/24 (ALB will come here)

- Public route table
- private route table

- Associate public subnets -> public Route table
- Associate private subnets -> public private table

- Internet gateway
- Route from public subnet -> in ternet gateway

# ecr pull purpose setup (NAT or vpc endpoint)



# security group
rds SG -> listen on 5432 from the security group of ECS
ECS SG -> listen on app port (8000) from security group of ALB
ALB SG -> listen on 80/443 from public 












###  Terraform best practices ###
1. varibales vs locals . typoe of variables
2. move my statefile to remote
3. import and data source
4. what happens if statefile got deleted/corrupted -> how to recover
  gaurdrails

5. Drift management 




terraform import aws_ecr_repository.ecr_repo dev-tf2t






docker build  --platform linux/amd64 -t 879381241087.dkr.ecr.ap-south-1.amazonaws.com/dev-tf2t:1.0 .

aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 879381241087.dkr.ecr.ap-south-1.amazonaws.com

docker push 879381241087.dkr.ecr.ap-south-1.amazonaws.com/dev-tf2t:1.0
