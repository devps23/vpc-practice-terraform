module "vpc" {
  source = "./modules/vpc"
  env = var.env
  vpc_cidr_block = var.vpc_cidr_block
  subnet_cidr_block = var.subnet_cidr_block
  default_vpc_id = var.default_vpc_id
  default_vpc_cidr_block = var.default_vpc_cidr_block
  default_route_table_id = var.default_route_table_id
}
module "app"{
  source = "./modules/app"
  env = var.env
  instance_type = var.instance_type

  subnet_id = ""
  vpc_id    = ""
}