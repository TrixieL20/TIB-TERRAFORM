resource "aws_lb" "alb" { # ALB (Public Subnet)
  name               = "TIB-alb"
  internal           = false # 외부 사용자 서비스 접속 가능하게 설정
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "ecs_tg" {
  name     = "ecs-tg"
  port     = var.backend_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health" # 헬스 체크 경로
    matcher             = "200"
    interval            = 30 # 초
    timeout             = 5  # 초
    healthy_threshold   = 2  # 컨테이너 정상 판단을 위해 연속 성공해야 하는 헬스 체크 수
    unhealthy_threshold = 2  # 컨테이너 비정상 판단을 위해 연속 실패해야 하는 헬스 체크 수
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" # HTTPS/TLS 연결 프로토콜, 암호화 스위트 정의
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

resource "aws_security_group" "alb_sg" { # ALB Security Group
  name        = "alb-sg"
  vpc_id      = aws_vpc.main.id
  description = "ALB security group"

  ingress {
    from_port   = 80 # 포트 범위
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
