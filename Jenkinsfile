pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: docker
                image: docker:20.10
                command:
                - cat
                tty: true
                volumeMounts:
                - name: docker-sock
                  mountPath: /var/run/docker.sock
              volumes:
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
            """
        }
    }
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = 'irwanpanai/fe-dumbmerch'
        TOKEN = credentials('cluster-token')
    }
    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                sh """
                docker login -u ${DOCKERHUB_CREDENTIALS_USR} -p ${DOCKERHUB_CREDENTIALS_PSW}
                docker build -t ${DOCKER_IMAGE}:latest .
                docker push ${DOCKER_IMAGE}:latest
                """
            }
        }
        stage('Deploy to GKE') {
            steps {
                sh """
                kubectl config set-credentials jenkins-user --token=$TOKEN
                kubectl get pods
                kubectl set image deployment/fe-dumbmerch fe-dumbmerch=${DOCKER_IMAGE}:latest --record
                """
            }
        }
    }
}
