pipeline {
    agent {
        kubernetes {
            label 'jenkins-pod'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:20.10.8
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        GITHUB_CREDENTIALS = credentials('github-pat') 
        DOCKER_IMAGE = 'irwanpanai/fe-dumbmerch'
        K8S_NAMESPACE = 'jenkins'
        K8S_DEPLOYMENT = 'fe-dumbmerch'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                    docker build -t ${DOCKER_IMAGE}:latest .
                    docker login -u ${DOCKERHUB_CREDENTIALS_USR} -p ${DOCKERHUB_CREDENTIALS_PSW}
                    docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        stage('Update Kubernetes Deployment') {
            steps {
                script {
                    sh """
                    kubectl set image deployment/${K8S_DEPLOYMENT} app-container=${DOCKER_IMAGE}:latest -n ${K8S_NAMESPACE}
                    """
                }
            }
        }
    }
    post {
        success {
            echo 'Deployment succeeded!'
        }
        failure {
            echo 'Deployment failed.'
        }
    }
}
