
output "cluster_name" {
  value = aws_eks_cluster.main.name
  depends_on = [
    aws_eks_access_entry.terraform_caller,
    aws_eks_access_policy_association.terraform_caller_admin
  ]
}

output "ca" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.main.certificate_authority[0].data
  depends_on = [
    aws_eks_access_entry.terraform_caller,
    aws_eks_access_policy_association.terraform_caller_admin
  ]
}

output "endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
  depends_on = [
    aws_eks_access_entry.terraform_caller,
    aws_eks_access_policy_association.terraform_caller_admin
  ]
}

output "eks_cluster_sg" {
  value = aws_security_group.cluster-sg.id
}

output "eks_nodeg_sg" {
  value = aws_security_group.node-sg.id
}

locals {
  config-map-aws-auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - groups:
        - system:bootstrappers
        - system:nodes
      rolearn: ${aws_iam_role.node.arn}
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
        - system:masters
      rolearn: ${data.aws_caller_identity.current.arn}
      username: cluster-admin
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.main.endpoint}
    certificate-authority-data: ${aws_eks_cluster.main.certificate_authority[0].data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${aws_eks_cluster.main.name}"
KUBECONFIG
}

output "config_map_aws_auth" {
  value = local.config-map-aws-auth
}

output "kubeconfig" {
  value = local.kubeconfig
}

resource "local_file" "kube_config_file" {
  content  = local.kubeconfig
  filename = "config"
}

