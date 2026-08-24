aws ec2 create-vpc-endpoint --vpc-id vpc-018486081fcad020b --service-name com.amazonaws.ap-south-1.ssm --vpc-endpoint-type Interface --subnet-ids subnet-09f698d6b9f76bf3e subnet-0f37fafc6105969bf --security-group-ids sg-03f69493e15c8b9d7

aws ec2 create-vpc-endpoint --vpc-id vpc-018486081fcad020b --service-name com.amazonaws.ap-south-1.ec2messages --vpc-endpoint-type Interface --subnet-ids subnet-09f698d6b9f76bf3e subnet-0f37fafc6105969bf --security-group-ids sg-03f69493e15c8b9d7

aws ec2 create-vpc-endpoint --vpc-id vpc-018486081fcad020b --service-name com.amazonaws.ap-south-1.ssmmessages --vpc-endpoint-type Interface --subnet-ids subnet-09f698d6b9f76bf3e subnet-0f37fafc6105969bf --security-group-ids sg-03f69493e15c8b9d7