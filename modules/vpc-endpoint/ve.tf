variable "app_name" {}
variable "vpc_id" {}
variable "route_table_ids" {
  type = list(string)
}
variable "security_group_id" {}
variable "subnet_ids" {
  type = list(string)
}

# VPC Endpoint DockerイメージをNatゲートウェイ経由ではなくVPC Endpoint経由で取得（コスト観点）

# Pull Container Image
resource "aws_vpc_endpoint" "s3" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = var.route_table_ids
  tags = {
    Name = "${var.app_name}-s3"
  }
}

# Execute docker command
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids = var.subnet_ids
  security_group_ids = [
    var.security_group_id
  ]
  private_dns_enabled = true
  tags = {
    Name = "${var.app_name}-ecr-dkr"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids = var.subnet_ids
  security_group_ids = [
    var.security_group_id
  ]
  private_dns_enabled = true
}

# コンテナ内のログをCloudwatchに送信する
resource "aws_vpc_endpoint" "logs" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids = var.subnet_ids
  security_group_ids = [
    var.security_group_id
  ]
  private_dns_enabled = true
}

# Fargateからパラメータストアの値をの環境変数に注入
resource "aws_vpc_endpoint" "ssm" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids = var.subnet_ids
  security_group_ids = [
    var.security_group_id
  ]
  private_dns_enabled = true
}
