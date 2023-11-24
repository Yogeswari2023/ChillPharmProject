data "aws_ami" "ubuntu" {
	most_recent = true
	
	filter{
		name = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
	}
	filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_instance" "whoami" {
  ami           				= data.aws_ami.ubuntu.id  # Ubuntu AMI
  instance_type 				= "t2.micro"
  associate_public_ip_address 	= true
  key_name      				= "my_aws_key"
  subnet_id						= "${element(module.vpc.public_subnets, 0)}"
  vpc_security_group_ids = [
    aws_security_group.whoami-sg.id
  ]
  
  root_block_device {
    delete_on_termination = true
    volume_type = "gp2"
  }
  tags = {
    Name = "whoami-instance"
  }
}

resource "aws_security_group" "whoami-sg" {
 vpc_id = module.vpc.vpc_id

  // To Allow SSH Transport
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}