module "vpc" {
  source = "./modules/vpc"
  env = var.env
  vpc_cidr_block = var.vpc_cidr_block
  subnet_cidr_block = var.subnet_cidr_block
  default_vpc_id = var.default_vpc_id
  default_vpc_cidr_block = var.default_vpc_cidr_block
  default_route_table_id = var.default_route_table_id
  backend_subnets = var.backend_subnets
  db_subnets = var.db_subnets
  frontend_subnets = var.frontend_subnets
  public_subnets = var.public_subnets
}
# module "app"{
#   source = "./modules/app"
#   env = var.env
#   instance_type = var.instance_type
#   subnet_id = module.vpc.subnet
#   vpc_id    = module.vpc.vpc_id
# }
module "frontend"{
  depends_on = [module.backend]
  source = "./modules/app"
  env    = var.env
  instance_type = var.instance_type
  subnet_id = module.vpc.frontend_subnets
  vpc_id = module.vpc.vpc_id
  component = "frontend"
  lb_type = "public"
  zone_id = var.zone_id
#   load balancer connect to frontend
  lb_subnets = module.vpc.public_subnets
  lb_needed = true
  app_port = 80
  vault_token=var.vault_token
  server_app_port = var.public_subnets
  bastion_nodes = var.bastion_nodes
  lb_app_port = ["0.0.0.0/0"]
}
module "backend"{
  depends_on = [module.mysql]
  source = "./modules/app"
  env    = var.env
  instance_type = var.instance_type
  subnet_id = ""
  vpc_id = module.vpc.vpc_id
  component = "backend"
  lb_type = "private"
  zone_id = var.zone_id
  lb_subnets = module.vpc.backend_subnets
  lb_needed = true
  app_port = 8080
  vault_token=var.vault_token
  server_app_port = concat(var.frontend_subnets,var.backend_subnets)
  bastion_nodes = var.bastion_nodes
  lb_app_port = var.frontend_subnets
}
module "mysql"{
  source = "./modules/app"
  env    = var.env
  instance_type = var.instance_type
  subnet_id = ""
  vpc_id = module.vpc.vpc_id
  component = "mysql"
  zone_id = var.zone_id
  lb_subnets = module.vpc.backend_subnets
  app_port = 3306
  vault_token=var.vault_token
  server_app_port = var.backend_subnets
  bastion_nodes = var.bastion_nodes
}
