module "vpc" {
  source = "./modules/vpc"
  vpc_cidr_block = var.vpc_cidr_block
  env = var.env
  subnet_cidr_block = var.subnet_cidr_block
  default_vpc_id=var.default_vpc_id
  route_target_cidr_block = var.route_destination_cidr_block
  default_route_table_id = var.default_route_table_id
}
module "app"{
  source = "./modules/app"
  env = var.env
  instance_type = var.instance_type
  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.subnets_id

}