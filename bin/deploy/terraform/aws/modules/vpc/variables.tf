variable "env" {}

variable "cidr" {}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC."
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC."
}

variable "azs" {
  description = "A list of Availability zones in the region"
}

variable "enable_dns_hostnames" {
  description = "should be true if you want to use private DNS within the VPC"
  default = false
}

variable "enable_dns_support" {
  description = "should be true if you want to use private DNS within the VPC"
  default = false
}
