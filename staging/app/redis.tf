resource "aws_elasticache_subnet_group" "staging" {
  name       = "staging"
  subnet_ids = aws_subnet.private-staging.*.id
}

resource "aws_elasticache_cluster" "musicbox-staging" {
  depends_on           = [aws_security_group.redis-staging]
  cluster_id           = "musicbox-staging"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.3"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.staging.name
  security_group_ids   = [aws_security_group.redis-staging.id]
}
