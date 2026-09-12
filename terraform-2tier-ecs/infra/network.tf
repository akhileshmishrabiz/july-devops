# region - ap-south-1, zones - a, b
# aws vpc - 10.0.0.0/16 

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.environment}-${var.prefix}-main"
    # string interpolation
  }
}

# public subnet - 10.0.1.0/24, 10.0.2.0/24
resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "${var.environment}-${var.prefix}-public-subnet-1"
  }
}


resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "${var.environment}-${var.prefix}-public-subnet-2"
  }
}

# private subnet - 10.0.3.0/24, 10.0.4.0/24
resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "${var.environment}-${var.prefix}-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-subnet-2"
  }
}

# rds subnet - 10.0.5.0/24, 10.0.6.0/24
resource "aws_subnet" "rds_subnet_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "${var.environment}-${var.prefix}-rds-subnet-1"
  }
}

resource "aws_subnet" "rds_subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "${var.environment}-${var.prefix}-rds-subnet-2"
  }
}


# public route table

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id 

  tags = {
    Name = "${var.environment}-${var.prefix}-public-route-table"
  }
}
# private route table

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-${var.prefix}-private-route-table"
  }
}

# associate public subnet -> public route table

# implicit dependency
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}
# associate private subnet -> private route table

resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}
# internet gateway


# dependency
# 1. implicit dependency
# 2. explicit dependency -> depends_on


# internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.environment}-${var.prefix}-internet-gateway"
  }

  # explicit dependency
  depends_on = [aws_vpc.main]
}

# route to internet gateway

resource "aws_route" "public" {
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}


# eip
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.environment}-${var.prefix}-nat-eip"
  }
}

#  nat gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "${var.environment}-${var.prefix}-nat-gateway"
  }
}

resource "aws_route" "private_subnet_1_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}
