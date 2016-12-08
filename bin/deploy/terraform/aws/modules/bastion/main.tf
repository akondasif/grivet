// Use the Ubuntu AMI
module "ami" {
    source = "github.com/terraform-community-modules/tf_aws_ubuntu_ami//ebs"
    region = "${var.region}"
    distribution = "trusty"
    instance_type = "${var.instance_type}"
}

// Set up a security group to the bastion
resource "aws_security_group" "bastion" {
    name = "bastion"
    description = "Allows ssh from the world"
    vpc_id = "${var.vpc_id}"

    ingress {
        from_port = 22
        to_port   = 22
        protocol  = "tcp"
        cidr_blocks = ${var.admin_cidr_ingress}
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "bastion"
    }
}

// Add our instance description
resource "aws_instance" "bastion" {
    ami = "${module.ami.ami_id}"
    source_dest_check = false
    instance_type = "${var.instance_type}"
    subnet_id = "${var.subnet_id}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.bastion.id}"]
    tags  {
        Name = "bastion-${var.env}-01"
        Environment = "${var.env}"
    }
}

// Setup our elastic ip
resource "aws_eip" "bastion" {
    instance = "${aws_instance.bastion.id}"
    vpc = true
}