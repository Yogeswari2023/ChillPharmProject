resource "aws_ecs_cluster" "main" {
  name = "whoami-cluster"
}

resource "aws_iam_policy" "task_execution_role_policy" {
  name        = "whoami-task-exec-role-policy"
  path        = "/"
  description = "Allow retrieving of images and adding to logs"
  policy      = file("./Policies/AmazonECSTaskExecutionRolePolicy.json")
}

resource "aws_iam_role" "task_execution_role" {
  name               = "whoami-task-exec-role"
  assume_role_policy = file("./Policies/ecs-tasks-trust-policy.json")
}

resource "aws_iam_role_policy_attachment" "task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_role_policy.arn
}

resource "aws_iam_role" "app_iam_role" {
  name               = "whoami-api-task"
  assume_role_policy = file("./Policies/ecs-tasks-trust-policy.json")
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name = "whoami-api"
}
data "template_file" "api_container_definitions" {
  template = file("./Policies/container-definitions.json")

  vars = {
    app_image                = var.ecr_image_api
    proxy_image              = var.ecr_image_proxy
    django_secret_key        = var.django_secret_key
    db_host                  = aws_db_instance.main.address
    db_name                  = aws_db_instance.main.identifier
    db_user                  = aws_db_instance.main.username
    db_pass                  = aws_db_instance.main.password
    log_group_name           = aws_cloudwatch_log_group.ecs_task_logs.name
	log_group_region         = data.aws_region.current.name
    allowed_hosts            = aws_route53_record.app.fqdn
    s3_storage_bucket_name   = aws_s3_bucket.whoami_public_files.bucket
	s3_storage_bucket_region = data.aws_region.current.name
  }
}
resource "aws_ecs_task_definition" "api" {
  family                   = "whoami-api"
  container_definitions    = data.template_file.api_container_definitions.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.app_iam_role.arn

  volume {
    name = "static"
  }
}

resource "aws_security_group" "ecs_service" {
  description = "Access for the ECS Service"
  name        = "whoami-ecs-service"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
	cidr_blocks = [ "10.0.1.0/24", "10.0.2.0/24" ]
  }

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    security_groups = [
      aws_security_group.lb.id
    ]
  }
}

resource "aws_ecs_service" "api" {
  name             = "whoami-api"
  cluster          = aws_ecs_cluster.main.name
  task_definition  = aws_ecs_task_definition.api.family
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
  subnets = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]
    security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "proxy"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.api_https]
}

data "template_file" "ecs_s3_write_policy" {
  template = file("./Policies/s3-bucket-policy.json")

  vars = {
    bucket_arn = aws_s3_bucket.whoami_public_files.arn
  }
}

resource "aws_iam_policy" "ecs_s3_access" {
  name        = "whoami-AppS3AccessPolicy"
  path        = "/"
  description = "Allow access to the recipe app S3 bucket"

  policy = data.template_file.ecs_s3_write_policy.rendered
}

resource "aws_iam_role_policy_attachment" "ecs_s3_access" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = aws_iam_policy.ecs_s3_access.arn
}