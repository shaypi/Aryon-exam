#General vars
region      = "eu-north-1"
prefix      = "k"
project     = "playground"
application = "Aryon"

#VPC
create_vpc          = true
cidr_block          = "10.0.16.0/22"
azs                 = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
public_subnet_cidr  = ["10.0.16.0/27", "10.0.16.32/27", "10.0.16.64/27"]
private_subnet_cidr = ["10.0.17.0/25", "10.0.17.128/25", "10.0.18.0/25"]
enable_nat_gateway  = true
public_eks_tag      = { "kubernetes.io/role/elb" = 1 }
private_eks_tag     = { "kubernetes.io/role/internal-elb" = 1 }
eks_cluster_name    = "Aryon"


#EKS
cluster_name                    = "Aryon"
k8s_version                     = "1.34"
aws_iam                         = "eks-cluster-cap"
desired_capacity                = 1
small_instance_desired_capacity = 2
large_instance_desired_capacity = 1
max_size                        = 10
min_size                        = 0
max_unavailable                 = 1
endpoint_private_access         = true
endpoint_public_access          = true
eks_cw_logging                  = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
small_instance_types            = ["m5.large", "t3.large", "m7i-flex.large", "m6in.large", "m7a.large", "m7i.large", "m5d.large", "m6i.large"]
large_instance_types            = ["m5.xlarge", "t3.xlarge", "m7i-flex.xlarge", "m6in.xlarge", "m7a.xlarge", "m7i.xlarge", "m5d.xlarge", "m6i.xlarge"]
