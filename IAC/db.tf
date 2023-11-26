resource "aws_db_subnet_group" "main" {
  name = "whoami-main"
  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]

}

resource "aws_security_group" "rds" {
  description = "Allow access to the RDS database instance"
  name        = "whoami-rds-inbound-access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol  = "tcp"
    from_port = 5432
    to_port   = 5432

    security_groups = [
      aws_security_group.whoami-sg.id
    ]
  }

}

resource "aws_db_instance" "main" {
  identifier              = "whoami"
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "11.16"
  instance_class          = "db.t2.micro"
  db_subnet_group_name    = aws_db_subnet_group.main.name
  password                = "<dbpass>"
  username                = "<dbuser>"
  backup_retention_period = 0
  multi_az                = false
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds.id]
}
