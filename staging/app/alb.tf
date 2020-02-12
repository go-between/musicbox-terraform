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
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  # Made manually in AWS
  certificate_arn = "arn:aws:acm:us-east-1:593337084109:certificate/ae733b80-9348-4c20-a4a9-aef871ba1a37"
  default_action {
    target_group_arn = aws_alb_target_group.staging.id
    type             = "forward"
  }
}
