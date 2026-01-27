resource "aws_launch_template" "lt-eks-ng" {
  name                   = "${var.prefix}-eks-lt"
  description            = "K8Trust EKS cluster template"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      tomap({ "Name" = "${var.prefix}" })
    )
  }


  vpc_security_group_ids = [aws_security_group.node-sg.id]

  lifecycle {
    create_before_destroy = true
  }
}
