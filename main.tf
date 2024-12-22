module "vpc" {
  source = "./modules/vpc"
  env = var.env
  vpc_cidr_block = var.vpc_cidr_block
}
module "app"{
  source = "./modules/app"
  env = var.env
  instance_type = var.instance_type

  subnet_id = ""
  vpc_id    = ""
}