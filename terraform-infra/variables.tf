variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "devops-lab"
}

variable "admin_cidr" {
  description = "Your public IP in CIDR format. Example: 1.2.3.4/32"
  type        = string
}

variable "key_name" {
  description = "Existing AWS EC2 Key Pair name (AWS-side name, not .pem file)"
  type        = string
}

# Instance types (lab-friendly; you can increase later)
variable "instance_type_tools" {
  type    = string
  default = "t3.micro"
}

variable "instance_type_k8s" {
  type    = string
  default = "t3.micro"
}

variable "root_volume_gb" {
  type    = number
  default = 30
}

# -----------------------------
# Network controls
# -----------------------------
# If your account hits VPC limit, set this to true and provide existing VPC + Subnet IDs
variable "use_existing_vpc" {
  description = "Use existing VPC and public subnets instead of creating new network"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "Existing VPC ID (required if use_existing_vpc=true)"
  type        = string
  default     = ""
}

variable "existing_public_subnet_ids" {
  description = "Existing public subnet IDs (2 recommended). Required if use_existing_vpc=true"
  type        = list(string)
  default     = []
}

# Only used when Terraform creates the VPC
variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.1.0/24", "10.50.2.0/24"]
}
