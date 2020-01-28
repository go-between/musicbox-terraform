resource "aws_alb" "staging" {
  name            = "musicbox-load-balancer-staging"
  subnets         = aws_subnet.public-staging.*.id
  security_groups = [aws_security_group.lb-staging.id]
}

resource "aws_alb_target_group" "staging" {
  name        = "musicbox-target-group-staging"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.staging.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front-end-staging" {
  load_balancer_arn = aws_alb.staging.id
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.staging.id
    type             = "forward"
  }
}
