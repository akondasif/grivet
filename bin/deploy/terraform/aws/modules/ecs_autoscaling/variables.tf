variable "cluster_name" {
    description = "The name of the ECS Cluster"
}

variable "iam_instance_profile" {

}

// @see http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
variable "ami" {
  default = {
        us-east-1 = "ami-40286957"
        us-west-1 = "ami-20fab440"
        us-west-2 = "ami-562cf236"
        eu-west-1 = "ami-175f1964"
        eu-central-1 =  "ami-c55ea2aa"
        ap-northeast-1 = "ami-010ed160"
        ap-southeast-1 = "ami-438b2f20"
        ap-southeast-2 = "ami-862211e5"
  }
  description = "AMI id to launch, must be in the region specified by the region variable"
}

variable "key_name" {
    description = "SSH key name in your AWS account for AWS instances."
}

variable "region" {
    default = "us-west-2"
    description = "The region of AWS"
}

variable "availability_zones" {
    description = "Comma separated list of EC2 availability zones to launch instances, must be within region"
}

variable "subnet_ids" {
    description = "Comma separated list of subnet ids, must match availability zones"
}

variable "security_group_ids" {
    description = "Comma separated list of security group ids"
    default = ""
}

variable "instance_type" {
    default = "c4.large"
    description = "Name of the AWS instance type"
}

variable "min_size" {
    default = "1"
    description = "Minimum number of instances to run in the group"
}

variable "max_size" {
    default = "5"
    description = "Maximum number of instances to run in the group"
}

variable "desired_capacity" {
    default = "1"
    description = "Desired number of instances to run in the group"
}

variable "health_check_grace_period" {
    default = "300"
    description = "Time after instance comes into service before checking health"
}

variable "registry_url" {
    default = "https://index.docker.io/v1/"
    description = "Docker private registry URL, defaults to Docker index"
}

variable "registry_email" {
    default = ""
    description = "Docker private registry login email address"
}

variable "registry_auth" {
    default = ""
    description = "Docker private registry login auth token (from ~/.dockercgf)"
}

variable "env" {
    default = ""
    description = "Environment name to tag EC2 resources with (tag=env)"
}

variable "associate_public_ip_address" {
    default = false
    description = "Associate a public IP address with an instance in an ECS cluster?"