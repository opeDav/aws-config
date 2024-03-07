provider "aws" {}

resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.cidr_block[0]
  tags = {
    Name: "${var.env-prefix}-vpc"
    }
}

module "myapp_subnet_module" {
  source = "./modules/subnet"
  avail_zone = var.avail_zone
  env-prefix = var.env-prefix
  vpc_id = aws_vpc.myapp_vpc.id
  cidr_block = var.cidr_block
}

module "myapp_webserver_module" {
source = "./modules/webserver"
ip = var.ip
vpc_id = aws_vpc.myapp_vpc.id
env-prefix = var.env-prefix
public_key_location =var.public_key_location
avail_zone = var.avail_zone
instance_type = var.instance_type
subnet_id = module.myapp_subnet_module.subnet_output.id
  
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
  