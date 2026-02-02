region       = "ap-south-1"
project_name = "devops-lab"

# Replace with your REAL public IP
admin_cidr = "0.0.0.0/0"

# Your AWS key pair name
key_name = "my-project"

# LAB sizes (reduce if you still hit vCPU limits)
instance_type_k8s   = "t3.micro"
instance_type_tools = "t3.micro"
root_volume_gb      = 30

# If you hit VPC limit again:
use_existing_vpc = false
# existing_vpc_id = "vpc-xxxxxxxx"
# existing_public_subnet_ids = ["subnet-aaaaaaa", "subnet-bbbbbbb"]
