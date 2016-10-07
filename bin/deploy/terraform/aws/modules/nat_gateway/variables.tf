variable "name" {
  default = "private"
}

variable "cidrs" {
  description = "A list of CIDR"
  default     = []
}

variable "azs" {
  description = "A list of availability zones"
  default     = []
}

variable "vpc_id" {
}

variable "public_subnet_ids" {
  description = "A list of public subnet ids"
  default     = []
}

variable "nat_gateways_count" {
}

variable "map_public_ip_on_launch" {
  default = true
}