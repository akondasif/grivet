output "subnet_ids" {
  value = [
    "${aws_subnet.private.*.id}"
  ]
}

output "private_route_table_ids" {
  value = [
    "${aws_route_table.private.*.id}"
  ]
}

output "nat_eips" {
  value = [
    "${aws_eip.nat.*.public_ip}"
  ]
}