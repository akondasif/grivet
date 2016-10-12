# Specify the provider and access details
provider "aws" {
  region = "${var.region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

# Create a VPC to launch our instances into
module "vpc" {
  source = "../../modules/vpc"
  env = "${var.env}"
  cidr = "10.0.0.0/16"
  private_subnets = "10.0.1.0/24,10.0.2.0/24,10.0.3.0/24"
  public_subnets = "10.0.101.0/24,10.0.102.0/24,10.0.103.0/24"
  azs = "${var.availability_zones}"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
}

# SSH public/private key-pair
resource "aws_key_pair" "pem" {
  key_name = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}


# Create a bastion host
module "bastion" {
  source = "../../modules/bastion"
  region = "${var.region}"
  env = "${var.env}"
  vpc_id = "${module.vpc.vpc_id}"
  subnet_id = "${element(module.vpc.public_subnets, 0)}"
  key_name = "${var.key_name}"
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

# Create IAM roles and policies
module "iam" {
  source = "../../modules/iam"
}

# Create RDS MySQL instance
module "rds_mysql_instance" {
  source = "../../modules/rds"
  env = "${var.env}"
  rds_instance_class = "db.t2.medium"
  rds_instance_name = "grivetdb"
  rds_allocated_storage = "20"
  rds_engine_type = "mysql"
  rds_engine_version = "5.7"
  database_name = "grivet"
  database_user = "${var.db_user}"
  database_password = "${var.db_password}"
  rds_security_group_id = "${module.sg_mysql.security_group_id_mysql}"
  subnet_az1 = "${element(module.vpc.private_subnets, 0)}"
  subnet_az2 = "${element(module.vpc.private_subnets, 2)}"
  aws_access_key = "${var.aws_access_key}"
  aws_secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
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

## TODO add ELB per cluster, @see http://vilkeliskis.com/blog/2016/02/10/bootstrapping-docker-with-terraform.html for inspiration

# Create an EC2 Launch Configuration and Autoscaling Group and configures EC2 instances for an ECS cluster
# This cluster will host Zuul
module "ecs_apigw" {
  source = "../../modules/ecs_autoscaling"
  cluster_name = "apigw"
  iam_instance_profile = "${module.iam.ecs_iam_instance_profile_id}"
  key_name = "${var.key_name}"
  instance_type = "t2.micro"
  region = "${var.region}"
  env = "${var.env}"
  availability_zones = "${var.availability_zones}"
  subnet_ids = "${join(",", module.vpc.public_subnets)}"
  security_group_ids = "${module.sg_web.security_group_id_web}"
  min_size = "1"
  max_size = "4"
  desired_capacity = "2"
  registry_email = "${var.registry_email}"
  registry_auth = "${var.registry_auth}"
}

# Create an EC2 Launch Configuration and Autoscaling Group and configures EC2 instances for an ECS cluster
# This cluster will host an ELK stack, statsd, Graphite, Grafana, PHPMyAdmin
module "ecs_monitoring" {
  source = "../../modules/ecs_autoscaling"
  cluster_name = "monitoring"
  iam_instance_profile = "${module.iam.ecs_iam_instance_profile_id}"
  key_name = "${var.key_name}"
  instance_type = "t2.medium"
  region = "${var.region}"
  env = "${var.env}"
  availability_zones = "${var.availability_zones}"
  subnet_ids = "${join(",", module.vpc.public_subnets)}"
  security_group_ids = "${module.sg_web.security_group_id_web},${module.sg_redis.security_group_id_redis},${module.sg_mysql.security_group_id_mysql},${module.sg_elasticsearch.security_group_id_elasticsearch}"
  min_size = "3"
  max_size = "10"
  desired_capacity = "4"
  registry_email = "${var.registry_email}"
  registry_auth = "${var.registry_auth}"
}

# Create an EC2 Launch Configuration and Autoscaling Group and configures EC2 instances for an ECS cluster
# This cluster will host suite of Grivet micro-services, Eureka, Spring Boot Admin, Micro Dashboard, and Configuration Management
module "ecs_grivet" {
  source = "../../modules/ecs_autoscaling"
  cluster_name = "grivet"
  iam_instance_profile = "${module.iam.ecs_iam_instance_profile_id}"
  key_name = "${var.key_name}"
  instance_type = "t2.medium"
  region = "${var.region}"
  env = "${var.env}"
  availability_zones = "${var.availability_zones}"
  subnet_ids = "${join(",", module.vpc.private_subnets)}"
  security_group_ids = "${module.sg_web.security_group_id_web},${module.sg_zookeeper.security_group_id_zookeeper},${module.sg_redis.security_group_id_redis},${module.sg_mysql.security_group_id_mysql},${module.sg_kafka.security_group_id_kafka}"
  min_size = "3"
  max_size = "10"
  desired_capacity = "4"
  registry_email = "${var.registry_email}"
  registry_auth = "${var.registry_auth}"
}

# Create an EC2 Launch Configuration and Autoscaling Group and configures EC2 instances for an ECS cluster
# This cluster will host Zookeeper, Kafka
module "ecs_zk_kafka" {
  source = "../../modules/ecs_autoscaling"
  cluster_name = "zk_kafka"
  iam_instance_profile = "${module.iam.ecs_iam_instance_profile_id}"
  key_name = "${var.key_name}"
  instance_type = "t2.medium"
  region = "${var.region}"
  env = "${var.env}"
  availability_zones = "${var.availability_zones}"
  subnet_ids = "${join(",", module.vpc.private_subnets)}"
  security_group_ids = "${module.sg_web.security_group_id_web},${module.sg_zookeeper.security_group_id_zookeeper},${module.sg_kafka.security_group_id_kafka}"
  min_size = "1"
  max_size = "4"
  desired_capacity = "2"
  registry_email = "${var.registry_email}"
  registry_auth = "${var.registry_auth}"
}