variable "app_name" {}
variable "vpc_id" {}
variable "ecs_sg_id" {}
variable "subnet_ids" {}
variable "db_database" {}
variable "db_username" {}
variable "db_password" {}
variable "db_username_super_user" {}
variable "db_password_super_user" {}
variable "bastion_sg_id" {}

# Security Group
resource "aws_security_group" "database_sg" {
  name   = "${var.app_name}-database-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-database-sg"
  }
}

resource "aws_security_group_rule" "database_sg_rule" {
  security_group_id        = aws_security_group.database_sg.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.ecs_sg_id # ECSのSGからのアクセスを許可
}

resource "aws_security_group_rule" "from_bastion" {
  security_group_id        = aws_security_group.database_sg.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.bastion_sg_id
}

resource "aws_db_subnet_group" "database_sg_group" {
  name       = "${var.app_name}-database-subnet-group"
  subnet_ids = var.subnet_ids
}

# RDS Cluster
resource "aws_rds_cluster_parameter_group" "cluster_parameter_group" {
  name   = "${var.app_name}-cluster-parameter-group"
  family = "aurora-postgresql15"
}

resource "aws_rds_cluster" "database" {
  cluster_identifier     = "${var.app_name}-cluster"
  db_subnet_group_name   = aws_db_subnet_group.database_sg_group.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]

  engine         = "aurora-postgresql"
  engine_version = "15.4"
  port           = 5432

  database_name   = var.db_database
  master_username = var.db_username_super_user
  master_password = var.db_password_super_user

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_parameter_group.name

  deletion_protection = false
  skip_final_snapshot = true
  apply_immediately   = true
}

resource "aws_db_parameter_group" "db_parameter_group" {
  name   = "${var.app_name}-db-parameter-group"
  family = "aurora-postgresql15"

  parameter {
    name         = "log_min_duration_statement"
    value        = "1000"
    apply_method = "immediate"
  }
}

resource "aws_rds_cluster_instance" "cluster_instance" {
  identifier         = "${var.app_name}-database-cluster-instance"
  cluster_identifier = aws_rds_cluster.database.id

  engine         = aws_rds_cluster.database.engine
  engine_version = aws_rds_cluster.database.engine_version

  instance_class          = "db.t3.medium"
  db_subnet_group_name    = aws_db_subnet_group.database_sg_group.name
  db_parameter_group_name = aws_db_parameter_group.db_parameter_group.name
  publicly_accessible     = false
}

output "db_host_endpoint" {
  value = aws_rds_cluster.database.endpoint
}
