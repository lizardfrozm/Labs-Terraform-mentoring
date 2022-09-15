resource "aws_security_group" "sg" {
  name        = "${terraform.workspace}-${var.name}-sg"
  description = "${var.name} inbound traffic"
  vpc_id      = var.vpc

  dynamic "ingress" {
    for_each = var.ingr

    content {
      description     = ingress.value.desc
      from_port       = ingress.value.from
      to_port         = ingress.value.to
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr
      security_groups = ingress.value.sg
      self            = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = var.egr

    content {
      from_port       = egress.value.from
      to_port         = egress.value.to
      protocol        = egress.value.protocol
      cidr_blocks     = egress.value.cidr
      security_groups = egress.value.sg
      self            = egress.value.self
    }
  }
}
