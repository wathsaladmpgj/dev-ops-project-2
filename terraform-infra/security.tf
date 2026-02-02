# Bastion SG
resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
  description = "Bastion host SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-bastion-sg" }
}

# K8s nodes SG
resource "aws_security_group" "k8s_sg" {
  name        = "${var.project_name}-k8s-sg"
  description = "Kubernetes nodes SG"
  vpc_id      = aws_vpc.main.id

  # SSH only from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Kubernetes API: allow from Bastion (kubectl via ssh tunnel / direct)
  ingress {
    description     = "K8s API from Bastion"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Node-to-node full traffic inside this SG (important for cluster networking)
  ingress {
    description = "All node-to-node traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Optional: NodePort testing from your IP (if you want to access services)
  ingress {
    description = "NodePort range from your IP (optional)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-k8s-sg" }
}

# Tools SG (Nexus, SonarQube, Monitoring)
resource "aws_security_group" "tools_sg" {
  name        = "${var.project_name}-tools-sg"
  description = "Tools servers SG"
  vpc_id      = aws_vpc.main.id

  # SSH only from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Nexus UI (access from Bastion + (optional) from K8s nodes)
  ingress {
    description     = "Nexus UI from Bastion"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description     = "Nexus UI from K8s nodes"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_sg.id]
  }

  # SonarQube UI (mostly for Jenkins/Bastion; here we allow Bastion)
  ingress {
    description     = "SonarQube UI from Bastion"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Prometheus + Grafana UIs from Bastion
  ingress {
    description     = "Prometheus from Bastion"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description     = "Grafana from Bastion"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Allow scraping access from K8s nodes to monitoring (optional)
  ingress {
    description     = "Allow from K8s nodes (optional)"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.k8s_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-tools-sg" }
}
