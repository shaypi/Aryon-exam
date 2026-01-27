output "vpc_id" {
  description = "The ID of the VPC"
  value       = one(aws_vpc.main[*].id)
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = one(aws_vpc.main[*].arn)
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = one(aws_vpc.main[*].cidr_block)
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = one(aws_vpc.main[*].default_security_group_id)
}

output "default_route_table_id" {
  description = "The ID of the default route table"
  value       = one(aws_vpc.main[*].default_route_table_id)
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = one(aws_vpc.main[*].instance_tenancy)
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = one(aws_vpc.main[*].enable_dns_support)
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = one(aws_vpc.main[*].enable_dns_hostnames)
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with main VPC"
  value       = one(aws_vpc.main[*].main_route_table_id)
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "subnet_ids" {
  description = "List of public and private subnet to be used for EKS"
  value       = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = try(aws_eip.main.id, "")
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.main[*].public_ip
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = try(aws_nat_gateway.main.id, "")
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = one(aws_internet_gateway.main[*].id)
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = one(aws_internet_gateway.main[*].arn)
}

output "private_route_table_id" {
  value       = try(aws_route_table.private-rt.id, "")
  description = "The ID of the route table associated with the private subnets."
}

output "first_private_subnet_id" {
  value       = try(aws_subnet.private[0].id, "")
  description = "The ID of the first private subnet"
}
