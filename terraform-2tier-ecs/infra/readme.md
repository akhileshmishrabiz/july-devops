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