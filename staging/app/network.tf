data "aws_availability_zones" "available" {
}

resource "aws_vpc" "staging" {
  cidr_block = "172.17.0.0/16"
}
data "aws_vpc" "staging" {
  default = true
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

resource "aws_nat_gateway" "gw-staging" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.public-staging.*.id, count.index)
  allocation_id = element(aws_eip.gw-staging.*.id, count.index)
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private-staging" {
  count  = var.az_count
  vpc_id = aws_vpc.staging.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw-staging.*.id, count.index)
  }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private-staging" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private-staging.*.id, count.index)
  route_table_id = element(aws_route_table.private-staging.*.id, count.index)
}
