//NETWORK OUTPUTS
output "aws-vpc" {
  value = aws_vpc.aws-vpc.id
}

output "cidr_block" {
  value = aws_vpc.aws-vpc.cidr_block
}

output "aws-subnet-01" {
  value = aws_subnet.aws-subnet-01.id
}

output "aws-subnet-02" {
  value = aws_subnet.aws-subnet-02.id
}

output "aws-subnet-03" {
  value = aws_subnet.aws-subnet-03.id
}