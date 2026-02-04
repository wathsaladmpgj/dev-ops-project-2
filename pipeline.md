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
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT = '0'

    REPO_URL = 'https://github.com/wathsaladmpgj/dev-ops-project-2.git'
    TF_DIR   = 'terraform-infra'
    ANS_DIR  = 'ansible'
    APP_DIR  = 'app'

    // Marker SHOULD NOT be in workspace because deleteDir() wipes it.
    // Per-job marker in Jenkins home:
    ANSIBLE_MARKER = "${JENKINS_HOME}/.ansible_done_${JOB_NAME}"
    
    DOCKER_IMAGE = "docker.io/janith9988/nextjs-app"
  }

  stages {

    stage('Checkout') {
      steps {
        script {
          // If SKIP_TERRAFORM=true, do NOT wipe workspace because state may be stored locally
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
    // Sonar URL (from TF state)
    // -------------------------
    stage('Get SonarQube URL') {
      when { expression { params.ACTION == 'apply' && params.RUN_SONAR } }
      steps {
        script {
          def sonarUrl = sh(
            script: "cd ${TF_DIR} && terraform output -raw sonarqube_url",
            returnStdout: true
          ).trim()

          env.SONAR_URL = sonarUrl
          echo "SonarQube URL: ${env.SONAR_URL}"
        }
      }
    }
    
    //--------------------------
    //Nexus URL
    //--------------------------
    stage('Get Nexus URL') {
  when { expression { params.ACTION == 'apply' } }
  steps {
    script {
      def nexusUrl = sh(
        script: "cd ${TF_DIR} && terraform output -raw nexus_public_url",
        returnStdout: true
      ).trim()

      env.NEXUS_URL = nexusUrl
      env.NPM_REGISTRY = "${env.NEXUS_URL}/repository/npm-group/"
      echo "Nexus URL: ${env.NEXUS_URL}"
      echo "NPM Registry: ${env.NPM_REGISTRY}"
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

    // -------------------------
    // Generate inventory (only if Ansible runs)
    // -------------------------
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

    // -------------------------
    // Run Ansible
    // -------------------------
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
          // create marker if ansible succeeds (outside workspace)
          sh "echo OK > ${ANSIBLE_MARKER}"
          echo "Created Ansible marker: ${ANSIBLE_MARKER}"
        }
      }
    }

    // -------------------------
    // SonarQube Scan (Next.js)
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
                echo "Using NPM registry: $NPM_CONFIG_REGISTRY"

                node -v
                npm -v
                
                # ✅ Nexus cache for dependencies
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
// Docker Build (Next.js)
// -------------------------
stage('Docker Build') {
  when { expression { params.ACTION == 'apply' } }
  steps {
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
// Push Docker Image (Docker Hub)
// -------------------------
stage('Push Docker Image (Docker Hub)') {
  when { expression { params.ACTION == 'apply' } }
  steps {
    withCredentials([usernamePassword(
      credentialsId: 'dockerhub-creds',
      usernameVariable: 'DOCKERHUB_USER',
      passwordVariable: 'DOCKERHUB_TOKEN'
    )]) {
      sh """
        set -e
        echo "\$DOCKERHUB_TOKEN" | docker login -u "\$DOCKERHUB_USER" --password-stdin

        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
        docker push ${DOCKER_IMAGE}:latest

        docker logout
      """
    }
  }
}

  }

  post {
    always {
      echo "Pipeline finished"
    }
  }
}
