# Specify the provider and access details
provider "aws" {
  region = "us-west-2"
}

# Create a VPC to launch our instances into
module "vpc" {
  source = "../../modules/vpc"
  name = "grivet"
  cidr = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
}

# Create NAT gateways
module "nat_gw" {
  source = "../../modules/nat_gateway"
  vpc_id = "${module.vpc.vpc_id}"
  cidrs = "${module.vpc.private_subnets}"
  azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnet_ids = "${module.vpc.public_subnets}"
  nat_gateways_count = 3
}

# IAM policies

# Create S3 bucket for public keys


# Create a bastion host
module "bastion_host" {
  source = "../../modules/bastion"
  region = "us-west-2"
  #ami = "ami-123456"
  iam_instance_profile = "s3-readonly"
  s3_bucket_name = "pubkeys"
  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = ${module.vpc.public_subnets}
  keys_update_frequency = "5,20,35,50 * * * *"
  eip = ${aws_eip.bastion.public_ip}
  additional_user_data_script = <<EOF
    pip install aws-ec2-assign-elastic-ip
    INSTANCE_ID=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
    REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
    EIP=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=EIP" --output text --region ${REGION} --query 'Tags[*].Value')
    aws-ec2-assign-elastic-ip --valid-ips $EIP
  EOF"
}

# Create a web security group
module "sg_web" {
  source = "../../modules/sg_web"
  security_group_name = "web"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create a zookeeper security group
module "sg_zookeeper" {
  source = "../../modules/sg_zookeeper"
  security_group_name = "zookeeper"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create a redis security group
module "sg_redis" {
  source = "../../modules/sg_redis"
  security_group_name = "redis"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create a mysql security group
module "sg_mysql" {
  source = "../../modules/sg_mysql"
  security_group_name = "mysql"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create an elasticsearch security group
module "sg_elasticsearch" {
  source = "../../modules/sg_elasticsearch"
  security_group_name = "elasticsearch"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create a kafka security group
module "sg_kafka" {
  source = "../../modules/sg_kafka"
  security_group_name = "kafka"
  vpc_id = "${module.vpc.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}

# Create RDS MySQL instance
module "rds_mysql_instance" {
  source = "../../modules/rds"
  
  rds_instance_class = "db.t2.medium"
  rds_instance_name = "grivetdb"
  rds_allocated_storage = "20"
  rds_engine_type = "mysql"
  rds_engine_version = "5.7"
  database_name = "grivet"
  database_user = "${var.db_user}"
  database_password = "${var.db_password}"
  rds_security_group_id = "${module.sg_mysql.security_group_id_mysql}"

  subnet_az1 = "us-west-2a"
  subnet_az2 = "us-west-2c"
}

# Create an Elasticache Redis cluster
module "redis_elasticache" {
  source = "../../modules/elasticache_redis"

  vpc_id = "${module.vpc.vpc_id}"
  vpc_cidr_block = "10.0.0.0/16"

  cache_name = "cache"
  engine_version = "2.8.24"
  instance_type = "cache.t2.medium"
  maintenance_window = "sun:05:00-sun:06:00"

  private_subnet_ids = "${module.vpc.private_subnets}"
}

# Create an EC2 Launch Configuration and Autoscaling Group and configures EC2 instances for an ECS cluster
module "ecs_autoscaling" {
  source = "../../modules/ecs_autoscaling"
  cluster_name = "${var.cluster_name}"
  key_name = "${var.key_name}"
  instance_type = "${var.ecs_instance_type}"
  region = "${var.region}"
  availability_zones = "us-west-2a,us-west-2b,us-west-2c"
  subnet_ids = "${join(",", module.vpc.private_subnets)}"
  security_group_ids = "${module.sg_web.security_group_id},${module.sg_zookeeper.security_group_id},${module.sg_redis.security_group_id},${module.sg_mysql.security_group_id},${module.sg_elasticsearch.security_group_id},${module.sg_kafka.security_group_id}"
  min_size = "3"
  max_size = "10"
  desired_capacity ="4"
  iam_instance_profile = "AmazonECSContainerInstanceRole"
  registry_email = "${var.registry_email}"
  registry_auth = "${var.registry_auth}"
}
