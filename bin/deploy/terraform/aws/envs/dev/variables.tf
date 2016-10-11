variable "aws_secret_key" {}

variable "aws_access_key" {}

variable "key_name" {}

variable "env" {}

variable "region" {
    default = "us-west-2"
    description = "The region of AWS"
}

variable "availability_zones" {}

variable "rds_subnet_az1" {}

variable "rds_subnet_az2" {}

variable "ecs_ami" {
  description = "ECS Optimized AMI id to launch, must be in the region specified by the region variable"
}

variable "source_cidr_block" {}

variable "registry_email" {}


variable "registry_auth" {}


variable "db_user" {}

variable "db_password" {}