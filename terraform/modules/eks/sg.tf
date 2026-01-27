
resource "aws_security_group" "cluster-sg" {
  description = "communication between the control plane and worker nodes"
  vpc_id      = var.vpc_id
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}-eks-cluster-sg" })
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node-sg" {
  description = "Communication between all nodes within the cluster"
  vpc_id      = var.vpc_id
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}-eks-node-sg" })
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "eks-all" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster-sg.id
}

resource "aws_security_group_rule" "eks-all-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cluster-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "eks-node" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.node-sg.id
}


resource "aws_security_group_rule" "eks-node-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "eks-all-node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.node-sg.id
  security_group_id        = aws_security_group.cluster-sg.id
}

resource "aws_security_group_rule" "eks-node-all" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.cluster-sg.id
  security_group_id        = aws_security_group.node-sg.id
}

resource "aws_security_group_rule" "eks-all-self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.cluster-sg.id
}

resource "aws_security_group_rule" "eks-node-self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.node-sg.id
}
