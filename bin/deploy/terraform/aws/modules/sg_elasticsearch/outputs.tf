output "security_group_id_elasticsearch" {
  value = "${aws_security_group.main_security_group.id}"
}