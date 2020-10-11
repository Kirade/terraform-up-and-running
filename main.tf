provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "example" {
  ami           = "ami-044057cb1bc4ce527"
  instance_type = "t2.nano"

  tags = {
    name = "terraform-example"
  }
}