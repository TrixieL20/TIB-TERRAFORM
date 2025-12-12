# ✔ React/Vue/Next 정적 빌드 결과물을 올린다
# ✔ S3는 public 접근 차단
# ✔ CloudFront가 Origin Access Control(OAC)로 접근
# ✔ HTTPS(ACM) 인증서 포함
# ✔ 기본 index.html / error.html 처리까지 완備

resource "aws_s3_bucket" "frontend" { # 프론트엔드 정적 코드를 위한 S3
  bucket = "TIB-frontend-bucket"
}

resource "aws_s3_bucket_public_access_block" "frontend" { # S3 접근 차단
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true # 퍼블릭 ACL(읽기 허용) 설정 금지
  block_public_policy     = true # 퍼블릭 ACL 설정 사전 금지
  ignore_public_acls      = true # 누가 ACL을 퍼블릭으로 바꾸어도 무시
  restrict_public_buckets = true # 퍼블릭 정책이 있으면 버킷 자체가 요청을 거부
}

resource "aws_s3_bucket_versioning" "frontend" { # 정적 코드 업데이트에 의한 버젼 관리 지원
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudfront_origin_access_control" "oac" { # private인 S3로부터 CloudFront가 파일을 가져오기 위해 필요한 인증 키 역할
  name                              = "frontend-oac"
  description                       = "OAC for CloudFront to access S3"
  origin_access_control_origin_type = "s3"     # S3를 origin으로 CloudFront 제공
  signing_behavior                  = "always" # S3로 향하는 요청은 반드시 서명(SigV4)해야 함
  signing_protocol                  = "sigv4"  # S3로 향하는 요청 서명 방식
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "s3-frontend"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"

    # forwarded_values {
    #   query_string = false

    #   cookies {
    #     forward = "none"
    #   }

    #   headers = ["CloudFront-Viewer-Country"]
    # }

    # lambda_function_association { # Lambda@Edge 람다를 통한 html 제공
    #   event_type   = "viewer-request"
    #   lambda_arn   = aws_lambda_function.country_redirect.qualified_arn
    # }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.frontend.arn
    ssl_support_method  = "sni-only"
  }

  default_root_object = "index.html"

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# resource "aws_lambda_function" "country_redirect" { # lambda@edge 지원을 위한 람다 설정
#   provider = aws.us_east_1

#   filename         = "lambda_edge.zip"
#   function_name    = "country_redirect_edge"
#   role             = aws_iam_role.edge_lambda_role.arn
#   handler          = "index.handler"
#   runtime          = "nodejs18.x"
#   publish          = true
# }
