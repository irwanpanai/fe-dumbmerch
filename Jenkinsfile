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
                    withKubeConfig([credentialsId: 'kubeconfig']) {
                        sh '''
                            # Buat namespace jika belum ada
                            kubectl create namespace dumbmerch --dry-run=client -o yaml | kubectl apply -f -
                            
                            # Deploy aplikasi
                            kubectl apply -f fe-dumbmerch-deployment.yaml
                            
                            # Update image
                            kubectl set image deployment/fe-dumbmerch fe-dumbmerch-container=$DOCKER_IMAGE:$DOCKER_TAG -n dumbmerch
                            
                            # Tunggu deployment selesai
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
        }
    }
}
