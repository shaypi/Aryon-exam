data "aws_iam_policy_document" "ebs-csi-controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ebs-csi-controller" {
  assume_role_policy = data.aws_iam_policy_document.ebs-csi-controller_assume_role_policy.json
  name               = "ebs-csi-controller-${var.project}"
}

resource "aws_iam_policy" "ebs_csi_driver" {
  policy = file("../../modules/eks/iam-AmazonEKS_EBS_CSI_Policy.json")
  name   = "${var.aws_iam}-ebs-csi-driver"
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs-csi-controller.name
  policy_arn = aws_iam_policy.ebs_csi_driver.arn
}