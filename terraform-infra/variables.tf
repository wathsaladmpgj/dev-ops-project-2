variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "devops-lab"
}

variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.1.0/24", "10.50.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.11.0/24", "10.50.12.0/24"]
}

variable "admin_cidr" {
  description = "Your public IP in CIDR format. Example: 1.2.3.4/32"
  type        = string
}

variable "key_name" {
  description = "Existing AWS EC2 Key Pair name"
  type        = string
}

variable "instance_type_tools" {
  type    = string
  default = "t3.micro"
}

variable "instance_type_k8s" {
  type    = string
  default = "t3.small"
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "root_volume_gb" {
  type    = number
  default = 30
}

variable "create_bastion" {
  type    = bool
  default = true
}
