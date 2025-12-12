resource "aws_acm_certificate" "frontend" {
  provider          = aws.us_east_1
  domain_name       = "www.tib-time-in-busan.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "backend" {
  provider          = aws
  domain_name       = "api.tib-time-in-busan.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
