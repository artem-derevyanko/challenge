data "aws_availability_zones" "available_zones" {
  state = "available"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

############## VPC #############
resource "aws_vpc" "default" {
  cidr_block           = "10.32.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public" {
  count                   = 2
  cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, 2 + count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id                  = aws_vpc.default.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.default.id
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_eip" "gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

############## VPC #############

resource "aws_security_group" "lb" {
  name   = "app-lb-security-group"
  vpc_id = aws_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds-app" {
  vpc_id      = aws_vpc.default.id
  name        = "rds-app"
  description = "Allow inbound PostgreSQL traffic"
}

resource "aws_security_group_rule" "allow-postgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds-app.id
  source_security_group_id = aws_security_group.rds-app.id
}

resource "aws_security_group_rule" "allow-hasura-postgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds-app.id
  source_security_group_id = aws_security_group.hasura_task.id
}


resource "aws_security_group_rule" "allow-outgoing" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds-app.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_db_subnet_group" "rds-app" {
  name        = "rds-app"
  description = "RDS subnet group"
  subnet_ids  = aws_subnet.private.*.id
}

############## SECURITY GROUPS  #############


############## LOAD BALANCER  #############

resource "aws_lb" "default" {
  name            = "app-lb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "app" {
  name        = "app-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_target_group" "hasura" {
  name        = "hasura-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"
  health_check {
    matcher = "200,302"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.default.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "hasura" {
  load_balancer_arn = aws_lb.default.id
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.hasura.id
    type             = "forward"
  }
}

############## LOAD BALANCER #############


############## RDS #############
resource "aws_db_parameter_group" "app" {
  name   = "app"
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "app" {
  identifier        = "appdb"
  instance_class    = var.db_instance
  allocated_storage = 5
  engine            = "postgres"
  engine_version    = var.db_version
  name              = var.db_name
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.rds-app.name
  vpc_security_group_ids = ["${aws_security_group.rds-app.id}"]
  parameter_group_name   = aws_db_parameter_group.app.name
  publicly_accessible    = false
  skip_final_snapshot    = true
}
############## RDS #############


############## ECS #############
resource "aws_ecr_repository" "app" {
  name                 = "app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "image": "${aws_ecr_repository.app.repository_url}",
    "name": "app",
    "cpu": 1024,
    "memory": 2048,
    "name": "app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.app_port},
        "hostPort": ${var.app_port}
      }
    ]
  }
]
DEFINITION
}

resource "aws_security_group" "app_task" {
  name   = "app-security-group"
  vpc_id = aws_vpc.default.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "app" {
  name = "app-cluster"
}

resource "aws_ecs_service" "app" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.app_task.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.id
    container_name   = "app"
    container_port   = var.app_port
  }

  depends_on = [aws_lb_listener.app]
}

## HASURA
# TODO: hide console and add authorization for Hasura requests

resource "aws_ecs_task_definition" "hasura" {
  family                   = "hasura-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  depends_on = [aws_db_instance.app]


  container_definitions = <<DEFINITION
[
  {
    "image": "hasura/graphql-engine:v2.0.10",
    "cpu": 1024,
    "memory": 2048,
    "name": "hasura-app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.hasura_port},
        "hostPort": ${var.hasura_port}
      }
    ],
    "command": ["graphql-engine", "serve", "--enable-console"],
    "environment": [
      {
          "name": "HASURA_GRAPHQL_DATABASE_URL",
          "value": "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.app.endpoint}/${var.db_name}"
      },
      {
          "name": "HASURA_GRAPHQL_ENABLE_CONSOLE",
          "value": "false"
      },
      {
          "name": "HASURA_GRAPHQL_ACTIONS_HANDLER_WEBHOOK_BASEURL",
          "value": "http://${aws_lb.default.dns_name}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_security_group" "hasura_task" {
  name   = "hasura_task-security-group"
  vpc_id = aws_vpc.default.id

  ingress {
    protocol        = "tcp"
    from_port       = var.hasura_port
    to_port         = var.hasura_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "hasura" {
  name = "hasura-cluster"
}

resource "aws_ecs_service" "hasura" {
  name            = "hasura-service"
  cluster         = aws_ecs_cluster.hasura.id
  task_definition = aws_ecs_task_definition.hasura.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.hasura_task.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.hasura.id
    container_name   = "hasura-app"
    container_port   = var.hasura_port
  }

  depends_on = [aws_lb_listener.hasura]
}
############## ECS #############
