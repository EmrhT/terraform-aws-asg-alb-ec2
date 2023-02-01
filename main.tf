terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.52.0"
    }
  }

  backend "s3" {
    bucket   = "emrah-aws-terraform-state-bucket"
    key      = "asg-alb-ec22/terraform.tfstate"
    region   = "eu-central-1"
  }
}

provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "random_pet" "this" {
  length = 2
}

# Define the security group for the EC2 Instance
resource "aws_security_group" "aws-ec2-sg" {
  name        = "ec2-sg"
  description = "Allow incoming connections"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTP connections"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections"
  }  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  tags = {
    Name = "ec2-sg"
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name        = "alb-sg-${random_pet.this.id}"
  description = "Security group for example usage with ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.2.2"

  name = "complete-alb-for-test"

  load_balancer_type = "application"

  vpc_id          = data.aws_vpc.default.id
  security_groups = [module.security_group.security_group_id]
  subnets         = data.aws_subnets.all.ids

  http_tcp_listeners = [
    # Forward action is default, either when defined or undefined
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      # action_type        = "forward"
    },
  ]

  http_tcp_listener_rules = [
    {
      http_tcp_listener_index = 0
      priority                = 3
      actions = [{
        type         = "fixed-response"
        content_type = "text/plain"
        status_code  = 200
        message_body = "This is a fixed response"
      }]

      conditions = [{
        http_headers = [{
          http_header_name = "x-Gimme-Fixed-Response"
          values           = ["yes", "please", "right now"]
        }]
      }]
    },
  ]

  target_groups = [
    {
      name_prefix          = "h1"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
      protocol_version = "HTTP1"
      tags = {
        InstanceTargetGroupTag = "baz"
      }
    },
  ]

}


resource "aws_launch_configuration" "as_conf" {
  name_prefix   = "terraform-lc-example-"
  image_id      = var.ami
  instance_type = var.instance_type

  security_groups = [aws_security_group.aws-ec2-sg.id]

  user_data = file("aws-user-data.sh")

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "asg-test" {
  name                 = "terraform-asg-example"
  launch_configuration = aws_launch_configuration.as_conf.name
  vpc_zone_identifier  = data.aws_subnets.all.ids
  min_size             = 2
  max_size             = 5

  depends_on = [module.alb]

  target_group_arns    =  module.alb.target_group_arns

  tag {
    key                   = "Name"
    value                 = "TF-ALB-ASG-EC2-${random_pet.this.id}"
    propagate_at_launch   = true
  }

  lifecycle {
    create_before_destroy = true
  }
  
}

resource "aws_autoscaling_policy" "example-autoscaling-policy" {
  autoscaling_group_name = aws_autoscaling_group.asg-test.name
  name                   = "example-autoscaling-policy"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
    disable_scale_in  = false
  }
}
