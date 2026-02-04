terraform {
  backend "s3" {
    bucket         = "devops-lab-terraform-state-123456"   # must be UNIQUE
    key            = "devops-lab/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
