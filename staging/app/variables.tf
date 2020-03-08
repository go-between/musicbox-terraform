variable "db_root_password_staging" {}
variable "db_username_staging" {}
variable "mailgun_key" {}
variable "secret_key_base_staging" {}
variable "skylight_auth" {}

variable "aws_region" {
  description = "The AWS region things are created in"
  default     = "us-east-1"
}

variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  default     = "MusicboxECSTaskExecutionRole"
}

variable "ecs_auto_scale_role_name" {
  description = "ECS auto scale role Name"
  default     = "MusicboxECSAutoScaleRole"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region"
  default     = 2
}

variable "app_image" {
  description = "Docker image to run in the ECS cluster"
  default     = "593337084109.dkr.ecr.us-east-1.amazonaws.com/musicbox:latest"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 80
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 1
}

variable "nat_vpc_ami" {
  description = "amzn-ami-vpc-nat-hvm-2018.03.0.20180811-x86_64-ebs AMI"
  default     = "ami-0422d936d535c63b1"
}

variable "worker_count" {
  description = "Number of docker containers to run"
  default     = 1
}

variable "health_check_path" {
  default = "/health_check"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}
