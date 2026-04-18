pipeline {
  agent any

  environment {
    FRONTEND_DIR = 'a1-water-online-shop'
    BACKEND_DIR = 'aws-lambdas/products-api'
    K8S_DIR = 'k8s'
    IMAGE_NAME = 'a1-water-tech'
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

    stage('Prepare') {
      steps {
        script {
          if (!env.IMAGE_NAME?.trim()) {
            error('IMAGE_NAME is not configured.')
          }

          env.FRONTEND_IMAGE = "${env.IMAGE_NAME}-frontend:${env.BUILD_NUMBER}"
          env.BACKEND_IMAGE = "${env.IMAGE_NAME}-backend:${env.BUILD_NUMBER}"
        }
      }
    }

    // 🔥 FRONTEND BUILD (Dockerized Node)
    stage('Build Frontend') {
      steps {
        dir("${FRONTEND_DIR}") {
          script {
            docker.image('node:20').inside {
              sh 'npm ci'
              sh 'npm run build'
            }
          }
        }
      }
    }

    // 🔥 BACKEND BUILD
    stage('Build Backend') {
      steps {
        dir("${BACKEND_DIR}") {
          script {
            docker.image('node:20').inside {
              sh 'npm ci'
            }
          }
        }
      }
    }

    // 🔥 TEST STAGE
    stage('Test') {
      steps {
        script {
          docker.image('node:20').inside {
            sh 'echo "Running validation checks"'

            dir("${FRONTEND_DIR}") {
              sh 'test -d dist'
            }

            dir("${BACKEND_DIR}") {
              sh 'test -f server.mjs'
              sh 'node --check server.mjs'
            }
          }
        }
      }
    }

    // 🔥 DOCKER BUILD
    stage('Docker Build') {
      steps {
        sh "docker build -t ${FRONTEND_IMAGE} ${FRONTEND_DIR}"
        sh "docker build -t ${BACKEND_IMAGE} ${BACKEND_DIR}"
      }
    }

    // 🔥 DOCKER PUSH
    stage('Docker Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'docker-cred',
          usernameVariable: 'DOCKER_USERNAME',
          passwordVariable: 'DOCKER_PASSWORD'
        )]) {
          sh '''
          echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

          docker tag ${FRONTEND_IMAGE} $DOCKER_USERNAME/${FRONTEND_IMAGE}
          docker tag ${BACKEND_IMAGE} $DOCKER_USERNAME/${BACKEND_IMAGE}

          docker push $DOCKER_USERNAME/${FRONTEND_IMAGE}
          docker push $DOCKER_USERNAME/${BACKEND_IMAGE}
          '''
        }
      }
    }

    // 🔥 KUBERNETES DEPLOY
    stage('Kubernetes Deploy') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'docker-cred',
          usernameVariable: 'DOCKER_USERNAME',
          passwordVariable: 'DOCKER_PASSWORD'
        )]) {
          sh """
            kubectl apply -f ${K8S_DIR}/backend-deployment.yaml
            kubectl apply -f ${K8S_DIR}/backend-service.yaml
            kubectl apply -f ${K8S_DIR}/frontend-deployment.yaml
            kubectl apply -f ${K8S_DIR}/frontend-service.yaml

            kubectl set image deployment/a1-backend a1-backend=$DOCKER_USERNAME/${BACKEND_IMAGE}
            kubectl set image deployment/a1-frontend a1-frontend=$DOCKER_USERNAME/${FRONTEND_IMAGE}

            kubectl rollout status deployment/a1-backend
            kubectl rollout status deployment/a1-frontend
          """
        }
      }
    }
  }

  post {
    always {
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