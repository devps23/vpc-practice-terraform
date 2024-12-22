#  create VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env}-vpc"
  }
}
# create subnets
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr_block

  tags = {
    Name = "${var.env}-subnet"
  }
}