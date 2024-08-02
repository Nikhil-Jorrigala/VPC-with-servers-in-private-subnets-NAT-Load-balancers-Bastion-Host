# create a VPC
resource "aws_vpc" "myvpc-temp" {
  cidr_block = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyVPC"
  }
}

# create public subnets
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.myvpc-temp.id
  cidr_block = element(var.public_subnet_cidrs,count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
   Name = "Public Subnet ${count.index + 1}"
 }
}

# create private subnets
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.myvpc-temp.id
  cidr_block = element(var.private_subnet_cidrs,count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
   Name = "Private Subnet ${count.index + 1}"
 }
}

# ceate an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc-temp.id


  tags = {
    Name = "MyIGW"
  }
}

# create Route table for public 
resource "aws_route_table" "Public" {
  vpc_id = aws_vpc.myvpc-temp.id

  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }

}

# create a routetable association for public subnets
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  subnet_id = element(aws_subnet.public_subnets.*.id,count.index)
  route_table_id = aws_route_table.Public.id

}

# ceate Elastic Ips 
resource "aws_eip" "nat" {
  count = 2
  vpc = true
}

#create a nat gateway 
resource "aws_nat_gateway" "nat" {
    count = 2
allocation_id = element(aws_eip.nat.*.id,count.index)
subnet_id = element(aws_subnet.public_subnets.*.id, count.index)
tags = {
    Name = "NatGateway-${count.index}"
}
}

# create a route table for private subnets in availability zone1
resource "aws_route_table" "private_az1" {
  vpc_id = aws_vpc.myvpc-temp.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = {
    Name = "PrivateRouteTableAZ1"
  }
}

#create a route table for private subnets in availability zone2
resource "aws_route_table" "private_az2" {
  vpc_id = aws_vpc.myvpc-temp.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[1].id
  }

  tags = {
    Name = "PrivateRouteTableAZ2"
  }
}

#Route table association for private subnets in both availability zones 
resource "aws_route_table_association" "private_az1" {
  count = 1
  subnet_id = element(aws_subnet.private_subnets.*.id,0)
  route_table_id = aws_route_table.private_az1.id
}


resource "aws_route_table_association" "private_az2" {
  count = 1
  subnet_id = element(aws_subnet.private_subnets.*.id,1)
  route_table_id = aws_route_table.private_az2.id
}


# Create EC2 instances in private subnets
resource "aws_instance" "private_instance" {
  count = 2
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = element(aws_subnet.private_subnets.*.id, count.index)
  key_name = var.key_name
  security_groups = [aws_security_group.private_instance_sg.id]

  tags = {
    Name = "privateinstance-${count.index}"
  }
}

# create Bastion Host in public subnet
resource "aws_instance" "Bastion" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_subnets[0].id
  key_name = var.key_name
  security_groups = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "BastonHost"
  }
}

# Security group for bastion host
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.myvpc-temp.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = ["0.0.0.0/0"]

    }
    
  

  tags ={
      name = "BastionSecurityGroup"
    }
}

# security group for private subnets

resource "aws_security_group" "private_instance_sg" {
  vpc_id = aws_vpc.myvpc-temp.id

  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress  {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateInstanceSecurityGroup"
  }
}

# Create a security group for the load balancer
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.myvpc-temp.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALBSecurityGroup"
  }
}



# create a load Balancer
resource "aws_lb" "app_lb" {
  name = "app-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets = aws_subnet.public_subnets[*].id
  
  tags = {
    name = "AppLB"
  }
}

# create a target group
resource "aws_lb_target_group" "app_tg" {
  name = "app-tg"
  port = 80 
  protocol = "HTTP"
  vpc_id = aws_vpc.myvpc-temp.id

  health_check {
    path        = "/"
    interval    = 30
    timeout     = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

  tags = {
    name = "AppTargetGroup"
  }
  
}


# attach instance to the target group
resource "aws_lb_target_group_attachment" "app_tag_attachment" {
  count = 2
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id = element(aws_instance.private_instance[*].id,count.index)
  port = 80
  
}


# create a listener for load balancer
resource "aws_lb_listener" "aws_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
