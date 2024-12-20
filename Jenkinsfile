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
                    - mountPath: /var/run/docker.sock
                      name: docker-sock
                  - name: kubectl
                    image: bitnami/kubectl:latest
                    command:
                    - cat
                    tty: true
                    volumeMounts:
                    - mountPath: /root/.kube
                      name: kubeconfig
                  volumes:
                  - name: docker-sock
                    hostPath:
                      path: /var/run/docker.sock
                  - name: kubeconfig
                    secret:
                      secretName: kubeconfig
            '''
        }
    }
    
    environment {
        DOCKER_IMAGE = 'irwanpanai/fe-dumbmerch'
        DOCKER_TAG = 'latest'
        KUBECONFIG = credentials('kubeconfig')
        GIT_REPO = 'https://github.com/irwanpanai/fe-dumbmerch.git'
        GIT_BRANCH = 'main'
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                git branch: env.GIT_BRANCH, 
                    url: env.GIT_REPO,
                    credentialsId: 'github-token'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-cred', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh '''
                            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                            docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
                            docker push $DOCKER_IMAGE:$DOCKER_TAG
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    withKubeConfig([credentialsId: 'kubeconfig']) {
                        sh '''
                            # Debug information
                            echo "Checking kubectl configuration..."
                            kubectl config view
                            
                            echo "Checking current context..."
                            kubectl config current-context
                            
                            echo "Checking cluster connection..."
                            kubectl cluster-info
                            
                            echo "Applying deployment..."
                            kubectl apply -f fe-dumbmerch-deployment.yaml -n dumbmerch || echo "Failed to apply deployment"
                            
                            echo "Setting new image..."
                            kubectl set image deployment/fe-dumbmerch fe-dumbmerch-container=$DOCKER_IMAGE:$DOCKER_TAG -n dumbmerch || echo "Failed to set image"
                            
                            echo "Checking deployment status..."
                            kubectl rollout status deployment/fe-dumbmerch --timeout=60s -n dumbmerch || echo "Deployment status check failed"
                        '''
                    }
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
        success {
            echo 'Pipeline berhasil dieksekusi!'
        }
        failure {
            echo 'Pipeline gagal! Silakan cek log untuk detail.'
        }
    }
}
