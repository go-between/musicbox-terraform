# EC2 Instance
# resource "aws_instance" "ssm-staging" {
#   # amzn2-ami-hvm-2.0.20200207.1-x86_64-gp2
#   ami                    = "ami-0a887e401f7654935"
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.private-staging.0.id
#   iam_instance_profile   = aws_iam_instance_profile.ssm-staging.name
#   vpc_security_group_ids = [aws_security_group.session-manager-staging.id]
#   tags = {
#     Name = "SSM-Staging"
#   }

#   user_data = <<-EOF
#     #! /bin/bash
#     yum install -y ec2-instance-connect
#     yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
#   EOF
# }

# VPC Endpoint
# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id              = aws_vpc.staging.id
#   service_name        = "com.amazonaws.${var.aws_region}.ssm"
#   vpc_endpoint_type   = "Interface"
#   security_group_ids  = [aws_security_group.session-manager-vpc-staging.id]
#   subnet_ids          = aws_subnet.private-staging.*.id
#   private_dns_enabled = true
# }

# resource "aws_vpc_endpoint" "ec2messages" {
#   vpc_id              = aws_vpc.staging.id
#   service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
#   vpc_endpoint_type   = "Interface"
#   security_group_ids  = [aws_security_group.session-manager-vpc-staging.id]
#   subnet_ids          = aws_subnet.private-staging.*.id
#   private_dns_enabled = true
# }

# resource "aws_vpc_endpoint" "ssmmessages" {
#   vpc_id              = aws_vpc.staging.id
#   service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
#   vpc_endpoint_type   = "Interface"
#   security_group_ids  = [aws_security_group.session-manager-vpc-staging.id]
#   subnet_ids          = aws_subnet.private-staging.*.id
#   private_dns_enabled = true
# }

# Security
resource "aws_security_group" "session-manager-staging" {
  name   = "session-manager-staging"
  vpc_id = aws_vpc.staging.id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "session-manager-vpc-staging" {
  name   = "session-manager-vpc-staging"
  vpc_id = aws_vpc.staging.id

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    security_groups = [
      aws_security_group.session-manager-staging.id
    ]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Role
resource "aws_iam_instance_profile" "ssm-staging" {
  name = "ssm-staging"
  role = aws_iam_role.ssm-staging.name
  path = "/"
}

resource "aws_iam_role" "ssm-staging" {
  name               = "ssm-staging"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  path               = "/"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ssm-staging" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_policy" "ssm-staging" {
  name   = "ssm-staging"
  policy = data.aws_iam_policy.ssm-staging.policy
  path   = "/"
}

resource "aws_iam_role_policy_attachment" "ssm-staging" {
  role       = aws_iam_role.ssm-staging.name
  policy_arn = aws_iam_policy.ssm-staging.arn
}

# Allow musicbox-truman user to send an SSH key and sign in to SSM
data "aws_caller_identity" "current" {}

# data "aws_iam_policy_document" "ssm-ssh-management-staging" {
#   statement {
#     actions = [
#       "ec2-instance-connect:SendSSHPublicKey"
#     ]
#     resources = [
#       "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.ssm-staging.id}"
#     ]
#   }
# }

# resource "aws_iam_policy" "ssm-ssh-management-staging" {
#   name   = "ssm-ssh-management-staging"
#   path   = "/"
#   policy = data.aws_iam_policy_document.ssm-ssh-management-staging.json
# }

# resource "aws_iam_policy_attachment" "ssm-ssh-management-staging" {
#   name       = "ssm-ssh-management-staging"
#   users      = ["musicbox-truman"]
#   policy_arn = aws_iam_policy.ssm-ssh-management-staging.arn
# }
