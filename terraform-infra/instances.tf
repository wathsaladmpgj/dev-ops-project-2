locals {
  servers = {
    k8s-master = {
      type      = var.instance_type_k8s
      subnet_id = local.public_subnet_ids[0]
      role      = "k8s-master"
    }
    k8s-worker-1 = {
      type      = var.instance_type_k8s
      subnet_id = local.public_subnet_ids[0]
      role      = "k8s-worker"
    }
    k8s-worker-2 = {
      type      = var.instance_type_k8s
      subnet_id = local.public_subnet_ids[1]
      role      = "k8s-worker"
    }
    nexus = {
      type      = var.instance_type_tools
      subnet_id = local.public_subnet_ids[1]
      role      = "nexus"
    }
    sonarqube = {
      type      = var.instance_type_tools
      subnet_id = local.public_subnet_ids[0]
      role      = "sonarqube"
    }
    monitoring = {
      type      = var.instance_type_tools
      subnet_id = local.public_subnet_ids[1]
      role      = "monitoring"
    }
  }
}


# 6 public instances (LAB MODE)
resource "aws_instance" "servers" {
  for_each = local.servers

  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = each.value.type
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = [aws_security_group.lab_sg.id]   # <- uses single lab SG
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.project_name}-${each.key}"
    Project = var.project_name
    Role    = each.value.role
  }
}
