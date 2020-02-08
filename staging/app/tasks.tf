resource "aws_ecs_cluster" "tasks-staging" {
  name = "musicbox-tasks-cluster-staging"
}

data "template_file" "musicbox-app-room-poll" {
  template = file("./templates/ecs/app.json.tpl")

  vars = {
    app_image       = var.app_image
    app_port        = var.app_port
    fargate_cpu     = var.fargate_cpu
    fargate_memory  = var.fargate_memory
    aws_region      = var.aws_region
    command         = jsonencode(["bin/rake", "room:poll_queue"])
    allowed_hosts   = ""
    database_url    = "postgresql://root:${var.db_root_password_staging}@${aws_db_instance.musicbox-staging.address}"
    secret_key_base = var.secret_key_base_staging
    redis_url       = "redis://${aws_elasticache_cluster.musicbox-staging.cache_nodes.0.address}:6379"
  }

  depends_on = [aws_db_instance.musicbox-staging]
}

resource "aws_ecs_task_definition" "room-poll-staging" {
  family                   = "musicbox-app-task-room-poll-staging"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.musicbox-app-room-poll.rendered
}

resource "aws_ecs_service" "room-poll-staging" {
  name            = "musicbox-room-poll-service-staging"
  cluster         = aws_ecs_cluster.tasks-staging.id
  task_definition = aws_ecs_task_definition.room-poll-staging.arn
  desired_count   = var.worker_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs-tasks-staging.id]
    subnets          = aws_subnet.private-staging.*.id
    assign_public_ip = true
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role]
}

resource "aws_appautoscaling_target" "room-poll-staging" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.tasks-staging.name}/${aws_ecs_service.room-poll-staging.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.ecs_auto_scale_role.arn
  min_capacity       = 1
  max_capacity       = 1

  depends_on = [aws_ecs_service.room-poll-staging]
}
