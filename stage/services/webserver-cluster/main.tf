terraform {
  backend "s3" {
    bucket  = "terraform-up-and-running-example-123"
    key     = "stage/services/webserver-cluster/terraform.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
    dynamodb_table = "terraform-up-and-running-lock"
  }
}


provider "aws" {
  region = "ap-northeast-2"
}


resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_launch_configuration" "example" {
  image_id        = "ami-044057cb1bc4ce527"
  instance_type   = "t2.nano"
  security_groups = [
    aws_security_group.instance.id,
  ]

  user_data = <<-EOF
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p ${var.server_port} &
EOF

  lifecycle {
    create_before_destroy = true
  }
}


data "aws_availability_zones" "all" {
  state = "available"
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  availability_zones   = data.aws_availability_zones.all.names
  target_group_arns    = [
    aws_lb_target_group.lb-tg.arn,
  ]

  min_size = 2
  max_size = 10

  tag {
    key                 = "name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_lb" "lb" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = [
    "subnet-0d2ce599a7aa3cb3a",
    "subnet-0a97a852cce67a4fd",
  ]

  security_groups = [
    aws_security_group.lb-sg.id,
  ]
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-tg.arn
  }
}

resource "aws_lb_target_group" "lb-tg" {
  name        = "terraform-lb-tg"
  port        = var.server_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "vpc-06feb5580103e168a"

  health_check {
    path = "/"
  }
}


resource "aws_security_group" "lb-sg" {
  name = "terraform-example-lb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}