pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  serviceAccountName: jenkins
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
                  volumes:
                  - name: docker-sock
                    hostPath:
                      path: /var/run/docker.sock
            '''
        }
    }

    environment {
        DOCKER_IMAGE = 'irwanpanai/fe-dumbmerch'
        DOCKER_TAG = 'latest'
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
                    withKubeConfig([
                        credentialsId: 'kubeconfig',
                        serverUrl: 'https://kubernetes.default.svc'
                    ]) {
                        sh '''
                            # Debug information
                            echo "Current working directory:"
                            pwd
                            
                            echo "Listing directory contents:"
                            ls -la
                            
                            echo "Checking kubectl version:"
                            kubectl version
                            
                            echo "Checking current context:"
                            kubectl config current-context
                            
                            echo "Creating namespace:"
                            kubectl create namespace dumbmerch --dry-run=client -o yaml | kubectl apply -f -
                            
                            echo "Checking if deployment file exists:"
                            ls -la fe-dumbmerch-deployment.yaml
                            
                            echo "Applying deployment:"
                            kubectl apply -f fe-dumbmerch-deployment.yaml -n dumbmerch
                            
                            echo "Verifying deployment:"
                            kubectl get deployments -n dumbmerch
                            
                            echo "Updating image:"
                            kubectl set image deployment/fe-dumbmerch fe-dumbmerch-container=$DOCKER_IMAGE:$DOCKER_TAG -n dumbmerch
                            
                            echo "Checking rollout status:"
                            kubectl rollout status deployment/fe-dumbmerch -n dumbmerch --timeout=120s
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
            
            script {
                // Print pod details on failure
                container('kubectl') {
                    sh '''
                        echo "Pod status:"
                        kubectl get pods -n dumbmerch
                        
                        echo "Pod descriptions:"
                        kubectl describe pods -n dumbmerch
                        
                        echo "Pod logs:"
                        for pod in $(kubectl get pods -n dumbmerch -o jsonpath='{.items[*].metadata.name}'); do
                            echo "Logs for $pod:"
                            kubectl logs $pod -n dumbmerch
                        done
                    '''
                }
            }
        }
    }
}
