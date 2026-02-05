# 🚀 End-to-End DevOps CI/CD Learning Project

> ⚠️ **Important Note**
> This is a **learning-focused DevOps project**, inspired by real-world practices. It is **NOT a production-ready system**. The main goal is to gain **hands-on experience** with modern DevOps tools, CI/CD workflows, cloud infrastructure, containerization, and Kubernetes.

---

## 📌 Project Overview

This project demonstrates a **complete DevOps CI/CD workflow** starting from source code checkout and ending with application deployment on a Kubernetes cluster. The entire process is orchestrated using **Jenkins pipelines**, with strong emphasis on automation, modular design, and flexibility.

The pipeline is highly configurable using parameters, allowing stages such as Terraform, Ansible, Docker build, Docker push, and Kubernetes deployment to be skipped or forced as needed. This makes the project ideal for **learning, experimentation, and interviews**.

---

## 🎯 Project Objectives

* Understand **end-to-end CI/CD pipeline design**
* Learn **Infrastructure as Code (IaC)** using Terraform
* Practice **configuration management** with Ansible
* Implement **code quality checks** using SonarQube
* Use **Nexus** for caching npm dependencies
* Build and push Docker images to **Docker Hub**
* Deploy applications to **Kubernetes using Helm**
* Gain real-world DevOps troubleshooting experience

---

## 🧱 Architecture Overview

High-level workflow:

1. Developer pushes code to GitHub
2. Jenkins pipeline is triggered
3. Infrastructure is provisioned using Terraform
4. Servers are configured using Ansible
5. Code quality is analyzed using SonarQube
6. Application is containerized using Docker
7. Docker image is pushed to Docker Hub
8. Application is deployed to Kubernetes using Helm
9. Ingress is configured using NGINX Ingress Controller

---

## 🛠️ Tools & Technologies Used

### CI/CD & SCM

* Jenkins
* GitHub

### Infrastructure & Configuration

* Terraform
* Ansible
* AWS EC2, VPC, IAM

### Code Quality & Artifact Management

* SonarQube
* Nexus Repository Manager (npm cache)

### Containerization & Orchestration

* Docker
* Docker Hub
* Kubernetes (kubeadm-based cluster)
* Helm
* NGINX Ingress Controller

### Monitoring

* Prometheus
* Node Exporter

---

## 📂 Project Structure

```text
.
├── terraform-infra/        # Terraform code (VPC, EC2, outputs)
├── ansible/               # Ansible playbooks & inventories
│   ├── playbooks/
│   ├── inventories/
│   └── roles/
├── app/                   # Next.js application source code
│   ├── Dockerfile
│   └── package.json
├── helm/                  # Helm charts for Kubernetes deployment
│   └── nextjs-app/
├── Jenkinsfile             # Jenkins CI/CD pipeline
└── README.md
```

---

## 🔄 Jenkins Pipeline Stages

The Jenkins pipeline is fully parameterized and includes the following stages:

1. Checkout Source
2. Terraform Init
3. Terraform Validate
4. Terraform Plan
5. Terraform Apply / Destroy
6. Read Outputs (SonarQube, Nexus, K8s Master IP)
7. Decide Ansible Execution
8. Generate Ansible Inventory
9. Ansible Bootstrap & Tool Installation
10. Node Exporter Installation
11. Prometheus Target Update
12. SonarQube Code Scan (Next.js)
13. Docker Image Build
14. Docker Image Push (Docker Hub)
15. Fetch Kubernetes kubeconfig
16. Helm Deployment
17. NGINX Ingress Installation

Each stage can be skipped using pipeline parameters for maximum flexibility.

---

## ⚙️ Pipeline Parameters

| Parameter         | Description                            |
| ----------------- | -------------------------------------- |
| ACTION            | plan / apply / destroy                 |
| SKIP_TERRAFORM    | Skip Terraform execution               |
| SKIP_ANSIBLE      | Skip Ansible configuration             |
| FORCE_ANSIBLE     | Force Ansible even if already executed |
| RUN_SONAR         | Enable SonarQube scan                  |
| SKIP_DOCKER_BUILD | Skip Docker build                      |
| SKIP_DOCKER_PUSH  | Skip Docker push                       |
| SKIP_DEPLOY       | Skip Kubernetes deployment             |

---

## 📦 Dependency Caching with Nexus

Nexus is used as an **npm proxy and group repository** to cache Node.js dependencies. This provides:

* Faster builds
* Reduced dependency on external npm registry
* Improved reliability

The Jenkins pipeline dynamically configures npm to use the Nexus registry before running `npm ci`.

---

## 🐳 Docker Image Strategy

* Multi-stage Docker build for optimized image size
* Tags used:

  * `latest`
  * Jenkins `BUILD_NUMBER`
* Images are pushed to **Docker Hub**

---

## ☸️ Kubernetes Deployment

* Kubernetes cluster created using kubeadm (via Ansible)
* Helm used for application deployment
* Namespace-based isolation
* Ingress routing via NGINX Ingress Controller

Helm allows easy upgrades, rollbacks, and parameterized deployments.

---

## 📈 Monitoring Setup

* Node Exporter installed on all EC2 instances
* Prometheus target configuration automated using Ansible
* Ready for Grafana integration

---

## 🔐 Security Practices (Learning Level)

* Jenkins credentials store for secrets
* SSH key-based authentication
* IAM role usage for Terraform (recommended)
* No hardcoded secrets in code

> ⚠️ Security is implemented for learning purposes and should be hardened for production.

---

## 🧪 Learning Outcomes

Through this project, I gained hands-on experience in:

* Designing real-world inspired CI/CD pipelines
* Automating infrastructure and configuration
* Debugging Jenkins, Terraform, Ansible, and Kubernetes issues
* Understanding DevOps tool integration end-to-end

---

## 🚧 Limitations

* Not production hardened
* No HA setup for Kubernetes or Jenkins
* TLS and security are simplified
* Manual approval steps exist

---

## 🔮 Future Improvements

* Add multi-environment support (dev/stage/prod)
* Enforce SonarQube Quality Gates
* Use Nexus as Docker registry
* Add Grafana dashboards
* Implement GitOps (ArgoCD)

---

## 📜 Conclusion

This project is a **comprehensive DevOps learning journey**, covering infrastructure provisioning, CI/CD automation, containerization, and Kubernetes deployment. It reflects real-world DevOps workflows while remaining safe and flexible for experimentation.

---

⭐ If you are learning DevOps, this project structure is an excellent starting point for hands-on practice.
