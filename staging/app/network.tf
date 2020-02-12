data "aws_availability_zones" "available" {
}

resource "aws_vpc" "staging" {
  cidr_block           = "172.17.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private-staging" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.staging.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.staging.id
}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public-staging" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.staging.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.staging.id
  map_public_ip_on_launch = true
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "gw-staging" {
  vpc_id = aws_vpc.staging.id
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet-access-staging" {
  route_table_id         = aws_vpc.staging.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw-staging.id
}

# Create a NAT gateway with an Elastic IP for each private subnet to get internet connectivity
resource "aws_eip" "gw-staging" {
  count      = var.az_count
  vpc        = true
  depends_on = [aws_internet_gateway.gw-staging]
}

resource "aws_instance" "nat-gateway-staging" {
  count = var.az_count

  ami               = var.nat_vpc_ami
  instance_type     = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  subnet_id         = element(aws_subnet.public-staging.*.id, count.index)
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private-staging" {
  count  = var.az_count
  vpc_id = aws_vpc.staging.id

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = element(aws_instance.nat-gateway-staging.*.id, count.index)
  }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private-staging" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private-staging.*.id, count.index)
  route_table_id = element(aws_route_table.private-staging.*.id, count.index)
}

# VPC Endpoints for fetching images from ECR
resource "aws_vpc_endpoint" "ecr-api" {
  vpc_id             = aws_vpc.staging.id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.ecs-ecr-staging.id]
  subnet_ids         = aws_subnet.private-staging.*.id
}

resource "aws_vpc_endpoint" "ecr-dkr" {
  vpc_id              = aws_vpc.staging.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ecs-ecr-staging.id]
  subnet_ids          = aws_subnet.private-staging.*.id
  private_dns_enabled = true
}

# VPC Endpoint for storing ECR layers in S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.staging.id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = aws_route_table.private-staging.*.id
}

# VPC Endpoint for contacting ECS
resource "aws_vpc_endpoint" "ecs-agent" {
  vpc_id             = aws_vpc.staging.id
  service_name       = "com.amazonaws.${var.aws_region}.ecs-agent"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private-staging.*.id
  security_group_ids = [aws_security_group.ecs-ecr-staging.id]
}
resource "aws_vpc_endpoint" "ecs-telemetry" {
  vpc_id             = aws_vpc.staging.id
  service_name       = "com.amazonaws.${var.aws_region}.ecs-telemetry"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private-staging.*.id
  security_group_ids = [aws_security_group.ecs-ecr-staging.id]
}
resource "aws_vpc_endpoint" "ecs" {
  vpc_id             = aws_vpc.staging.id
  service_name       = "com.amazonaws.${var.aws_region}.ecs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private-staging.*.id
  security_group_ids = [aws_security_group.ecs-ecr-staging.id]
}

# VPC Endpoint for cloudwatch monitoring
resource "aws_vpc_endpoint" "monitoring" {
  vpc_id             = aws_vpc.staging.id
  service_name       = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.ecs-tasks-staging.id, aws_security_group.ecs-ecr-staging.id]
  subnet_ids         = aws_subnet.private-staging.*.id
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.staging.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ecs-tasks-staging.id, aws_security_group.ecs-ecr-staging.id]
  subnet_ids          = aws_subnet.private-staging.*.id
  private_dns_enabled = true
}
