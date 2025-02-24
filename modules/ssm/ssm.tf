variable "app_name" {}
variable "db_database" {}
variable "db_username" {}
variable "db_password" {}
variable "db_username_super_user" {}
variable "db_password_super_user" {}

# パラメータストア
resource "aws_ssm_parameter" "db_database" {
  name  = "/${var.app_name}/DB_DATABASE"
  type  = "String"
  value = "db"
}
resource "aws_ssm_parameter" "db_username" {
  name  = "/${var.app_name}/DB_USERNAME"
  type  = "String"
  value = var.db_username
}
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.app_name}/DB_PASSWORD"
  type  = "SecureString"
  value = var.db_password
}
resource "aws_ssm_parameter" "db_username_super_user" {
  name  = "/${var.app_name}/DB_USERNAME_SUPER_USER"
  type  = "String"
  value = var.db_username_super_user
}
resource "aws_ssm_parameter" "db_password_super_user" {
  name  = "/${var.app_name}/DB_PASSWORD_SUPER_USER"
  type  = "SecureString"
  value = var.db_password_super_user
}

output "db_password_arn" {
  value = aws_ssm_parameter.db_password.arn
}

output "db_password_super_user_arn" {
  value = aws_ssm_parameter.db_password_super_user.arn
}
