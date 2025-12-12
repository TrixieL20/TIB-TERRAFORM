provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}

resource "aws_acm_certificate" "frontend" {
  provider          = aws.us_east_1
  domain_name       = "www.example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# (옵션) Route53 DNS 자동 검증 추가 가능
