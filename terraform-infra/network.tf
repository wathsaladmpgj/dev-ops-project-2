provider "aws" {
  region = var.region
}

data "aws_availability_zones" "az" {}

# Ubuntu 22.04 LTS (Canonical)
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC only if not using existing
resource "aws_vpc" "main" {
  count                = var.use_existing_vpc ? 0 : 1
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  count = var.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.main[0].id
  tags   = { Name = "${var.project_name}-igw" }
}

# Public subnets (2 AZ) - only when creating network
resource "aws_subnet" "public" {
  count                   = var.use_existing_vpc ? 0 : 2
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Tier = "public"
  }
}

# Public route table - only when creating network
resource "aws_route_table" "public" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  count          = var.use_existing_vpc ? 0 : 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Locals: choose VPC/Subnets depending on mode
locals {
  vpc_id = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.main[0].id

  public_subnet_ids = var.use_existing_vpc ? var.existing_public_subnet_ids : [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]
}
