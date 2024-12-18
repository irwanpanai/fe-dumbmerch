pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: docker
                    image: docker:latest
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
            '''
        }
    }
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_USERNAME = 'irwanpanai'
        IMAGE_NAME = 'fe-dumbmerch'
        IMAGE_TAG = 'latest'
        DEPLOYMENT_NAME = 'fe-dumbmerch'
        KUBERNETES_NAMESPACE = 'dumbmerch'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Login to DockerHub') {
            steps {
                container('docker') {
                    sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    sh """
                        docker build -t ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .
                    """
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                container('docker') {
                    sh """
                        docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh """
                        kubectl set image deployment/${DEPLOYMENT_NAME} ${IMAGE_NAME}=${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} -n ${KUBERNETES_NAMESPACE}
                    """
                }
            }
        }
    }
    
    post {
        always {
            container('docker') {
                sh 'docker logout'
            }
        }
    }
}
