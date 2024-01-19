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
  ami = "ami-0d5d9d301c853a04a"
  instance_type = "c5a.2xlarge"
  subnet_id = aws_subnet.gromacs_public_subnet.id
  associate_public_ip_address = true
  key_name = "gromacs"
  vpc_security_group_ids = [ aws_security_group.gromacs_security_group.id ]
  instance_initiated_shutdown_behavior = terminate
  tags = {
    Name = "gromacs"
  }
}

# Compute Node(s) Configuration
resource "aws_placement_group" "gromacs_placement_group" {
  name = "gromacs"
  strategy = "cluster"
}

resource "aws_autoscaling_attachment" "gromacs_autoscaling_attachment" {
  autoscaling_group_name = aws_autoscaling_group.gromacs_compute_nodes.name
  lb_target_group_arn = aws_lb_target_group.gromacs_target_group.arn 
}
resource "aws_autoscaling_group" "gromacs_compute_nodes" {
  name = "gromacs"
  max_size = 20
  min_size = 1
  launch_configuration = aws_launch_configuration.gromacs_launch_configuration.name
  vpc_zone_identifier = [ aws_subnet.gromacs_private_subnet.id ]
  depends_on = [ aws_instance.gromacs_head_node ]
  availability_zones = [us-east-2a]
  placement_group = aws_placement_group.gromacs_placement_group.name
  health_check_grace_period = 300
  health_check_type = "EC2"
}

resource "aws_launch_configuration" "gromacs_launch_configuration" {
  name = "gromacs"
  image_id = "ami-0d5d9d301c853a04a"
  instance_type = "c5a.2xlarge"
  associate_public_ip_address = false
  key_name = "gromacs"
  security_groups = [ aws_security_group.gromacs_security_group.id ]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y nfs-utils
              sudo mkdir /mnt/efs
              sudo mount -t efs ${aws_efs_file_system.gromacs_file_system.dns_name}:/ /mnt/efs
              EOF
}

resource "aws_autoscaling_policy" "gromacs_autoscaling_policy" {
  name = "gromacs"
  policy_type = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.gromacs_compute_nodes.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}

resource "aws_cloudwatch_metric_alarm" "gromacs_cloudwatch_metric_alarm" {
  alarm_name = "gromacs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = 50.0
  alarm_description = "Scale compute nodes up and down based on CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.gromacs_autoscaling_policy.arn ]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.gromacs_compute_nodes.name
  }
}

//////////////////////////////



# File System Configuration
resource "aws_efs_file_system" "gromacs_file_system" {
  creation_token = "gromacs"
  encrypted = true
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"

}

resource "aws_efs_mount_target" "gromacs_mount_target" {
  file_system_id = aws_efs_file_system.gromacs_file_system.id
  subnet_id = aws_subnet.gromacs_private_subnet.id
  security_groups = [ aws_security_group.gromacs_security_group.id ]
}

//////////////////////////////

# Security Group Configuration
resource "aws_security_group" "gromacs_security_group" {
  name = "gromacs"
  description = "Security group for GROMACS cluster"

  vpc_id = aws_vpc.gromacs_vpc.id

  ingress {
    description = "SSH access"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP access"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTPS access"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
