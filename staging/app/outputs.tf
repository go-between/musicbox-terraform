output "alb_hostname" {
  value = aws_alb.staging.dns_name
}

output "aws_security_group-ecs-tasks-staging" {
  value = aws_security_group.ecs-tasks-staging.id
}

output "aws_security_group-ecs-ecr-staging" {
  value = aws_security_group.ecs-ecr-staging.id
}

output "aws_subnet_private-staging_ids" {
  value = aws_subnet.private-staging.*.id
}

output "aws_db_instance-staging-address" {
  value = aws_db_instance.musicbox-staging.address
}
