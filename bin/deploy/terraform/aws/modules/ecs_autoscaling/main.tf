resource "aws_ecs_cluster" "main" {
  name = "${var.cluster_name}-${var.env}"
}



data "template_file" "cloud_config" {
  template = "${file("${path.module}/templates/cloud-config.yml")}"

  vars {
    aws_region         = "${var.aws_region}"
    ecs_cluster_name   = "${aws_ecs_cluster.main.name}"
    ecs_log_level      = "info"
    ecs_agent_version  = "latest"
    ecs_log_group_name = "${aws_cloudwatch_log_group.ecs.name}"
  }
}

data "aws_ami" "stable_coreos" {
  most_recent = true

  filter {
    name   = "description"
    values = ["CoreOS stable *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["595879546273"] # CoreOS
}

resource "aws_launch_configuration" "app" {
  name = "${var.cluster_name}-${var.env}"
  instance_type = "${var.instance_type}"
  image_id = "${lookup(var.ami, var.region)}"
  iam_instance_profile = "${var.iam_instance_profile}"
  security_groups = ["${split(",", var.security_group_ids)}"]
  key_name = "${var.key_name}"
  user_data = "${data.template_file.user_data.rendered}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name = "${var.cluster_name}-${var.env}"
  availability_zones = ["${split(",", var.availability_zones)}"]
  vpc_zone_identifier = ["${split(",", var.subnet_ids)}"]
  min_size = "${var.min_size}"
  max_size = "${var.max_size}"
  desired_capacity = "${var.desired_capacity}"
  launch_configuration = "${aws_launch_configuration.app.name}"
  health_check_type = "EC2"
  health_check_grace_period = "${var.health_check_grace_period}"

  tag {
    key = "Environment"
    value = "${var.env}"
    propagate_at_launch = true
  }

  tag {
    key = "Name"
    value =  "ECS ${var.cluster_name}-${var.env}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "ecs_scale_up" {
    name = "ecs-scale-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ecs_cluster.name}"
}

resource "aws_autoscaling_policy" "ecs_scale_down" {
    name = "ecs-scale-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.ecs_cluster.name}"
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
    alarm_name = "mem-util-high-ecs"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors EC2 memory for high utilization on ECS cluster instances"
    alarm_actions = [
        "${aws_autoscaling_policy.ecs_scale_up.arn}"
    ]
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.ecs_cluster.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
    alarm_name = "mem-util-low-ecs"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "40"
    alarm_description = "This metric monitors EC2 memory for low utilization on ECS cluster instances"
    alarm_actions = [
        "${aws_autoscaling_policy.ecs_scale_down.arn}"
    ]
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.ecs_cluster.name}"
    }
}