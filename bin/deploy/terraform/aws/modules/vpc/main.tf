# Prefix resources with var.name so we can have many environments trivially

# Create VPC
resource "aws_vpc" "mod" {
  cidr_block = "${var.cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support = "${var.enable_dns_support}"
  tags { 
    Name = "${var.env}_vpc"
  }
}

# For each in the list of availability zones, create the public subnet 
# and private subnet for that list index,
# then create an EIP and attach a nat_gateway for each one.  And an aws route
# table should be created for each private subnet, and add the correct nat_gw

# Create VPC public subnets
resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.mod.id}"
  cidr_block = "${element(split(",", var.public_subnets), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count = "${length(compact(split(",", var.public_subnets)))}"
  tags { 
    Name = "${var.env}_public_${count.index}"
  }
  map_public_ip_on_launch = true
}

# Create VPC private subnets
resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.mod.id}"
  cidr_block = "${element(split(",", var.private_subnets), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count = "${length(compact(split(",", var.private_subnets)))}"
  tags { 
    Name = "${var.env}_private_${count.index}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.mod.id}"
  tags { 
    Name = "${var.env}_igw"
  }
}

# Create route to the Internet
resource "aws_route" "internet_access" {
  route_table_id = "${aws_vpc.mod.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.igw.id}"
}

# Create Elastic IP (EIP)
resource "aws_eip" "nat_eip" {
  count    = "${length(split(",", var.public_subnets))}"
  vpc = true
  depends_on = ["aws_internet_gateway.igw"]
}

# Create NAT Gateways (one per public subnet)
resource "aws_nat_gateway" "nat_gw" {
  count = "${length(split(",", var.public_subnets))}"
  allocation_id = "${element(aws_eip.nat_eip.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  depends_on = ["aws_internet_gateway.igw"]
}

# Create private route table and the route to the Internet

# For each of the private subnets, create a "private" route table.
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.mod.id}"
  count = "${length(compact(split(",", var.private_subnets)))}"
  tags {
    Name = "${var.env}_private_subnet_route_table_${count.index}"
  }
}

# Add a NAT Gateway to each private subnet's route table
resource "aws_route" "private_nat_gateway_route" {
  count = "${length(compact(split(",", var.private_subnets)))}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${element(aws_nat_gateway.nat_gw.*.id, count.index)}"
}

# Create route table associations
resource "aws_route_table_association" "private" {
  count = "${length(compact(split(",", var.private_subnets)))}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_route_table_association" "public" {
  count = "${length(compact(split(",", var.public_subnets)))}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_vpc.mod.main_route_table_id}"
}
