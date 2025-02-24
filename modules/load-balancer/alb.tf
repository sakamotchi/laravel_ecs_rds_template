variable "app_name" {}
variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "alb_domain" {}

# ACM
data "aws_acm_certificate" "acm" {
  domain = var.alb_domain
}

# ALB
resource "aws_security_group" "alb" {
  name   = "${var.app_name}-integrated-alb"
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "alb_http" {
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_https" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_alb" "alb" {
  name               = "${var.app_name}-alb"
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.alb.id
  ]
  subnets = var.subnet_ids
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.acm.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}

resource "aws_lb_target_group" "alb" {
  name        = "${var.app_name}-tg"
  port        = "80"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    port = 80
    path = "/"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_alb.alb.arn
#   port = 80
#   protocol = "HTTP"
#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.alb.arn
#   }
# }

output "aws_lb_target_group_arn" {
  value = aws_lb_target_group.alb.arn
}
