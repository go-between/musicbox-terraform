resource "aws_db_subnet_group" "staging" {
  name       = "staging"
  subnet_ids = aws_subnet.private-staging.*.id
}

resource "aws_db_instance" "musicbox-staging" {
  depends_on             = [aws_security_group.db-staging]
  identifier             = "musicbox-staging"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "11.5"
  instance_class         = "db.t2.micro"
  name                   = "musicbox"
  username               = "read_write"
  password               = "PleaseReplaceMePlease!"
  vpc_security_group_ids = [aws_security_group.db-staging.id]
  db_subnet_group_name   = aws_db_subnet_group.staging.name
}
