resource "aws_cloudwatch_log_group" "musicbox_log_group_staging" {
  name              = "/ecs/musicbox-app-staging"
  retention_in_days = 30

  tags = {
    Name = "musicbox-log-group-staging"
  }
}

resource "aws_cloudwatch_log_stream" "musicbox_log_stream_staging" {
  name           = "musicbox-log-stream-staging"
  log_group_name = aws_cloudwatch_log_group.musicbox_log_group_staging.name
}
