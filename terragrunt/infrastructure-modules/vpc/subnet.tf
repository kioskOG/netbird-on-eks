resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnet_cidr_block)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidr_block, count.index)
  availability_zone       = element(var.public_subnet_availability_zone, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch # Enable public IP assignment
  tags = merge(
    {
      Name = "${var.vpc_name}-${var.vpc_env}-public-subnet-${count.index + 1}"
    },
    var.tags_all,
    var.public_subnet_tags
  )

  lifecycle {
    ignore_changes = [tags]
  }
}

locals {
  merged_private_subnet_cidrs = length(var.db_subnet_cidr_block) > 0 ? concat(var.db_subnet_cidr_block, var.private_subnet_cidr_block) : var.private_subnet_cidr_block
  merged_private_subnet_azs   = length(var.availability_zone_db_subnet) > 0 ? concat(var.availability_zone_db_subnet, var.availability_zone_private_subnet) : var.availability_zone_private_subnet
}

resource "aws_subnet" "private_subnet" {
  count             = length(local.merged_private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(local.merged_private_subnet_cidrs, count.index)
  availability_zone = element(local.merged_private_subnet_azs, count.index)
  tags = merge(
    {
      Name = "${var.vpc_name}-${var.vpc_env}-${length(var.db_subnet_cidr_block) > 0 && count.index < length(var.db_subnet_cidr_block) ? "db" : "private"}-subnet-${length(var.db_subnet_cidr_block) > 0 && count.index < length(var.db_subnet_cidr_block) ? count.index + 1 : count.index - length(var.db_subnet_cidr_block) + 1}"
    },
    var.tags_all,
    var.private_subnet_tags
  )

  lifecycle {
    ignore_changes = [tags]
  }
}
