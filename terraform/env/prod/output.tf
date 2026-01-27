# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}
output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "subnet_ids" {
  description = "List of public and private subnet to be used for EKS"
  value       = module.vpc.subnet_ids
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

output "cluster-sg" {
  description = "The security group ID associated with the cluster. Use this to identify or reference the cluster's security group in other resources."
  value       = module.sg.cluster-sg
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster. This is crucial for operations and management of the cluster within AWS."
  value       = module.eks.cluster_name
}




