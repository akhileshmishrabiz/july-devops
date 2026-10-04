resource "random_password" "db" {
  length  = 16
  special = false
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "Dummy RDS"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "postgres from ecs"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-rds-sg"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = local.name
  subnet_ids = module.network.private_subnet_ids
}

resource "aws_db_instance" "this" {
  identifier             = local.name
  engine                 = "postgres"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = "dummy"
  username               = "dummy"
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  storage_encrypted      = true
  skip_final_snapshot    = true
  publicly_accessible    = false
}
