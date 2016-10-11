output "security_group_id_kafka" {
  value = "${aws_security_group.main_security_group.id}"
}