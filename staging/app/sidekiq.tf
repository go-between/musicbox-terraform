resource "aws_ecs_cluster" "sidekiq-staging" {
  name = "musicbox-sidekiq-cluster-staging"
}

data "template_file" "musicbox-sidekiq" {
  template = file("./templates/ecs/app.json.tpl")

  vars = {
    app_image       = var.app_image
    app_port        = var.app_port
    fargate_cpu     = var.fargate_cpu
    fargate_memory  = var.fargate_memory
    aws_region      = var.aws_region
    command         = jsonencode(["bundle", "exec", "sidekiq"])
    allowed_hosts   = "^172\\\\.17\\\\.\\\\d{1,3}\\\\.\\\\d{1,3}$&^${aws_alb.staging.dns_name}$"
    database_url    = "postgresql://root:${var.db_root_password_staging}@${aws_db_instance.musicbox-staging.address}"
    secret_key_base = var.secret_key_base_staging
    redis_url       = "redis://${aws_elasticache_cluster.musicbox-staging.cache_nodes.0.address}:6379"
  }

  depends_on = [aws_db_instance.musicbox-staging, aws_elasticache_cluster.musicbox-staging]
}

resource "aws_ecs_task_definition" "sidekiq-staging" {
  family                   = "musicbox-sidekiq-task-staging"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.musicbox-sidekiq.rendered
}

resource "aws_ecs_service" "sidekiq-staging" {
  name            = "musicbox-sidekiq-service-staging"
  cluster         = aws_ecs_cluster.sidekiq-staging.id
  task_definition = aws_ecs_task_definition.sidekiq-staging.arn
  desired_count   = var.worker_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs-tasks-staging.id]
    subnets          = aws_subnet.private-staging.*.id
    assign_public_ip = true
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role]
}

resource "aws_appautoscaling_target" "sidekiq-target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.sidekiq-staging.name}/${aws_ecs_service.sidekiq-staging.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.ecs_auto_scale_role.arn
  min_capacity       = 1
  max_capacity       = 1
}
