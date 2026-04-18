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

    stage('Prepare') {
      steps {
        script {
          if (!env.DOCKER_USERNAME?.trim()) {
            error('DOCKER_USERNAME is not configured in Jenkins.')
          }
          if (!env.DOCKER_PASSWORD?.trim()) {
            error('DOCKER_PASSWORD is not configured in Jenkins.')
          }
          if (!env.IMAGE_NAME?.trim()) {
            error('IMAGE_NAME is not configured in Jenkins.')
          }

          env.FRONTEND_IMAGE = "${env.DOCKER_USERNAME}/${env.IMAGE_NAME}-frontend:${env.BUILD_NUMBER}"
          env.BACKEND_IMAGE = "${env.DOCKER_USERNAME}/${env.IMAGE_NAME}-backend:${env.BUILD_NUMBER}"
        }
      }
    }

    stage('Build Frontend') {
      steps {
        dir("${FRONTEND_DIR}") {
          sh 'npm ci'
          sh 'npm run build'
        }
      }
    }

    stage('Build Backend') {
      steps {
        dir("${BACKEND_DIR}") {
          sh 'npm ci'
        }
      }
    }

    stage('Test') {
      steps {
        sh 'echo "Running placeholder validation checks"'
        dir("${FRONTEND_DIR}") {
          sh 'test -d dist'
        }
        dir("${BACKEND_DIR}") {
          sh 'test -f index.mjs'
          sh 'node --check server.mjs'
        }
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker build -t ${FRONTEND_IMAGE} ${FRONTEND_DIR}'
        sh 'docker build -t ${BACKEND_IMAGE} ${BACKEND_DIR}'
      }
    }

    stage('Docker Push') {
      steps {
        sh 'echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin'
        sh 'docker push ${FRONTEND_IMAGE}'
        sh 'docker push ${BACKEND_IMAGE}'
      }
    }

    stage('Kubernetes Deploy') {
      steps {
        sh """
          kubectl apply -f ${K8S_DIR}/backend-deployment.yaml
          kubectl apply -f ${K8S_DIR}/backend-service.yaml
          kubectl apply -f ${K8S_DIR}/frontend-deployment.yaml
          kubectl apply -f ${K8S_DIR}/frontend-service.yaml
          kubectl set image deployment/a1-backend a1-backend=${BACKEND_IMAGE}
          kubectl set image deployment/a1-frontend a1-frontend=${FRONTEND_IMAGE}
          kubectl rollout status deployment/a1-backend
          kubectl rollout status deployment/a1-frontend
        """
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
