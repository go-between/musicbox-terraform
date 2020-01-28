resource "aws_cloudwatch_log_group" "musicbox-log-group-staging" {
  name              = "/ecs/musicbox-app-staging"
  retention_in_days = 30

  tags = {
    Name = "musicbox-log-group-staging"
  }
}

resource "aws_cloudwatch_log_stream" "musicbox-log-stream-staging" {
  name           = "musicbox-log-stream-staging"
  log_group_name = aws_cloudwatch_log_group.musicbox-log-group-staging.name
}
