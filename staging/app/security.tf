resource "aws_security_group" "lb-staging" {
  name        = "musicbox-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.staging.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Traffic from ECS cluster may cross the nat gateway
resource "aws_security_group" "nat-gateway-staging" {
  name        = "musicbox-nat-gateawy-staging"
  description = "allow traffic to cross from ecs tasks"
  vpc_id      = aws_vpc.staging.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.ecs-tasks-staging.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [aws_security_group.ecs-tasks-staging.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs-tasks-staging" {
  name        = "musicbox-ecs-tasks-security-group-staging"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.staging.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.lb-staging.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs-ecr-staging" {
  name        = "musicbox-ecs-ecr-security-group-staging"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.staging.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Traffic to the DB should only come from the ECS Task security group
resource "aws_security_group" "db-staging" {
  name   = "musicbox-db-security-group-staging"
  vpc_id = aws_vpc.staging.id
  ingress {
    protocol  = "tcp"
    from_port = 5432
    to_port   = 5432
    security_groups = [
      aws_security_group.ecs-tasks-staging.id,
      aws_security_group.session-manager-staging.id
    ]
  }

  egress {
    protocol  = "tcp"
    from_port = 5432
    to_port   = 5432
    security_groups = [
      aws_security_group.ecs-tasks-staging.id,
      aws_security_group.session-manager-staging.id
    ]
  }
}

resource "aws_security_group" "redis-staging" {
  name   = "musicbox-redis-security-group-staging"
  vpc_id = aws_vpc.staging.id
  ingress {
    protocol        = "tcp"
    from_port       = 6379
    to_port         = 6379
    security_groups = [aws_security_group.ecs-tasks-staging.id]
  }

  egress {
    protocol        = "tcp"
    from_port       = 6379
    to_port         = 6379
    security_groups = [aws_security_group.ecs-tasks-staging.id]
  }
}
