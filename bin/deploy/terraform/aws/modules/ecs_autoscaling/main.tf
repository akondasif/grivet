resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.cluster_name}"
}



data "template_file" "user_data" {
  template = "templates/user_data"
  vars {
    cluster_name = "${var.cluster_name}"
  }
}

resource "aws_launch_configuration" "ecs_cluster" {
  name = "${var.cluster_name}-lc-${var.env}"
  instance_type = "${var.instance_type}"
  image_id = "${lookup(var.ami, var.region)}"
  iam_instance_profile = "${var.iam_instance_profile}"
  security_groups = ["${split(",", var.security_group_ids)}"]
  key_name = "${var.key_name}"
  user_data = "${data.template_file.user_data.rendered}"
}

resource "aws_autoscaling_group" "ecs-cluster" {
  name = "${var.cluster_name}-${var.env}"
  availability_zones = ["${split(",", var.availability_zones)}"]
  vpc_zone_identifier = ["${split(",", var.subnet_ids)}"]
  min_size = "${var.min_size}"
  max_size = "${var.max_size}"
  desired_capacity = "${var.desired_capacity}"
  launch_configuration = "${aws_launch_configuration.ecs_cluster.name}"
  health_check_type = "EC2"
  health_check_grace_period = "${var.health_check_grace_period}"

  tag {
    key = "Environment"
    value = "${var.env}"
    propagate_at_launch = true
  }

  tag {
    key = "Name"
    value =  "ECS ${var.cluster_name}"
    propagate_at_launch = true
  }
}
