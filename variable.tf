variable "aws_region" {
  description = "AWS region to deploy resources (Seoul)"
  type        = string
  default     = "ap-northeast-2"
}

variable "backend_port" {
  description = "Backend Application Port"
  type        = number
  default     = 8080
}

variable "postgres_rds_port" {
  description = "PostgreSQL Port"
  type        = number
  default     = 5432
}
