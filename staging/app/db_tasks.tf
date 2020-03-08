data "template_file" "musicbox-app-db-create" {
  template = file("./templates/ecs/app.json.tpl")

  vars = {
    app_image                = var.app_image
    app_port                 = var.app_port
    fargate_cpu              = var.fargate_cpu
    fargate_memory           = var.fargate_memory
    aws_region               = var.aws_region
    command                  = jsonencode(["bin/rake", "db:create"])
    allowed_hosts            = "^172\\\\.17\\\\.\\\\d{1,3}\\\\.\\\\d{1,3}$&^${aws_alb.staging.dns_name}$"
    database_url             = "postgresql://root:${var.db_root_password_staging}@${aws_db_instance.musicbox-staging.address}"
    log_level                = "info"
    mailgun_key              = var.mailgun_key
    secret_key_base          = var.secret_key_base_staging
    redis_url                = "redis://${aws_elasticache_cluster.musicbox-staging.cache_nodes.0.address}:6379"
    sidekiq_redis_url        = "redis://${aws_elasticache_cluster.musicbox-sidekiq-staging.cache_nodes.0.address}:6379"
    skylight_auth            = var.skylight_auth
    skylight_enabled         = false
    skylight_sidekiq_enabled = false
  }

  depends_on = [aws_db_instance.musicbox-staging]
}

resource "aws_ecs_task_definition" "staging-db-create" {
  family                   = "musicbox-app-task-staging-db-create"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.musicbox-app-db-create.rendered
}

data "template_file" "musicbox-app-db-migrate" {
  template = file("./templates/ecs/app.json.tpl")

  vars = {
    app_image                = var.app_image
    app_port                 = var.app_port
    fargate_cpu              = var.fargate_cpu
    fargate_memory           = var.fargate_memory
    aws_region               = var.aws_region
    command                  = jsonencode(["bin/rake", "db:migrate"])
    allowed_hosts            = "^172\\\\.17\\\\.\\\\d{1,3}\\\\.\\\\d{1,3}$&^${aws_alb.staging.dns_name}$"
    database_url             = "postgresql://root:${var.db_root_password_staging}@${aws_db_instance.musicbox-staging.address}"
    log_level                = "info"
    mailgun_key              = var.mailgun_key
    secret_key_base          = var.secret_key_base_staging
    redis_url                = "redis://${aws_elasticache_cluster.musicbox-staging.cache_nodes.0.address}:6379"
    sidekiq_redis_url        = "redis://${aws_elasticache_cluster.musicbox-sidekiq-staging.cache_nodes.0.address}:6379"
    skylight_auth            = var.skylight_auth
    skylight_enabled         = false
    skylight_sidekiq_enabled = false
  }

  depends_on = [aws_db_instance.musicbox-staging]
}

resource "aws_ecs_task_definition" "staging-db-migrate" {
  family                   = "musicbox-app-task-staging-db-migrate"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.musicbox-app-db-migrate.rendered
}
