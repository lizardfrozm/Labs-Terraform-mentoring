variable "region_name" {
  description = "Value of the region"
  type        = list(string)
}

variable "instcl" {
  description = "Instance classes for RDS"
  type        = list(string)
}

variable "instacg" {
  description = "Instance classes for ACG"
  type        = list(string)
}


