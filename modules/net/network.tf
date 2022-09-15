resource "aws_vpc" "aws-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.aws-vpc.id
}

resource "aws_route_table" "aws-rt" {
  vpc_id = aws_vpc.aws-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_main_route_table_association" "rt-main" {
  vpc_id         = aws_vpc.aws-vpc.id
  route_table_id = aws_route_table.aws-rt.id
}

resource "aws_subnet" "aws-subnet-01" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.aws-vpc.id
  availability_zone       = "${var.az}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "aws-subnet-02" {
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.aws-vpc.id
  availability_zone       = "${var.az}b"
  map_public_ip_on_launch = true
}


resource "aws_subnet" "aws-subnet-03" {
  cidr_block              = "10.0.3.0/24"
  vpc_id                  = aws_vpc.aws-vpc.id
  availability_zone       = "${var.az}c"
  map_public_ip_on_launch = true
}
