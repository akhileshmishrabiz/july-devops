# rds subnet group

resource "aws_db_subnet_group" "default" {
  name       = "${var.environment}-${var.prefix}-rds-subnet-group"
  subnet_ids = [aws_subnet.rds_subnet_1.id, aws_subnet.rds_subnet_2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# rds password

resource "random_password" "password" {
  length  = 10
  special = false
  override_special = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
}


# secret manager

# rds instance on that subnet group 
# ubnet group, SG, password, user, all the infor

resource "aws_db_instance" "default" {
  identifier                  = "${var.environment}-${var.prefix}-rds"
  allocated_storage           = 20
  backup_retention_period     = 7
  db_subnet_group_name        = aws_db_subnet_group.default.name
  engine                      = "postgres"
  engine_version              = "16.4"
  instance_class              = "db.t3.medium"
  db_name                     = var.prefix
  multi_az                    = false # Custom for Oracle does not support multi-az
  password                    = random_password.password.result
  username                    = "postgres"
  storage_encrypted           = false
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]

  tags = {
    Name = "${var.environment}-${var.prefix}-rds"
  }
}
