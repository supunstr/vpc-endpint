
provider "aws" {
 # region = var.region
profile = "default"
}

data "aws_vpc" "selected" {
  id = "vpc-0592bb9992487344f"
}

data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_subnet" "example" {
  for_each = toset(data.aws_subnets.example.ids)
  id       = each.value
}


resource "aws_vpc_endpoint" "api" {
  vpc_id            = data.aws_vpc.selected.id
 # vpc_id = vpc-0592bb9992487344f
  service_name      = "com.amazonaws.us-east-1.execute-api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.app-endpoint.id,
  ]

subnet_ids = [for subnet in values(data.aws_subnet.example) : subnet.id]

  private_dns_enabled = true
}

# creating security group for endpoint and open port 443
resource "aws_security_group" "app-endpoint" {
  name        = "APP-Endpoint"
  description = "Allow ssh and http ports inbound and everything outbound"
  #vpc_id      = "vpc-0592bb9992487344f"
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name : "endpoint"
    Environment = "app"
    Terraform   = "true"
  }
}

