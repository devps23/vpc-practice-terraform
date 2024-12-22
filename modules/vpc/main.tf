#  create VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env}-vpc"
  }
}
# create subnets
resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr_block

  tags = {
    Name = "${var.env}-subnet"
  }
}
# create peer connection between two vpc ids
resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id   = var.default_vpc_id
  vpc_id        = aws_vpc.vpc.id
  auto_accept   = true
  tags = {
    Name = "${var.env}-peer"
  }
}
# Edit routes on main vpc route
# resource "aws_route" "main_edit_route" {
#   route_table_id            = aws_vpc.vpc.main_route_table_id
#   destination_cidr_block    = var.default_vpc_cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
# }
# Edit routes on default vpc route
resource "aws_route" "default_edit_route" {
  route_table_id            = var.default_route_table_id
  destination_cidr_block    = var.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
# create a route table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.env}-route-table"
  }
}
# associate route table id to subnet id
resource "aws_route_table_association" "subnet-rout-association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id

}
resource "aws_route" "custom_edit_route" {
  route_table_id            = aws_route_table.route_table.id
  destination_cidr_block    = var.default_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

}
# add routes to the route table
# add internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.env}-igw"
  }
}