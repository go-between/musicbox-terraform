data "template_file" "musicbox-app-db-create" {
  template = file("./templates/ecs/db-create.json.tpl")

  vars = {
    app_image       = var.app_image
    app_port        = var.app_port
    fargate_cpu     = var.fargate_cpu
    fargate_memory  = var.fargate_memory
    aws_region      = var.aws_region
    allowed_host    = aws_alb.staging.dns_name
    database_url    = "postgresql://root:${var.db_root_password_staging}@${aws_db_instance.musicbox-staging.address}"
    secret_key_base = var.secret_key_base_staging
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
  template = file("./templates/ecs/db-migrate.json.tpl")

  vars = {
    app_image       = var.app_image
    app_port        = var.app_port
    fargate_cpu     = var.fargate_cpu
    fargate_memory  = var.fargate_memory
    aws_region      = var.aws_region
    allowed_host    = aws_alb.staging.dns_name
    database_url    = "postgresql://root:${var.db_root_password_staging}@${aws_db_instance.musicbox-staging.address}"
    secret_key_base = var.secret_key_base_staging
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
