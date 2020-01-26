resource "aws_db_instance" "musicbox-staging" {
  depends_on             = [aws_security_group.ecs_tasks]
  identifier             = "musicbox-staging"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "11.5"
  instance_class         = "db.t2.micro"
  name                   = "musicbox"
  username               = "read_write"
  password               = "PleaseReplaceMePlease!"
  vpc_security_group_ids = [aws_security_group.ecs_tasks.id]
}
