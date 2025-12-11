resource "aws_ecs_cluster" "backend_cluster" { # ECS Cluster 논리적 공간 생성
  name = "TIB-backend"
}

resource "aws_ecs_service" "backend_service" { # ECS Service # Task 실행 단위, ALB 연결, Auto Scaling
  name            = "TIB-backend-service"
  cluster         = aws_ecs_cluster.backend_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 2 # 최소 살아있어야 하는 컨테이너 수
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "backend"
    container_port   = var.backend_port
  }

  deployment_minimum_healthy_percent = 50  # 최소 살아있어야 하는 Task 수
  deployment_maximum_percent         = 200 # desired_count의 몇 %까지 최대 task를 늘릴 수 있는지
}

resource "aws_ecs_task_definition" "backend_task" { # ECS Task Definition (Fargate)
  family                   = "TIB-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"] # 실행 엔진 Fargate 설정
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = "your-ecr-image-url" # 이미지 url 추후 추가
    essential = true
    portMappings = [{
      containerPort = var.backend_port # 컨테이너 listen 포트
      hostPort      = var.backend_port # ENI의 외부 수신 포트
    }]
    environment = [
      { name = "ENV", value = "prod" }
    ]
  }])
}

resource "aws_security_group" "ecs_sg" { # ECS Security Group
  name        = "ecs-sg"
  vpc_id      = aws_vpc.main.id
  description = "ECS tasks"

  ingress { # ALB 통해서만 접근 가능
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress { # 외부로 나가는 트래필 허용
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
