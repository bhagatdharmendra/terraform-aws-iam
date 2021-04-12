provider "aws" {
  region     = "ap-south-1"
   profile = "sonu-terraform"
}

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "sonu-vpc"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-sonu-vpc-subnet"
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "private-sonu-vpc-subnet"
  }
}
######### public Security Group 
resource "aws_security_group" "allow_tls" {
  name        = "public_sonu_vpc"
  description = "ssh,http"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allports
    iterator = port
    content{
    from_port   = port.value
    to_port     = port.value
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  }
  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public_sonu_vpc_SG"
  }
}

######### private Security Group 
resource "aws_security_group" "allow_tls2" {
  name        = "private_sonu_vpc"
  description = "ssh,http for private access only "
  vpc_id      = aws_vpc.main.id

   dynamic "ingress" {
    for_each = var.allprivate_ports
   iterator = port
    content{
    
    from_port   = port.value
    to_port     = port.value
    protocol    = "tcp"
    security_groups = [ aws_security_group.allow_tls.id ]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private_sonu_vpc_SG"
  }
  
}
##### Internet Gateways for public instance ##
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "sonu-vpc-gateways"
  }
}
##### routing tables #######
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

   tags = {
    Name = "public_routing_tables"
  }
  depends_on = [
    aws_internet_gateway.gw
  ]
}

######## public subnet association with routing table  ###
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.r.id
  
  depends_on = [
    aws_subnet.subnet-1
       
  ]

}


 
######### Launch EC2-instance  in public subnet  ######  

resource "aws_instance" "instance1" {
  ami           = "ami-0732b62d310b80e97"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.allow_tls.id ]
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnet-1.id
  key_name = "bhagat-laptopkey"
  
  
  
  tags = {
    Name = "wordpress-public"
  }
 
}

output "ip_of_instnace" {
  value = aws_instance.instance1.public_ip
}



locals {
  ingres_rules = [{
   port = 80
   description = "port 80 allow"
  },
  {
    port = 443
   description = "port 443 allow"
  },
   {
    port = 22
   description = "port 22 allow"
  },
   {
   port = 9090
   description = "port 22 allow"
  }
  ]
}
resource "aws_security_group" "allow_tls_ext" {
  name        = "test_sg"
  vpc_id      = aws_vpc.main.id
  dynamic "ingress" {
    for_each = local.ingres_rules
    content {
      description = ingress.value.description
      from_port = ingress.value.port
      to_port = ingress.value.port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags = {
    "Name" = "test_sg"
  }
}