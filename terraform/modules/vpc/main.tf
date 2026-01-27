locals {
  max_subnet_length = max(
    length(var.private_subnet_cidr),
  )
  common_tags = {
    Environment = terraform.workspace
    Project     = "${var.project}"
    Application = "${var.application}"
    ManagedBy   = "Terraform"
  }
}
resource "aws_vpc" "main" {
  count                = var.create_vpc ? 1 : 0
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}" })
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main[0].id

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}-ig" })
  )
}

resource "aws_eip" "main" {
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}-eip" })
  )
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id = element(
  aws_subnet.public.*.id, 1)

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}-nat" })
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidr)
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.public_subnet_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    local.common_tags,
    var.public_eks_tag,
    tomap({ "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared" }),
    tomap({ "Name" = "${var.prefix}-pub${count.index}-${var.azs[count.index]}" })
  )
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    local.common_tags,
    var.private_eks_tag,
    tomap({ "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared" }),
    tomap({ "Name" = "${var.prefix}-pvt${count.index}-${var.azs[count.index]}" })
  )
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main[0].id
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}-public-rt" })
  )
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route" "public-internet-access" {
  route_table_id         = aws_route_table.public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.main[0].id
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}-private-rt" })
  )
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route" "route-nat-gateway" {
  route_table_id         = aws_route_table.private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.main.id
}