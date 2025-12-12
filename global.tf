terraform { # 엔진
  # Terraform 최소 버전 요구사항
  required_version = ">= 1.13.0" # 호환성

  required_providers {
    aws = {
      source  = "hashicorp/aws" # AWS 환경에서 수행
      version = "~> 5.0"
    }
  }
}

provider "aws" { # AWS 리소스 생성 & API 요청 보냄
  region  = var.aws_main_region
  profile = "myprofile"
}

provider "aws" { # CloudFront ACM, lambda@edge 지원 대비
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "myprofile"
}
