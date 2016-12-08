variable "env" {}

variable "instance_type" {
  default = "t2.micro"
}

variable "region" {}

variable "vpc_id" {}

variable "subnet_id" {}

variable "key_name" {}

variable "admin_cidr_ingress" {
  description = "CIDR to allow tcp/22 ingress to EC2 instance"
}
