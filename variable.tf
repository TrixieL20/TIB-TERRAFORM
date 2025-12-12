variable "aws_main_region" {
  description = "AWS main region to deploy resources (Seoul)"
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_sub_region" {
  description = "AWS sub region to deploy resources (Virginia)"
  type        = string
  default     = "us_east_1"
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
