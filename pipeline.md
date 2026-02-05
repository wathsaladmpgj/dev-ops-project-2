pipeline {
  agent any

  tools {
    nodejs 'node25'
  }

  parameters {
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')

    booleanParam(name: 'SKIP_TERRAFORM', defaultValue: false, description: 'Skip Terraform steps (use existing infra)')
    booleanParam(name: 'SKIP_ANSIBLE', defaultValue: false, description: 'Skip Ansible steps (keep existing config)')
    booleanParam(name: 'FORCE_ANSIBLE', defaultValue: false, description: 'Force Ansible even if it ran successfully before')

    booleanParam(name: 'RUN_SONAR', defaultValue: true, description: 'Run SonarQube code scan (Next.js)')

    booleanParam(name: 'SKIP_DOCKER_BUILD', defaultValue: false, description: 'Skip Docker build stage')
    booleanParam(name: 'SKIP_DOCKER_PUSH', defaultValue: false, description: 'Skip Docker push stage (Docker Hub)')

    booleanParam(name: 'SKIP_DEPLOY', defaultValue: false, description: 'Skip Kubernetes/Helm deploy')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT = '0'

    REPO_URL = 'https://github.com/wathsaladmpgj/dev-ops-project-2.git'
    TF_DIR   = 'terraform-infra'
    ANS_DIR  = 'ansible'
    APP_DIR  = 'app'

    ANSIBLE_MARKER = "${JENKINS_HOME}/.ansible_done_${JOB_NAME}"

    DOCKER_IMAGE = "docker.io/janith9988/nextjs-app"

    HELM_CHART_DIR = "helm/nextjs-app"
    K8S_NAMESPACE  = "nextjs"
    HELM_RELEASE   = "nextjs"

    K8S_MASTER_IP = "13.201.31.174"
    IMAGE_TAG_TO_DEPLOY = "latest"
  }

  stages {

    stage('Checkout') {
      steps {
        script {
          if (!params.SKIP_TERRAFORM) {
            deleteDir()
          }
        }
        git(url: "${REPO_URL}", branch: 'main', credentialsId: 'github-creds')
        sh 'ls -la'
      }
    }

    // -------------------------
    // Terraform
    // -------------------------
    stage('Terraform Init') {
      when { expression { !params.SKIP_TERRAFORM } }
      steps { sh "cd ${TF_DIR} && terraform init" }
    }

    stage('Terraform Validate') {
      when { expression { !params.SKIP_TERRAFORM } }
      steps { sh "cd ${TF_DIR} && terraform validate" }
    }

    stage('Terraform Plan') {
      when { expression { !params.SKIP_TERRAFORM && (params.ACTION == 'plan' || params.ACTION == 'apply') } }
      steps { sh "cd ${TF_DIR} && terraform plan -out=tfplan" }
    }

    stage('Terraform Apply') {
      when { expression { !params.SKIP_TERRAFORM && params.ACTION == 'apply' } }
      steps {
        input message: 'Apply Terraform changes to AWS?'
        sh "cd ${TF_DIR} && terraform apply -auto-approve tfplan"
      }
    }

    stage('Terraform Destroy') {
      when { expression { !params.SKIP_TERRAFORM && params.ACTION == 'destroy' } }
      steps {
        input message: 'DESTROY infra?'
        sh "cd ${TF_DIR} && terraform destroy -auto-approve"
      }
    }

    // -------------------------
    // URLs from Terraform outputs
    // -------------------------
    stage('Get SonarQube URL') {
      when { expression { params.ACTION == 'apply' && params.RUN_SONAR } }
      steps {
        script {
          env.SONAR_URL = sh(
            script: "cd ${TF_DIR} && terraform output -raw sonarqube_url",
            returnStdout: true
          ).trim()
          echo "SonarQube URL: ${env.SONAR_URL}"
        }
      }
    }

    stage('Get Nexus URL') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        script {
          env.NEXUS_URL = sh(
            script: "cd ${TF_DIR} && terraform output -raw nexus_public_url",
            returnStdout: true
          ).trim()
          env.NPM_REGISTRY = "${env.NEXUS_URL}/repository/npm-group/"
          echo "Nexus URL: ${env.NEXUS_URL}"
          echo "NPM Registry: ${env.NPM_REGISTRY}"
        }
      }
    }

    // -------------------------
    // Get K8s master IP (only if deploying)
    // -------------------------
    stage('Get K8s Master IP') {
  when { expression { params.ACTION == 'apply' && !params.SKIP_DEPLOY && !params.SKIP_TERRAFORM } }
  steps {
    script {
      env.K8S_MASTER_IP = sh(
        script: "cd ${TF_DIR} && terraform output -raw k8s_master_public_ip",
        returnStdout: true
      ).trim()

      if (!env.K8S_MASTER_IP) {
        error("K8S_MASTER_IP is empty. Check Terraform state/outputs.")
      }

      echo "K8s Master IP: ${env.K8S_MASTER_IP}"
    }
  }
}


    // -------------------------
    // Decide if Ansible should run
    // -------------------------
    stage('Decide Ansible Run') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        script {
          if (params.SKIP_ANSIBLE) {
            env.DO_ANSIBLE = "false"
            echo "SKIP_ANSIBLE=true -> Skipping Ansible."
            return
          }

          def markerExists = fileExists(env.ANSIBLE_MARKER)
          if (markerExists && !params.FORCE_ANSIBLE) {
            env.DO_ANSIBLE = "false"
            echo "Ansible marker found (${env.ANSIBLE_MARKER}) -> Skipping Ansible."
          } else {
            env.DO_ANSIBLE = "true"
            echo "Ansible will run (marker missing OR FORCE_ANSIBLE=true)."
          }
        }
      }
    }

    stage('Generate Inventory') {
      when { expression { params.ACTION == 'apply' && env.DO_ANSIBLE == 'true' } }
      steps {
        sh """
          set -e
          cd ${TF_DIR}
          terraform output >/dev/null

          cd ../${ANS_DIR}
          chmod +x inventories/generate_inventory.sh
          inventories/generate_inventory.sh ../${TF_DIR}

          echo "===== INVENTORY ====="
          cat inventories/hosts.ini
        """
      }
    }

    stage('Run Ansible') {
      when { expression { params.ACTION == 'apply' && env.DO_ANSIBLE == 'true' } }
      steps {
        withCredentials([sshUserPrivateKey(
          credentialsId: 'ec2-ssh-key',
          keyFileVariable: 'SSH_KEY',
          usernameVariable: 'SSH_USER'
        )]) {
          sh """
            set -e
            cd ${ANS_DIR}
            export ANSIBLE_HOST_KEY_CHECKING=False

            ansible -i inventories/hosts.ini all -m ping --private-key \$SSH_KEY -u \$SSH_USER

            ansible-playbook -i inventories/hosts.ini playbooks/01-common.yml --private-key \$SSH_KEY -u \$SSH_USER
            ansible-playbook -i inventories/hosts.ini playbooks/02-k8s.yml --private-key \$SSH_KEY -u \$SSH_USER
            ansible-playbook -i inventories/hosts.ini playbooks/03-tools.yml --private-key \$SSH_KEY -u \$SSH_USER
          """
        }
      }
      post {
        success {
          sh "echo OK > ${ANSIBLE_MARKER}"
          echo "Created Ansible marker: ${ANSIBLE_MARKER}"
        }
      }
    }

    //////////////////////////
    stage('Install Node Exporter (All Servers)') {
  when { expression { params.ACTION == 'apply' && env.DO_ANSIBLE == 'true' } }
  steps {
    withCredentials([sshUserPrivateKey(
      credentialsId: 'ec2-ssh-key',
      keyFileVariable: 'SSH_KEY',
      usernameVariable: 'SSH_USER'
    )]) {
      sh """
        set -e
        cd ${ANS_DIR}
        export ANSIBLE_HOST_KEY_CHECKING=False
        ansible-playbook -i inventories/hosts.ini playbooks/04-node-exporter.yml --private-key \$SSH_KEY -u \$SSH_USER
      """
    }
  }
}

//////////////////////////////
stage('Update Prometheus Targets') {
  when { expression { params.ACTION == 'apply' && env.DO_ANSIBLE == 'true' } }
  steps {
    withCredentials([sshUserPrivateKey(
      credentialsId: 'ec2-ssh-key',
      keyFileVariable: 'SSH_KEY',
      usernameVariable: 'SSH_USER'
    )]) {
      sh """
        set -e
        cd ${ANS_DIR}
        export ANSIBLE_HOST_KEY_CHECKING=False
        ansible-playbook -i inventories/hosts.ini playbooks/05-prometheus-targets.yml --private-key \$SSH_KEY -u \$SSH_USER
      """
    }
  }
}


    // -------------------------
    // SonarQube Scan
    // -------------------------
    stage('SonarQube Scan (Next.js)') {
      when { expression { params.ACTION == 'apply' && params.RUN_SONAR } }
      steps {
        dir("${APP_DIR}") {
          withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
            withEnv(["SONAR_USER_HOME=${env.WORKSPACE}/.sonar"]) {
              sh '''
                set -e
                echo "Using SonarQube: $SONAR_URL"
                echo "Using NPM registry: $NPM_ CONFIG_REGISTRY"

                node -v
                npm -v

                npm config set registry "$NPM_CONFIG_REGISTRY"
                npm config get registry

                npm ci
                npm test --if-present || true

                npx sonar-scanner \
                  -Dsonar.host.url=$SONAR_URL \
                  -Dsonar.login=$SONAR_TOKEN \
                  -Dsonar.projectKey=nextjs-app \
                  -Dsonar.projectName=nextjs-app \
                  -Dsonar.sources=. \
                  -Dsonar.exclusions=node_modules/**,.next/**,out/**,coverage/**
              '''
            }
          }
        }
      }
    }

    // -------------------------
    // Docker Build
    // -------------------------
    stage('Docker Build') {
      when { expression { params.ACTION == 'apply' && !params.SKIP_DOCKER_BUILD } }
      steps {
        script { env.IMAGE_TAG_TO_DEPLOY = "${BUILD_NUMBER}" }

        dir("${APP_DIR}") {
          sh """
            set -e
            docker version
            docker build \
              -t ${DOCKER_IMAGE}:${BUILD_NUMBER} \
              -t ${DOCKER_IMAGE}:latest \
              .
          """
        }
      }
    }

    // -------------------------
    // Docker Push
    // -------------------------
    stage('Push Docker Image (Docker Hub)') {
      when { expression { params.ACTION == 'apply' && !params.SKIP_DOCKER_PUSH } }
      steps {
        script {
          // if build was skipped, deploy latest
          if (params.SKIP_DOCKER_BUILD) {
            env.IMAGE_TAG_TO_DEPLOY = "latest"
          }
        }

        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKERHUB_USER',
          passwordVariable: 'DOCKERHUB_TOKEN'
        )]) {
          sh """
            set -e
            echo "\$DOCKERHUB_TOKEN" | docker login -u "\$DOCKERHUB_USER" --password-stdin
            docker push ${DOCKER_IMAGE}:${env.IMAGE_TAG_TO_DEPLOY}
            docker push ${DOCKER_IMAGE}:latest
            docker logout
          """
        }
      }
    }

    // -------------------------
    // Fetch kubeconfig
    // -------------------------
    stage('Fetch kubeconfig') {
  steps {
    withCredentials([sshUserPrivateKey(
      credentialsId: 'ec2-ssh-key',
      keyFileVariable: 'SSH_KEY',
      usernameVariable: 'SSH_USER'
    )]) {

      sh '''
      set -e

      MASTER_PUBLIC_IP="13.201.31.174"

      mkdir -p "$HOME/.kube"

      scp -o StrictHostKeyChecking=no -i "$SSH_KEY" \
        $SSH_USER@${MASTER_PUBLIC_IP}:/home/$SSH_USER/.kube/config \
        "$HOME/.kube/config"

      # Force kubeconfig to use PUBLIC API endpoint
      sed -i "s#server: https://.*:6443#server: https://${MASTER_PUBLIC_IP}:6443#g" "$HOME/.kube/config"

      export KUBECONFIG="$HOME/.kube/config"

      # ✅ LAB ONLY: disable TLS verification (fix SAN mismatch)
      kubectl config set-cluster kubernetes --insecure-skip-tls-verify=true
      kubectl config unset clusters.kubernetes.certificate-authority-data || true

      kubectl get nodes
      '''
    }
  }
}



    // -------------------------
    // Helm Deploy
    // -------------------------
    stage('Helm Deploy to K8s') {
      when { expression { params.ACTION == 'apply' && !params.SKIP_DEPLOY } }
      steps {
        sh """
          set -e
          export KUBECONFIG=\$HOME/.kube/config

          kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

          helm upgrade --install ${HELM_RELEASE} ${HELM_CHART_DIR} \
            -n ${K8S_NAMESPACE} \
            --set image.repository=${DOCKER_IMAGE} \
            --set image.tag=${env.IMAGE_TAG_TO_DEPLOY}

          kubectl -n ${K8S_NAMESPACE} rollout status deployment/nextjs-app
          kubectl -n ${K8S_NAMESPACE} get pods -o wide
          kubectl -n ${K8S_NAMESPACE} get svc
        """
      }
    }
    
    stage('Install NGINX Ingress Controller') {
  when { expression { params.ACTION == 'apply' && !params.SKIP_DEPLOY } }
  steps {
    sh '''
      set -e
      export KUBECONFIG=$HOME/.kube/config

      kubectl get ns ingress-nginx >/dev/null 2>&1 || \
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml

      kubectl -n ingress-nginx wait --for=condition=Ready pod \
        -l app.kubernetes.io/component=controller \
        --timeout=180s
    '''
  }
}

  }

  post {
    always {
      echo "Pipeline finished"
    }
  }
}


how update my pipeline 