variable "name" {
  description = "name for aws_security_group"
  type        = string
}

variable "vpc" {
  description = "name of VPC"
  type        = string
}

variable "ingr" {
  type = list(object({
    desc     = string
    from     = number
    to       = number
    protocol = string
    cidr     = list(string)
    sg       = list(string)
    self     = bool
  }))
}

variable "egr" {
  type = list(object({
    from     = number
    to       = number
    protocol = string
    cidr     = list(string)
    sg       = list(string)
    self     = bool
  }))
}
