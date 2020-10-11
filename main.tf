provider "aws" {
  region = "ap-northeast-2"
}


variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = 8080
}


resource "aws_instance" "example" {
  ami                    = "ami-044057cb1bc4ce527"
  instance_type          = "t2.nano"
  vpc_security_group_ids = [
    aws_security_group.instance.id,
  ]

  user_data = <<-EOF
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p ${var.server_port} &
EOF

  tags = {
    name = "terraform-example",
  }
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


output "public_ip" {
  value = aws_instance.example.public_ip
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

  min_size = 2
  max_size = 10

  tag {
    key                 = "name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

