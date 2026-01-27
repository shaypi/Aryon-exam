resource "aws_iam_policy" "alb_controller" {
  name        = "${var.prefix}-aws-load-balancer-controller"
  description = "Permissions for AWS Load Balancer Controller in EKS"
  policy      = file("${path.module}/alb_controller_policy.json")
}

resource "aws_iam_role" "alb_controller" {
  name = "${var.prefix}-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller",
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}

output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller.arn
}
