# VPC Configuration
resource "aws_vpc" "gromacs_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "gromacs"
  }
}

# Public Subnet Configuration


# Private Subnet Configuration

# Head Node Configuration

# Compute Node(s) Configuration

# File System Configuration