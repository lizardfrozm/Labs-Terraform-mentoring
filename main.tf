terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket                  = "lz-terraform-state-08"
    key                     = "terraform.tfstate"
    region                  = "us-east-1"
    shared_credentials_file = ".aws/credentials"
  }
}


locals {
  env = (terraform.workspace == "default" ? 0 : 1)
}


provider "aws" {
  region     = var.region_name[local.env]
  shared_credentials_files = [".aws/credentials"]
  default_tags {
    tags = {
      Project = "Labs Terraform mentoring"
      ManagedBy = "Terraform"
      Owner     = "Volodymyr Boiko"
    }
  }
}

module "net" {
  source = "./modules/net"
  az     = var.region_name[local.env]
}

module "sg_rds" {
  source = "./modules/sg"
  name   = "allow_rds"
  vpc    = module.net.aws-vpc
  ingr = [{
    desc     = "RDS from VPC"
    from     = 3306
    to       = 3306
    protocol = "tcp"
    cidr     = [module.net.cidr_block]
    sg       = []
    self     = false
    }
  ]

  egr = [{
    from     = 0
    to       = 0
    protocol = "-1"
    cidr     = ["0.0.0.0/0"]
    sg       = []
    self     = false
  }]
}

module "sg_elb" {
  source = "./modules/sg"
  name   = "allow_elb"
  vpc    = module.net.aws-vpc
  ingr = [
    {
      desc     = "HTTP from VPC"
      from     = 80
      to       = 80
      protocol = "tcp"
      cidr     = [module.net.cidr_block]
      sg       = []
      self     = false
    },
    {
      desc     = "HTTP from Internet"
      from     = 80
      to       = 80
      protocol = "tcp"
      cidr     = ["0.0.0.0/0"]
      sg       = []
      self     = false
    }
  ]

  egr = [{
    from     = 0
    to       = 0
    protocol = "-1"
    cidr     = ["0.0.0.0/0"]
    sg       = []
    self     = false
  }]
}

module "sg_asg" {
  source = "./modules/sg"
  name   = "allow_asg"
  vpc    = module.net.aws-vpc
  ingr = [{
    desc     = "HTTP from ELB"
    from     = 80
    to       = 80
    protocol = "tcp"
    cidr     = []
    sg       = [module.sg_elb.id]
    self     = false
  }]

  egr = [{
    from     = 0
    to       = 0
    protocol = "-1"
    cidr     = ["0.0.0.0/0"]
    sg       = []
    self     = false
  }]
}


#Creating DB instance and sub resources

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "${terraform.workspace}-subnetgroup"
  subnet_ids = [module.net.aws-subnet-01, module.net.aws-subnet-02, module.net.aws-subnet-03]
}

resource "aws_db_parameter_group" "default" {
  name   = "${terraform.workspace}-pg"
  family = "mysql5.7"
  parameter {
    name  = "character_set_server"
    value = "utf8"
  }
  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}

#Creating rds

resource "aws_db_instance" "awsdb" {
  identifier             = "${terraform.workspace}-instance"
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = var.instcl[local.env]
  db_name                = "${terraform.workspace}db"
  username               = "foo"
  password               = "foobarbaz"
  parameter_group_name   = aws_db_parameter_group.default.name
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.dbsubnetgroup.name
  vpc_security_group_ids = [module.sg_rds.id]
}


#Find image
data "aws_ami" "amios" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS 7*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


#Creating launch_configuration for ASG
resource "aws_launch_configuration" "ec2_template" {
  image_id      = data.aws_ami.amios.id
  instance_type = var.instacg[local.env]
  user_data     = <<-EOF
#!/bin/bash
yum -y update
yum -y install httpd
echo "Website is Working" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
systemctl stop firewalld
EOF

  security_groups = [module.sg_asg.id]

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "my_ASG" {
  max_size                  = 5
  min_size                  = 2
  launch_configuration      = aws_launch_configuration.ec2_template.name
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  vpc_zone_identifier       = [module.net.aws-subnet-01, module.net.aws-subnet-02, module.net.aws-subnet-03]


  lifecycle {
    create_before_destroy = true
  }
}

#Creating Elb 
resource "aws_elb" "elb" {
  name = "${terraform.workspace}-elb"

  subnets         = [module.net.aws-subnet-01, module.net.aws-subnet-02, module.net.aws-subnet-03]
  security_groups = [module.sg_elb.id]
  internal        = false

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.my_ASG.id
  elb                    = aws_elb.elb.id
}


