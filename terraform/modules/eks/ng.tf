data "aws_subnet" "private_subnets" {
  count = length(var.private_subnets)
  id    = var.private_subnets[count.index]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  lifecycle {
    ignore_changes = [
      addon_version
    ]
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  lifecycle {
    ignore_changes = [
      addon_version
    ]
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  lifecycle {
    ignore_changes = [
      addon_version
    ]
  }

  depends_on = [
    aws_eks_node_group.eks-node-group-small,
    aws_eks_node_group.eks-node-group-large
  ]
}

resource "aws_eks_addon" "ebs-csi-driver" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs-csi-controller.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  lifecycle {
    ignore_changes = [
      addon_version
    ]
  }

  depends_on = [
    aws_eks_node_group.eks-node-group-small,
    aws_eks_node_group.eks-node-group-large
  ]
}



resource "aws_eks_addon" "identity_agent" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  lifecycle {
    ignore_changes = [
      addon_version
    ]
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}

############### NODE GROUP CONFIGS SMALL ####################

resource "aws_eks_node_group" "eks-node-group-small" {
  cluster_name           = var.cluster_name
  node_group_name_prefix = "${var.cluster_name}_small_spot_"
  node_role_arn          = aws_iam_role.node.arn
  subnet_ids             = var.private_subnets
  capacity_type          = "SPOT"
  instance_types         = var.small_instance_types

  depends_on = [
    aws_eks_cluster.main,
    aws_launch_template.lt-eks-ng,
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy
  ]

  scaling_config {
    desired_size = var.small_instance_desired_capacity
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  launch_template {
    name    = aws_launch_template.lt-eks-ng.name
    version = aws_launch_template.lt-eks-ng.latest_version
  }

  labels = {
    "eks/cluster-name"   = aws_eks_cluster.main.name
    "eks/nodegroup-name" = format("eks-ng-%s", aws_eks_cluster.main.name)
    "lifecycle"          = "Ec2Spot"
    "eks/nodeGroupSize"  = "SMALL"
  }

  tags = {
    "k8s.io/cluster-autoscaler/enabled"                     = "true"
    "k8s.io/cluster-autoscaler/var.cluster_name"            = var.cluster_name
    "k8s.io/cluster-autoscaler/node-template/capacity-type" = "SPOT"
    "eks/cluster-name"                                      = aws_eks_cluster.main.name
    "eks/nodegroup-name"                                    = format("eks-ng-%s", aws_eks_cluster.main.name)
    "eks/nodegroup-type"                                    = "managed"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name"           = aws_eks_cluster.main.name
    "Name"                                                  = "${var.prefix}"
    "Environment"                                           = terraform.workspace
    "Project"                                               = "${var.project}"
    "Application"                                           = "${var.application}"
    "ManagedBy"                                             = "Terraform"
  }

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
      labels
    ]
  }

  timeouts {}
}
############### NODE GROUP CONFIGS BIG ####################

resource "aws_eks_node_group" "eks-node-group-large" {
  cluster_name           = var.cluster_name
  node_group_name_prefix = "${var.cluster_name}_large_spot_"
  node_role_arn          = aws_iam_role.node.arn
  subnet_ids             = var.private_subnets
  capacity_type          = "SPOT"
  instance_types         = var.large_instance_types

  depends_on = [
    aws_eks_cluster.main,
    aws_launch_template.lt-eks-ng,
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy
  ]

  scaling_config {
    desired_size = var.large_instance_desired_capacity
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  launch_template {
    name    = aws_launch_template.lt-eks-ng.name
    version = aws_launch_template.lt-eks-ng.latest_version
  }

  labels = {
    "eks/cluster-name"   = aws_eks_cluster.main.name
    "eks/nodegroup-name" = format("eks-ng-spot-%s", aws_eks_cluster.main.name)
    "lifecycle"          = "Ec2Spot"
    "eks/nodeGroupSize"  = "LARGE"
  }

  tags = {
    "eks/cluster-name"                            = aws_eks_cluster.main.name
    "eks/nodegroup-name"                          = format("eks-ng-%s", aws_eks_cluster.main.name)
    "eks/nodegroup-type"                          = "managed"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = aws_eks_cluster.main.name
    "Name"                                        = "${var.prefix}-spot"
    "Environment"                                 = terraform.workspace
    "Project"                                     = "${var.project}"
    "Application"                                 = "${var.application}"
    "ManagedBy"                                   = "Terraform"
    "Savemoney"                                   = "True"
  }

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
      labels,
      tags,
      launch_template,
    ]
  }

  timeouts {}
}
