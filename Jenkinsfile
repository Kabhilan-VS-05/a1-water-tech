pipeline {
  agent any

  environment {
    FRONTEND_DIR = 'a1-water-online-shop'
    BACKEND_DIR = 'aws-lambdas/products-api'
    K8S_DIR = 'k8s'
    PATH = "${env.WORKSPACE}/bin:${env.PATH}"
  }

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  triggers {
    githubPush()
  }

  stages {
    stage('Setup Tools') {
      steps {
        sh '''
          mkdir -p ${WORKSPACE}/bin
          
          # Setup Docker CLI if missing
          if ! command -v docker > /dev/null; then
            echo "Downloading Docker CLI..."
            curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.6.tgz -o docker.tgz
            tar xzvf docker.tgz
            mv docker/docker ${WORKSPACE}/bin/
            chmod +x ${WORKSPACE}/bin/docker
            rm -rf docker docker.tgz
          fi
          
          # Setup Kubectl if missing
          if ! command -v kubectl > /dev/null; then
            echo "Downloading kubectl..."
            curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o ${WORKSPACE}/bin/kubectl
            chmod +x ${WORKSPACE}/bin/kubectl
          fi
        '''
      }
    }

    stage('Clone') {
      steps {
        checkout scm
      }
    }

    stage('Build Frontend') {
      steps {
        dir("${FRONTEND_DIR}") {
          // Stream workspace into container without using volume mounts, build it, and stream the required output back!
          sh 'tar cf - . | docker run --rm -i -w /app node:20 sh -c "tar xf - && npm ci && npm run build && tar cf - dist node_modules" | tar xf -'
        }
      }
    }

    stage('Build Backend') {
      steps {
        dir("${BACKEND_DIR}") {
          // Stream workspace into container to install deps safely
          sh 'tar cf - . | docker run --rm -i -w /app node:20 sh -c "tar xf - && npm ci && tar cf - node_modules" | tar xf -'
        }
      }
    }

    stage('Test') {
      steps {
        dir("${FRONTEND_DIR}") {
          // Verify frontend built correctly
          sh 'test -d dist'
        }
        dir("${BACKEND_DIR}") {
          // Verify backend code tests by streaming the context dynamically
          sh 'tar cf - . | docker run --rm -i -w /app node:20 sh -c "tar xf - && npm test"'
        }
      }
    }

    stage('Docker Build') {
      steps {
        // We use the docker-cred to get the DockerHub username dynamically
        withCredentials([usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh """
            docker build -t \$DOCKER_USERNAME/a1-water-tech-frontend:${env.BUILD_NUMBER} ${FRONTEND_DIR}
            docker build -t \$DOCKER_USERNAME/a1-water-tech-backend:${env.BUILD_NUMBER} ${BACKEND_DIR}
          """
        }
      }
    }

    stage('Docker Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh """
            echo "\$DOCKER_PASSWORD" | docker login -u "\$DOCKER_USERNAME" --password-stdin
            docker push \$DOCKER_USERNAME/a1-water-tech-frontend:${env.BUILD_NUMBER}
            docker push \$DOCKER_USERNAME/a1-water-tech-backend:${env.BUILD_NUMBER}
          """
        }
      }
    }

    stage('Kubernetes Deploy') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh """
            # Apply initial services and deployments
            kubectl apply -f ${K8S_DIR}/backend-deployment.yaml
            kubectl apply -f ${K8S_DIR}/backend-service.yaml
            kubectl apply -f ${K8S_DIR}/frontend-deployment.yaml
            kubectl apply -f ${K8S_DIR}/frontend-service.yaml

            # Dynamically update the image to the newly pushed DockerHub version
            kubectl set image deployment/a1-backend a1-backend=\$DOCKER_USERNAME/a1-water-tech-backend:${env.BUILD_NUMBER}
            kubectl set image deployment/a1-frontend a1-frontend=\$DOCKER_USERNAME/a1-water-tech-frontend:${env.BUILD_NUMBER}

            # Wait for deployments to successfully rollout
            kubectl rollout status deployment/a1-backend
            kubectl rollout status deployment/a1-frontend
          """
        }
      }
    }
  }

  post {
    always {
      // Ensure we always logout to keep credentials secure
      sh 'docker logout || true'
    }
    success {
      echo 'CI/CD pipeline completed successfully.'
    }
    failure {
      echo 'CI/CD pipeline failed. Review the Jenkins logs for details.'
    }
  }
}