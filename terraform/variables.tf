variable "access_key" {}
variable "secret_key" {}
variable "aws_region" {}
variable "aws_it" {}
variable "aws_ssh_key" {}
variable "aws_vpc" {}

variable "aws_az" {
  default = ["subnet-8c79d7e4", "subnet-af48a9d5"]
}


variable "http-port" {
  description = "http-port"
  default     = 80
}

