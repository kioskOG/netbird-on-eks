output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "db_subnet_ids" {
  value = length(var.db_subnet_cidr_block) > 0 ? slice(aws_subnet.private_subnet[*].id, 0, length(var.db_subnet_cidr_block)) : []
}

output "private_subnet_ids" {
  value = length(var.db_subnet_cidr_block) > 0 ? slice(aws_subnet.private_subnet[*].id, length(var.db_subnet_cidr_block), length(var.db_subnet_cidr_block) + length(var.private_subnet_cidr_block)) : aws_subnet.private_subnet[*].id
}
