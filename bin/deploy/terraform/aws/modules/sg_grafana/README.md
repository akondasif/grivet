Grafana Security Group Terraform module
==============================

A Terraform security group module for Kafka


Ports
-----
- TCP 22
- TCP 9090 (Grafana)


Input Variables
---------------

- `security_group_name` - The name for your security group, e.g. `bluffdale_web_stage1`
- `vpc_id` - The VPC this security group should be created in.
- `source_cidr_block` - The source CIDR block, defaults to `0.0.0.0/0`
   for this module.

Usage
-----

You can use these in your Terraform template with the following steps.

1. Adding a module resource to your template, e.g. `main.tf`

```
module "sg_grafana" {
  source = "github.com/terraform-community-modules/tf_aws_sg//sg_grafana"
  security_group_name = "${var.security_group_name}-grafana"
  vpc_id = "${var.vpc_id}"
  source_cidr_block = "${var.source_cidr_block}"
}
```

2. Setting values for the following variables, either through `terraform.tfvars` or `-var` arguments on the CLI

- security_group_name
- vpc_id
- source_cidr_block