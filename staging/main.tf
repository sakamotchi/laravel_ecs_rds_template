variable "app_name" {}
variable "php_image" {}
variable "web_image" {}
variable "db_database" {}
variable "db_username" {}
variable "db_password" {}
variable "db_username_super_user" {}
variable "db_password_super_user" {}
variable "log_channel" {}
variable "alb_domain" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.31.0"
    }
  }
  backend "s3" { # バケットは手動作成済み
    bucket  = "api-tfstate"
    region  = "ap-northeast-1"
    key     = "terraform.tfstate"
    encrypt = true
  }
}

locals {
  app_name = var.app_name
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      application = "${local.app_name}"
    }
  }
}

# VPC
module "vpc" {
  source   = "../modules/vpc"
  app_name = local.app_name
}

# HTTPS Security Group
module "https_sg" {
  source     = "../modules/security-group"
  name       = "https_sg"
  vpc_id     = module.vpc.vpc_id
  port       = 443
  cidr_block = ["0.0.0.0/0"]
}

# VPC Endpoint
module "vpd_endpoint" {
  source            = "../modules/vpc-endpoint"
  app_name          = local.app_name
  vpc_id            = module.vpc.vpc_id
  route_table_ids   = module.vpc.private_route_table_ids
  security_group_id = module.https_sg.security_group_id
  subnet_ids        = module.vpc.private_subnet_ids
  depends_on        = [module.vpc]
}

# Application Load Balancer
module "alb" {
  source     = "../modules/load-balancer"
  app_name   = local.app_name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  depends_on = [module.vpc]
  alb_domain = var.alb_domain
}

# SSM
module "ssm" {
  source                 = "../modules/ssm"
  app_name               = local.app_name
  db_database            = var.db_database
  db_username            = var.db_username
  db_password            = var.db_password
  db_username_super_user = var.db_username_super_user
  db_password_super_user = var.db_password_super_user
}

# ECS
module "ecs" {
  source                     = "../modules/ecs"
  app_name                   = local.app_name
  vpc_id                     = module.vpc.vpc_id
  php_image                  = var.php_image
  web_image                  = var.web_image
  private_subnet_ids         = module.vpc.private_subnet_ids
  target_group_arn           = module.alb.aws_lb_target_group_arn
  depends_on                 = [module.alb]
  db_host                    = module.db.db_host_endpoint
  db_database                = var.db_database
  db_username                = var.db_username
  db_password_arn            = module.ssm.db_password_arn
  db_username_super_user     = var.db_username_super_user
  db_password_super_user_arn = module.ssm.db_password_super_user_arn
  log_channel                = var.log_channel
}

# bastion
module "bastion" {
  source              = "../modules/bastion"
  app_name            = local.app_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_id_1a = module.vpc.public_subnet_id_1a
}

module "db" {
  source                 = "../modules/rds"
  app_name               = local.app_name
  vpc_id                 = module.vpc.vpc_id
  ecs_sg_id              = module.ecs.ecs_sg_id
  subnet_ids             = module.vpc.private_subnet_ids
  db_database            = var.db_database
  db_username            = var.db_username
  db_password            = var.db_password
  db_username_super_user = var.db_username_super_user
  db_password_super_user = var.db_password_super_user
  bastion_sg_id          = module.bastion.bastion_sg_id
}
