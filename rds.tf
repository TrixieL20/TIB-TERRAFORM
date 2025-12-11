resource "aws_security_group" "rds_sg" { # RDS Security Group
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = var.postgres_rds_port
    to_port         = var.postgres_rds_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnets" { # RDS PostgreSQL (Multi-AZ)
  name       = "TIB-rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = { Name = "TIB-rds-subnet-group" }
}

resource "aws_db_instance" "postgres_primary" { # Primary PostgreSQL
  identifier             = "TIB-db-primary"
  engine                 = "postgres"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20                        # 디스크 크기
  username               = var.postgres_rds_user     # 초기 DB 계정
  password               = var.postgres_rds_password # 패스워드
  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az               = true  # 장애, 트래픽 대비 (multi AZ)
  skip_final_snapshot    = false # 삭제 시 스냅샷 자동 생성
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" { # cloudwatch
  alarm_name          = "rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.rds_scale.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres_primary.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_low" {
  alarm_name          = "rds-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_sns_topic.rds_scale.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres_primary.id
  }
}

resource "aws_sns_topic" "rds_scale" {}              # 람다 함수로 Cloud Watch의 알림 신호 전달
resource "aws_sns_topic_subscription" "lambda_sub" { # sns topic과 람다 함수 연결
  topic_arn = aws_sns_topic.rds_scale.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.scale_read_replica.arn
}

resource "aws_lambda_function" "scale_read_replica" { # 람다를 통한 read replica 자동화
  function_name = "scale_read_replica"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "lambda_package.zip" # 코드 패키지
  source_code_hash = filebase64sha256("lambda_package.zip")
}

resource "aws_lambda_permission" "allow_sns" { # sns의 람다 호출을 위한 permission 추가
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scale_read_replica.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.rds_scale.arn
}
