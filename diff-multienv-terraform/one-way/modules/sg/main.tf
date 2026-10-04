resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Dummy instance security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "http from the vpc"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-sg"
  }
}
