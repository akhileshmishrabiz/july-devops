locals {
  public_subnets = {
    for subnet in var.public_subnet_data : subnet.name => subnet
  }

  private_subnets = {
    for subnet in var.private_subnet_data : subnet.name => subnet
  }

  # List order, so NAT count.index lands in that position's public subnet.
  public_subnet_names = [for subnet in var.public_subnet_data : subnet.name]

  public_name_by_az = {
    for subnet in var.public_subnet_data : subnet.availability_zone => subnet.name
  }

  nat_count = (
    var.need_nat_gateway
    ? (var.need_single_nat_gateway ? 1 : length(var.public_subnet_data))
    : 0
  )

  single_nat = var.need_nat_gateway && var.need_single_nat_gateway
  nat_per_az = var.need_nat_gateway && !var.need_single_nat_gateway
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-${each.value.prefix}-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.vpc_name}-${each.value.prefix}-${each.key}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = {
    Name = "${var.vpc_name}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[local.public_subnet_names[count.index]].id

  tags = {
    Name = "${var.vpc_name}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Shared private route table: used when there is no NAT, and when one NAT serves every private subnet.
resource "aws_route_table" "private" {
  count  = local.nat_per_az ? 0 : 1
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

resource "aws_route" "private_default" {
  count = local.single_nat ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

resource "aws_route_table_association" "private" {
  for_each = local.nat_per_az ? {} : local.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[0].id
}

# One route table per public subnet, each with its own NAT. A private subnet joins the table for its AZ.
resource "aws_route_table" "private_per_az" {
  for_each = local.nat_per_az ? local.public_subnets : {}

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[index(local.public_subnet_names, each.key)].id
  }

  tags = {
    Name = "${var.vpc_name}-private-${each.key}"
  }
}

resource "aws_route_table_association" "private_per_az" {
  for_each = local.nat_per_az ? local.private_subnets : {}

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private_per_az[local.public_name_by_az[each.value.availability_zone]].id
}
