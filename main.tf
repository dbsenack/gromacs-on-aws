# VPC Configuration
resource "aws_vpc" "gromacs_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "gromacs"
  }
}

# Public Subnet Configuration
resource "aws_subnet" "gromacs_public_subnet" {
  vpc_id = aws_vpc.gromacs_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "gromacs"
  }
}

# Private Subnet Configuration
resource "aws_subnet" "gromacs_private_subnet" {
  vpc_id = aws_vpc.gromacs_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "gromacs"
  }
}

# Internet and NAT Gateway Configuration
resource "aws_internet_gateway" "gromacs_internet_gateway" {
  vpc_id = aws_vpc.gromacs_vpc.id

  tags = {
    Name = "gromacs"
  }
}

resource "aws_internet_gateway_attachment" "gromacs_internet_gateway_attachment" {
  internet_gateway_id = aws_internet_gateway.gromacs_internet_gateway.id
  vpc_id = aws_vpc.gromacs_vpc.id
}

resource "aws_nat_gateway" "gromacs_nat_gateway" {
  allocation_id = aws_eip.gromacs_eip.id
  subnet_id = aws_subnet.gromacs_public_subnet.id

  tags = {
    Name = "gromacs"
  }
  
}

resource "aws_eip" "gromacs_eip" {
  domain = "vpc"

  instance = aws_instance.gromacs_head_node.id
  associate_with_private_ip = "10.0.1.12"
  depends_on = [ aws_internet_gateway_attachment.gromacs_internet_gateway_attachment, aws_internet_gateway.gromacs_internet_gateway ]

  tags = {
    Name = "gromacs"
  }
  
}

//////////////////////////////

# Head Node Configuration
resource "aws_instance" "gromacs_head_node" {
  
}

# Compute Node(s) Configuration
resource "aws_autoscaling_group" "gromacs_compute_nodes" {
  
}

# File System Configuration
resource "aws_efs_file_system" "gromacs_file_system" {
  
}