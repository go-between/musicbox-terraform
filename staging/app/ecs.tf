resource "aws_ecs_cluster" "staging" {
  name = "musicbox-cluster-staging"
}

data "template_file" "musicbox-app" {
  template = file("./templates/ecs/app.json.tpl")

  vars = {
    app_image                = var.app_image
    app_port                 = var.app_port
    fargate_cpu              = var.fargate_cpu
    fargate_memory           = "1024"
    aws_region               = var.aws_region
    command                  = jsonencode(["passenger", "start", "-p", "80", "--nginx-config-template", "nginx.conf.erb"])
    allowed_hosts            = "^172\\\\.17\\\\.\\\\d{1,3}\\\\.\\\\d{1,3}$&^${aws_alb.staging.dns_name}$&^api-staging.musicbox.fm$&^https://musicbox.fm$"
    database_url             = "postgresql://root:${var.db_root_password_staging}@${aws_db_instance.musicbox-staging.address}"
    log_level                = "error"
    mailgun_key              = var.mailgun_key
    secret_key_base          = var.secret_key_base_staging
    redis_url                = "redis://${aws_elasticache_cluster.musicbox-staging.cache_nodes.0.address}:6379"
    sidekiq_redis_url        = "redis://${aws_elasticache_cluster.musicbox-sidekiq-staging.cache_nodes.0.address}:6379"
    skylight_auth            = var.skylight_auth
    skylight_enabled         = false
    skylight_sidekiq_enabled = false
    airbrake_id              = var.airbrake_id
    airbrake_secret          = var.airbrake_secret
  }

  depends_on = [aws_db_instance.musicbox-staging, aws_elasticache_cluster.musicbox-staging]
}

resource "aws_ecs_task_definition" "staging" {
  family                   = "musicbox-app-task-staging"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = "1024"
  container_definitions    = data.template_file.musicbox-app.rendered
}

resource "aws_ecs_service" "staging" {
  name            = "musicbox-service-staging"
  cluster         = aws_ecs_cluster.staging.id
  task_definition = aws_ecs_task_definition.staging.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs-tasks-staging.id, aws_security_group.ecs-ecr-staging.id]
    subnets          = aws_subnet.private-staging.*.id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.staging.id
    container_name   = "musicbox-app-staging"
    container_port   = var.app_port
  }

  depends_on = [aws_alb_listener.front-end-staging, aws_iam_role_policy_attachment.ecs_task_execution_role]
}
