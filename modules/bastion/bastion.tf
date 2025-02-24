variable "app_name" {}
variable "vpc_id" {}
variable "public_subnet_id_1a" {}

# Security Group
resource "aws_security_group" "bastion_sg" {
  name   = "${var.app_name}-bastion-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-bastion-sg"
  }
}

resource "aws_security_group_rule" "bastion_sg_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

# IAM Role
data "aws_iam_policy_document" "ssm_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ssm_role" {
  name               = "EC2RoleforSSM-${var.app_name}"
  assume_role_policy = data.aws_iam_policy_document.ssm_role.json
}

resource "aws_iam_instance_profile" "ssm_role" {
  name = "EC2RoleforSSM-${var.app_name}"
  role = aws_iam_role.ssm_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_role" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_instance" "bastion" {
  ami                         = "ami-020283e959651b381"
  instance_type               = "t3a.nano"
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = "staging-bastion"
  subnet_id                   = var.public_subnet_id_1a
  associate_public_ip_address = true

  ebs_optimized = true

  iam_instance_profile = "EC2RoleforSSM-${var.app_name}"

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
    sudo yum install -y https://s3.ap-northeast-1.amazonaws.com/amazon-ssm-ap-northeast-1/latest/linux_amd64/amazon-ssm-agent.rpm
    sudo systemctl enable amazon-ssm-agent --now
  EOF

  tags = {
    Name = "${var.app_name}-bastion"
  }
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}
