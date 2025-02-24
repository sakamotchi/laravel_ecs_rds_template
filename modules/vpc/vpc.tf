variable "app_name" {
}

# VPC
resource "aws_vpc" "api" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw_01" {
  vpc_id = aws_vpc.api.id
  tags = {
    Name = "${var.app_name}-igw-01"
  }
}

# Public Subnet
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.api.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "${var.app_name}-pubic-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.api.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "${var.app_name}-public-1c"
  }
}

# Private Subnet
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.api.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "${var.app_name}-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.api.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "${var.app_name}-private-1c"
  }
}

# Public Subnet Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.api.id
  tags = {
    Name = "${var.app_name}-public"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw_01.id
  destination_cidr_block = "0.0.0.0/0"
}

# Public Route Table Association
resource "aws_route_table_association" "public_1a_to_igw" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c_to_igw" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

# Private Subnet Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.api.id
  tags = {
    Name = "${var.app_name}-private"
  }
}

# Private Route Table Association
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private.id
}

output "vpc_id" {
  value = aws_vpc.api.id
}

output "private_route_table_ids" {
  value = [
    aws_route_table.private.id
  ]
}

output "private_subnet_ids" {
  value = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id
  ]
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1c.id
  ]
}

output "public_subnet_id_1a" {
  value = aws_subnet.public_1a.id
}
