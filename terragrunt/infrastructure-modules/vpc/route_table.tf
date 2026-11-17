resource "aws_route_table" "pub_sub_route" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_internet_gateway.igw]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.vpc_name}-${var.vpc_env}-public_rt"
  }
}

resource "aws_route_table" "pri_sub_route" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_nat_gateway.ngw]
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "${var.vpc_name}-${var.vpc_env}-private-rt"
  }
}

resource "aws_route_table" "db_sub_route" {
  count  = length(var.db_subnet_cidr_block) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "${var.vpc_name}-${var.vpc_env}-db-rt"
  }
}
