output "ami_id" {
  value = "${data.aws_ami.web-ami.id}"
}

output "elb_dns_name" {
  value = "${aws_alb.web-alb.dns_name}"
}
