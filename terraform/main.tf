provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_launch_configuration" "web-lcfg" {
  name_prefix     = "web-lcfg"
  image_id        = "${data.aws_ami.web-ami.id}"
  instance_type   = "${var.aws_it}"
  security_groups = ["${aws_security_group.web-sg.id}"]
  key_name        = "${var.aws_ssh_key}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web-ag" {
  name                 = "web-ag - ${aws_launch_configuration.web-lcfg.name}"
  launch_configuration = "${aws_launch_configuration.web-lcfg.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
  ]

  metrics_granularity = "1Minute"
  health_check_grace_period = 5
  health_check_type         = "ELB"
  min_size = 2
  max_size = 6

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web-asp-up" {
  name                   = "web-asp-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.web-ag.name}"
}

resource "aws_cloudwatch_metric_alarm" "web-cpualarm-more" {
  alarm_name          = "web-cpu-alarm-more"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "900"
  statistic           = "Average"
  threshold           = "60"

  dimensions {
    
    AutoScalingGroupName = "${aws_autoscaling_group.web-ag.name}"

  }
  
  alarm_actions     = ["${aws_autoscaling_policy.web-asp-up.arn}"]

}

resource "aws_autoscaling_policy" "web-asp-down" {
  name                   = "web-asp-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.web-ag.name}"
}

resource "aws_cloudwatch_metric_alarm" "web-cpualarm-less" {
  alarm_name          = "web-cpu-alarm-less"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "900"
  statistic           = "Average"
  threshold           = "60"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.web-ag.name}"
  }

  alarm_actions     = ["${aws_autoscaling_policy.web-asp-down.arn}"]
}

resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "allow web and ssh"

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "${var.http-port}"
    to_port     = "${var.http-port}"
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_availability_zones" "all" {}

data "aws_ami" "web-ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Image"
    values = ["web-img-demo"]
  }
}

resource "aws_alb" "web-alb" {
  name            = "web-alb"
  internal        = false
  subnets           = "${var.aws_az}" 
  security_groups = ["${aws_security_group.web-alb-sg.id}"]
  idle_timeout    = 180

  tags {
    Role = "web"
  }
}

resource "aws_alb_target_group" "web-alb-tg" {
  name                 = "web-alb-tg"
  port                 = "${var.http-port}"
  protocol             = "HTTP"
  vpc_id               = "${var.aws_vpc}"
  deregistration_delay = 120

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 6
    interval            = 60
    port                = "${var.http-port}"
  }
}

resource "aws_autoscaling_attachment" "web-alb-atch" {
  autoscaling_group_name = "${aws_autoscaling_group.web-ag.id}"
  alb_target_group_arn   = "${aws_alb_target_group.web-alb-tg.arn}"
}

resource "aws_alb_listener" "web-alb-lns" {
  load_balancer_arn = "${aws_alb.web-alb.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = "${aws_alb_target_group.web-alb-tg.arn}"
    type             = "forward"
  }
}

resource "aws_security_group" "web-alb-sg" {
  name        = "web-alb-sg"
  description = "allow trafic for web"

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
