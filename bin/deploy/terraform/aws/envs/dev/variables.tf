variable "aws_secret_key" {}

variable "aws_access_key" {}

variable "key_name" {}

variable "public_key_path" {}

variable "env" {}

variable "region" {
    default = "us-west-2"
    description = "The region of AWS"
}

variable "availability_zones" {}

variable "source_cidr_block" {}

variable "registry_email" {}

variable "registry_auth" {}

variable "db_user" {}

variable "db_password" {}