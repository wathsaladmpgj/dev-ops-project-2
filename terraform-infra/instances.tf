locals {
  # Place instances across private subnets (AZ-A and AZ-B)
  private_subnet_ids = [aws_subnet.private[0].id, aws_subnet.private[1].id]

  servers = {
    k8s-master = {
      type      = var.instance_type_k8s
      subnet_id = local.private_subnet_ids[0]
      sg_id     = aws_security_group.k8s_sg.id
      role      = "k8s-master"
    }
    k8s-worker-1 = {
      type      = var.instance_type_k8s
      subnet_id = local.private_subnet_ids[0]
      sg_id     = aws_security_group.k8s_sg.id
      role      = "k8s-worker"
    }
    k8s-worker-2 = {
      type      = var.instance_type_k8s
      subnet_id = local.private_subnet_ids[1]
      sg_id     = aws_security_group.k8s_sg.id
      role      = "k8s-worker"
    }
    nexus = {
      type      = var.instance_type_tools
      subnet_id = local.private_subnet_ids[1]
      sg_id     = aws_security_group.tools_sg.id
      role      = "nexus"
    }
    sonarqube = {
      type      = var.instance_type_tools
      subnet_id = local.private_subnet_ids[0]
      sg_id     = aws_security_group.tools_sg.id
      role      = "sonarqube"
    }
    monitoring = {
      type      = var.instance_type_tools
      subnet_id = local.private_subnet_ids[1]
      sg_id     = aws_security_group.tools_sg.id
      role      = "monitoring"
    }
  }
}

# Bastion (optional)
resource "aws_instance" "bastion" {
  count                       = var.create_bastion ? 1 : 0
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.project_name}-bastion"
    Project = var.project_name
    Role    = "bastion"
  }
}

# 6 private instances
resource "aws_instance" "servers" {
  for_each = local.servers

  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = each.value.type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [each.value.sg_id]
  key_name               = var.key_name

  associate_public_ip_address = false

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
