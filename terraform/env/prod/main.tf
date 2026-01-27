provider "aws" {
  region = var.region
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  create_vpc          = true
  source              = "../../modules/vpc"
  cidr_block          = var.cidr_block
  azs                 = data.aws_availability_zones.available.names
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  public_eks_tag      = var.public_eks_tag
  private_eks_tag     = var.private_eks_tag
  prefix              = var.prefix
  project             = var.project
  application         = var.application
  eks_cluster_name    = var.eks_cluster_name
}

module "sg" {
  source      = "../../modules/sg"
  vpc_id      = module.vpc.vpc_id
  prefix      = var.prefix
  project     = var.project
  application = var.application
}

module "eks" {
  source                          = "../../modules/eks"
  cluster_name                    = var.cluster_name
  k8s_version                     = var.k8s_version
  small_instance_desired_capacity = var.small_instance_desired_capacity
  large_instance_desired_capacity = var.large_instance_desired_capacity
  large_instance_types            = var.large_instance_types
  small_instance_types            = var.small_instance_types

  max_size                = var.max_size
  min_size                = var.min_size
  max_unavailable         = var.max_unavailable
  vpc_id                  = module.vpc.vpc_id
  vpc_cidr                = module.vpc.vpc_cidr
  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  subnet_ids              = module.vpc.subnet_ids
  private_subnets         = module.vpc.private_subnets
  vpc_subnet_cidr         = module.vpc.vpc_cidr
  private_subnet_cidr     = module.vpc.private_subnets_cidr_blocks
  public_subnet_cidr      = module.vpc.public_subnets_cidr_blocks
  eks_cw_logging          = var.eks_cw_logging
  prefix                  = var.prefix
  project                 = var.project
  application             = var.application
  aws_iam                 = var.aws_iam
  account_id              = var.account_id
  subnet_id               = module.vpc.private_subnets
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }
  volume_binding_mode = "WaitForFirstConsumer"
}


