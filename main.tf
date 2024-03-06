provider "aws" {}

variable "cidr_block" {
  type = list(string)
}
variable "public_key_location" {}
variable "env-prefix" {}
variable "avail_zone" {}
variable "ip" {}
variable "instance_type" {}

resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.cidr_block[0]
  tags = {
    Name: "${var.env-prefix}-vpc"
    }
}

resource "aws_subnet" "myapp_subnet" {
  vpc_id     = aws_vpc.myapp_vpc.id
 cidr_block = var.cidr_block[1]
 availability_zone = var.avail_zone

  tags = {
    Name: "${var.env-prefix}-myapp_subnet"
    }
}
resource "aws_route_table" "myapp_rtb" {
  vpc_id     = aws_vpc.myapp_vpc.id

  route {
     cidr_block = var.cidr_block[2]
     gateway_id = aws_internet_gateway.myapp_igw.id
  }
   tags = {
    Name: "${var.env-prefix}-myapp_rtb"
    }
}

resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.myapp_vpc.id

   tags = {
    Name: "${var.env-prefix}-myapp_igw"
    }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id = aws_subnet.myapp_subnet.id
  route_table_id = aws_route_table.myapp_rtb.id
  
}
#using the default route tabe created for the subnet instead of creating a new one
/*resource "aws_default_route_table" "default_rtb" {
  default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id
  route {
     cidr_block = var.cidr_block[2]
     gateway_id = aws_internet_gateway.myapp_igw.id
  }
   tags = {
    Name: "${var.env-prefix}-myapp_rtb"
    }
}*/
  resource "aws_security_group" "myapp_sg" {
    name = "myapp_sg"
    vpc_id = aws_vpc.myapp_vpc.id

    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [var.ip] 
    }
    ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"] 
    }
egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"] 
      
    }
    tags = {
    Name: "${var.env-prefix}-myapp_sg"
    }
  }


data "aws_ami" "myapp_ami" {
  most_recent = true
  owners = ["amazon"]
  
  filter {
    name   = "name"
    values = ["*-ami-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}
resource "aws_key_pair" "ssh_key" {
  
  key_name = "server-key"
  public_key = file(var.public_key_location)
}
 output "ec2_ip" {
  value = aws_instance.myapp_server.public_ip
}
resource "aws_instance" "myapp_server" {
  ami = data.aws_ami.myapp_ami.id
  instance_type = "var.instance_type"

  subnet_id = aws_subnet.myapp_subnet.id
  vpc_security_group_ids = [aws_security_group.myapp_sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh_key.key_name
  tags = {
    Name = "${var.env-prefix}-myapp-server"
  }
}