# ecs cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.environment}-${var.prefix}-ecs-cluster"
}


# ecs task definition

resource "aws_ecs_task_definition" "service" {
  family                   = "2tier-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.app_image
      essential = true
      environment = [
        {
          name  = "DB_LINK"
          value = "postgresql://postgres:${random_password.password.result}@${aws_db_instance.rds_instance.address}/${aws_db_instance.rds_instance.db_name}"
        }
      ]
      portMappings = [
        {
          containerPort = var.port
          hostPort      = var.port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.ecs_task_def}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn


  depends_on = [ aws_cloudwatch_log_group.ecs_log_group ]
}

# ecs services 

# ecs service
resource "aws_ecs_service" "app_service" {
  name            = "${var.environment}-${var.prefix}-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  desired_count   = 2
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.service.arn

  load_balancer {
    target_group_arn = aws_alb_target_group.name.arn
    container_name   = var.container_name
    container_port   = var.port
  }

  network_configuration {
    subnets          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

}


# ecs iam task execution role



