#  create VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env}-vpc"
  }
}
# ********************* create peer connection between two vpc ids **************************************************
resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id   = var.default_vpc_id
  vpc_id        = aws_vpc.vpc.id
  auto_accept   = true
  tags = {
    Name = "${var.env}-peer"
  }
}
# #****************** create private subnets for public,frontend,backend and mysql ************************************************************
# create public subnets
resource "aws_subnet" "public_subnets" {
  count         =  length(var.public_subnets)
  vpc_id        =  aws_vpc.vpc.id
  cidr_block    =  var.public_subnets[count.index]
availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.env}-public-subnet-${count.index+1}"
  }
}
# create frontend subnets
resource "aws_subnet" "frontend_subnets" {
  count        = length(var.frontend_subnets)
  vpc_id       = aws_vpc.vpc.id
  cidr_block   = var.frontend_subnets[count.index]
 availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.env}-frontend-subnet-${count.index+1}"
  }
}
# create backend subnets
# resource "aws_subnet" "backend_subnets" {
#   count        = length(var.backend_subnets)
#   vpc_id       = aws_vpc.vpc.id
#   cidr_block   = var.backend_subnets[count.index]
#   availability_zone = var.availability_zones[count.index]
#
#   tags = {
#     Name = "${var.env}-backend-subnet-${count.index+1}"
#   }
# }
# # create mysql subnets
# resource "aws_subnet" "mysql_subnets" {
#   count        = length(var.mysql_subnets)
#   vpc_id       = aws_vpc.vpc.id
#   cidr_block   = var.mysql_subnets[count.index]
#   availability_zone = var.availability_zones[count.index]
#
#   tags = {
#     Name = "${var.env}-db-subnet-${count.index+1}"
#   }
# }
# ************************************ End for creating private subnets ********************************************************
# create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.env}-igw"
  }
}
# ************************create a custom route table for public,frontend,backend and mysql **********************************************
# create public route table
resource "aws_route_table" "public_route_table" {
  count = length(var.public_subnets)
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.env}-public route-table-${count.index+1}"
  }
}
//create frontend route table
resource "aws_route_table" "frontend_route_table" {
  count = length(var.frontend_subnets)
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "${var.env}-frontend-route-table-${count.index+1}"
  }
}
# create backend route table
# resource "aws_route_table" "backend_route_table" {
#   count = length(var.backend_subnets)
#   vpc_id = aws_vpc.vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat[count.index].id
#   }
#   tags = {
#     Name = "${var.env}-backend-route-table-${count.index+1}"
#   }
# }
# # create db route table
# resource "aws_route_table" "mysql_route_table" {
#   count = length(var.mysql_subnets)
#   vpc_id = aws_vpc.vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat[count.index].id
#   }
#   tags = {
#     Name = "${var.env}-db-route-table-${count.index+1}"
#   }
# }
# *********************** End for creating custom route table ************************************************************
# create a nat gateway and get connection from public subnets and distribute this nat gateway to frontend,backend,db private subnets
//create nat gateway
resource "aws_nat_gateway" "nat" {
  count = length(var.public_subnets)
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  tags = {
    Name = "${var.env}-nat-${count.index+1}"
  }
}
  resource "aws_eip" "eip" {
    count = length(var.public_subnets)
    domain   = "vpc"
}
# ************************************End for nat gateway *************************************************************

# to communicate subnets to route tables to send traffic from subnets to route ***************************************
# associate route table id to subnet id
resource "aws_route_table_association" "public-route-association" {
  count = length(var.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table[count.index].id
}
resource "aws_route_table_association" "frontend-route-association" {
  count = length(var.frontend_subnets)
  subnet_id      = aws_subnet.frontend_subnets[count.index].id
  route_table_id = aws_route_table.frontend_route_table[count.index].id
}
//associate route table to backend subnet id
# resource "aws_route_table_association" "backend-route-association" {
#   count = length(var.backend_subnets)
#   subnet_id      = aws_subnet.backend_subnets[count.index].id
#   route_table_id = aws_route_table.backend_route_table[count.index].id
# }
# # //associate route table to backend subnet id
# resource "aws_route_table_association" "mysql-route-association" {
#  count = length(var.mysql_subnets)
#  subnet_id      = aws_subnet.mysql_subnets[count.index].id
#  route_table_id = aws_route_table.mysql_route_table[count.index].id
# }
# ************************************ End of the route table association ***********************************************
# to add the rules in route table to send traffic to other VPC
# edit public route
resource "aws_route" "public_route"{
  count = length(var.public_subnets)
  route_table_id = aws_route_table.public_route_table[count.index].id
  destination_cidr_block = var.default_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
# edit the frontend route
resource "aws_route" "frontend_route" {
  count = length(var.frontend_subnets)
  route_table_id = aws_route_table.frontend_route_table[count.index].id
  destination_cidr_block = var.default_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
//edit backend route
# resource "aws_route" "backend_route" {
#   count = length(var.backend_subnets)
#   route_table_id = aws_route_table.backend_route_table[count.index].id
#   destination_cidr_block = var.default_vpc_cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
# }
# # edit mysql route
# resource "aws_route" "mysql_route" {
#   count = length(var.mysql_subnets)
#   route_table_id = aws_route_table.mysql_route_table[count.index].id
#   destination_cidr_block = var.default_vpc_cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
# }
# default edit route
resource "aws_route" "default_route" {
  count = length(var.frontend_subnets)
  route_table_id = var.default_route_table_id
  destination_cidr_block = var.frontend_subnets[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}



