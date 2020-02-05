[
  {
    "name": "musicbox-app-staging",
    "image": "${app_image}",
    "command": ["bin/rake", "db:migrate"],
    "cpu": ${fargate_cpu},
    "memory": ${fargate_memory},
    "networkMode": "awsvpc",
    "environment": [
      { "name": "ALLOWED_HOST", "value": "${allowed_hosts}" },
      { "name": "DATABASE_URL", "value": "${database_url}" },
      { "name": "RAILS_ENV", "value": "staging" },
      { "name": "SECRET_KEY_BASE", "value": "${secret_key_base}" }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/musicbox-app-staging",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${app_port},
        "hostPort": ${app_port}
      }
    ]
  }
]
