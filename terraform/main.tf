provider "aws" {

    region = "us-east-1"
  
}

# Getting VPC details

data "aws_vpc" "myvpc" {

}

# Getting AMI details

data "aws_ami" "ubuntu" {

    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

# Creating security group

resource "aws_security_group" "ec2rules" {
  name        = var.sg_name
  description = "Allow traffic"
  vpc_id      = data.aws_vpc.myvpc.id

  tags = {
    Name = "ec2rule"
  }
}

# Creating security group rules

resource "aws_security_group_rule" "inbound_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2rules.id
}

resource "aws_security_group_rule" "inbound_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2rules.id
}

resource "aws_security_group_rule" "inbound_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2rules.id
}

resource "aws_security_group_rule" "outbound_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2rules.id
}

# Creating keypair

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = var.instance_name
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" {
    command = "Set-Content ${var.instance_name}.pem '${tls_private_key.pk.private_key_pem}'"
    interpreter = ["PowerShell", "-Command"]
  }
}

# Creating elastic IP

resource "aws_eip" "e_ip" {
  instance = aws_instance.Web_server.id
  vpc      = true
    tags = {
    Name = "${var.instance_name}-IP"
  }
}

# Creating EC2 Instance


resource "aws_instance" "Web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.kp.key_name
  vpc_security_group_ids = [aws_security_group.ec2rules.id]
  tags = {
    Name = "${var.instance_name}"
  }
}

# Output data

output "Public_ip" {
    value = "${aws_eip.e_ip.public_ip}"
}

output "instance_id" {
    value = "${aws_instance.Web_server.id}"
}

output "sg_id" {
    value = "${aws_security_group.ec2rules.id}"
}

output "image_id" {
    value = "${data.aws_ami.ubuntu.id}"
}

output "vpc_id" {
    value = "${data.aws_vpc.myvpc.id}"
}