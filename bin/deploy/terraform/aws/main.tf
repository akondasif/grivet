# Specify the provider and access details
provider "aws" {
  region = "${var.region}"
}

# Create a VPC to launch our instances into
module "vpc" {
  source = "github.com/terraform-community-modules/tf_aws_vpc"
  name = "${var.environment_name}-vpc"
  cidr = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  azs = ["${split(",", var.availability_zones)}"]
}

# Create a web security group
module "sg_web" {
  source = "github.com/terraform-community-modules/tf_aws_sg//sg_web"
  security_group_name = "web-sg"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create a zookeeper security group
module "sg_zookeeper" {
  source = "github.com/terraform-community-modules/tf_aws_sg//sg_zookeeper"
  security_group_name = "zookeeper-sg"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create a redis security group
module "sg_redis" {
  source = "github.com/terraform-community-modules/tf_aws_sg//sg_redis"
  security_group_name = "redis-sg"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create a mysql security group
module "sg_mysql" {
  source = "github.com/terraform-community-modules/tf_aws_sg//sg_mysql"
  security_group_name = "mysql-sg"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create an elasticsearch security group
module "sg_elasticsearch" {
  source = "github.com/terraform-community-modules/tf_aws_sg//sg_elasticsearch"
  security_group_name = "elasticsearch-sg"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create a kafka security group
module "sg_kafka" {
  source = "github.com/terraform-community-modules/tf_aws_sg//sg_kafka"
  security_group_name = "kafka-sg"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}


# Create an EC2 Launch Configuration and Autoscaling Group and configures EC2 instances for an ECS cluster
module "ecs-autoscaling" {
    source = "git@github.com:RobotsAndPencils/terraform-ecs-autoscaling.git"
    cluster_name = "${var.cluster_name}"
    key_name = "${var.key_name}"
    instance_type = "${var.ecs_instance_type}"
    region = "${var.region}"
    availability_zones = "${var.availability_zones}"
    subnet_ids = "${join(",", module.vpc.private_subnets)}"
    security_group_ids = "${module.sg_web.security_group_id},${module.sg_zookeeper.security_group_id},${module.sg_redis.security_group_id},${module.sg_mysql.security_group_id},${module.sg_elasticsearch.security_group_id},${module.sg_kafka.security_group_id}"
    min_size = "3"
    max_size = "10"
    desired_capacity ="4"
    iam_instance_profile = "AmazonECSContainerInstanceRole"
    registry_url = "https://index.docker.io/v1/"
    registry_email = "${var.registry_email}"
    registry_auth = "${var.registry_auth}"
    environment_name = ${var.environment_name}
}