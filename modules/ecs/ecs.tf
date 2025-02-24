variable "app_name" {}
variable "vpc_id" {}
variable "php_image" {}
variable "web_image" {}
variable "private_subnet_ids" {}
variable "target_group_arn" {}
variable "db_host" {}
variable "db_database" {}
variable "db_username" {}
variable "db_password_arn" {}
variable "db_username_super_user" {}
variable "db_password_super_user_arn" {}
variable "log_channel" {}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.app_name}-files"
}

resource "aws_s3_bucket_public_access_block" "bucket-private" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "bucket-ownership" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

# ECS IAM Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "php-log-group" {
  name              = "/${var.app_name}/ecs/php"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "web-log-group" {
  name              = "/${var.app_name}/ecs/web"
  retention_in_days = 30
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.app_name}-app-cluster"
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
  container_definitions = templatefile("${path.module}/container_definitions.json", {
    PHP_IMAGE                  = var.php_image
    WEB_IMAGE                  = var.web_image
    DB_HOST                    = var.db_host
    DB_DATABASE                = var.db_database
    DB_USERNAME                = var.db_username
    DB_PASSWORD_ARN            = var.db_password_arn
    DB_USERNAME_SUPER_USER     = var.db_username_super_user
    DB_PASSWORD_SUPER_USER_ARN = var.db_password_super_user_arn
    LOG_CHANNEL                = var.log_channel
    AWS_BUCKET                 = aws_s3_bucket.s3_bucket.bucket
    APP_NAME                   = var.app_name
  })
}

data "aws_ecs_task_definition" "task_definition" {
  task_definition = aws_ecs_task_definition.task_definition.family
}

resource "aws_security_group" "ecs" {
  name   = "${var.app_name}-ecs"
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.app_name}-ecs"
  }
}

resource "aws_security_group_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  # 同一VPC内からのみアクセス可能
  cidr_blocks = ["10.0.0.0/16"]
}

resource "aws_ecs_service" "ecs_service" {
  name             = "${var.app_name}-ecs-service"
  cluster          = aws_ecs_cluster.ecs_cluster.id
  platform_version = "1.4.0"
  # CodePipelineでデプロイ時にリビジョンが更新されるので、最新のリビジョンをdataで取得
  task_definition = data.aws_ecs_task_definition.task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = "1"
  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [
      aws_security_group.ecs.id
    ]
  }
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "web"
    container_port   = "80"
  }
}

output "ecs_sg_id" {
  value = aws_security_group.ecs.id
}
