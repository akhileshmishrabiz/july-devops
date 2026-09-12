
# alb


resource "aws_alb" "app" {
  name            = "${var.environment}-${var.prefix}-alb"
  internal        = false
  security_groups = [aws_security_group.alb_sg.id]
  subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "${var.environment}-${var.prefix}-alb"
  }

}
# target group

resource "aws_alb_target_group" "name" {
  name     = "${var.environment}-${var.prefix}-alb-tg"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path     = "/health"
    protocol = "HTTP"
    matcher  = "200"
    interval = 30
    timeout  = 5
    # healthy_threshold   = 2
    # unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.environment}-${var.prefix}-alb-target-group"
  }

}

# alb lister for port 80
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.name.arn
  }
}


# alb lister for port 443

# alb lister for port 443
resource "aws_alb_listener" "https" {
    load_balancer_arn = aws_alb.app.arn
    port              = 443
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = aws_acm_certificate.app_cert.arn
    
    default_action {
        type             = "forward"
        target_group_arn = aws_alb_target_group.name.arn
  
}
}