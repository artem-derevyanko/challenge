variable "app_count" {
  type    = number
  default = 1
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}


variable "db_instance" {
  description = "DB INSTANCE"
  default     = "db.t3.micro"
}

variable "db_version" {
  description = "DB VERSION"
  default     = "13.1"
}


variable "db_name" {
  description = "DB NAME"
  # sensitive = true -> for test purposes do this
}

variable "db_username" {
  description = "DB USERNAME"
  # sensitive = true -> for test purposes do this
}

variable "db_password" {
  description = "DB PASSWORD"
  # sensitive = true -> for test purposes do this
}

variable "app_port" {
  description = "APP PORT"
  default     = 3000
}

variable "hasura_port" {
  description = "HASURA PORT"
  default     = 8080
}