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
}

# Private Subnet Configuration
resource "aws_subnet" "gromacs_private_subnet" {
  vpc_id = aws_vpc.gromacs_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2a"
}

# TODO add NAT Gateway and Internet Gateway!!

# Head Node Configuration
resource "aws_instance" "gromacs_head_node" {
  
}

# Compute Node(s) Configuration
resource "aws_autoscaling_group" "gromacs_compute_nodes" {
  
}

# File System Configuration
resource "aws_efs_file_system" "gromacs_file_system" {
  
}