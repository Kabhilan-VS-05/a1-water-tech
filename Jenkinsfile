pipeline {
  agent any

  environment {
    FRONTEND_DIR = 'a1-water-online-shop'
    BACKEND_DIR = 'aws-lambdas/products-api'
    K8S_DIR = 'k8s'
  }

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  triggers {
    githubPush()
  }

  stages {
    stage('Clone') {
      steps {
        checkout scm
      }
    }

    stage('Build Frontend') {
      steps {
        dir("${FRONTEND_DIR}") {
          // Use node container to install and build (avoid local npm requirement)
          sh 'docker run --rm -v "$(pwd):/app" -w /app node:20 sh -c "npm ci && npm run build"'
        }
      }
    }

    stage('Build Backend') {
      steps {
        dir("${BACKEND_DIR}") {
          // Use node container to install backend dependencies
          sh 'docker run --rm -v "$(pwd):/app" -w /app node:20 npm ci'
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
          // Verify backend code tests
          sh 'docker run --rm -v "$(pwd):/app" -w /app node:20 npm test'
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