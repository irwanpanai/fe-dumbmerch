pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  serviceAccountName: jenkins
                  containers:
                  - name: cloud-sdk
                    image: google/cloud-sdk:slim
                    command:
                    - /bin/sh
                    - -c
                    - cat
                    tty: true
                    volumeMounts:
                    - mountPath: /workspace
                      name: workspace-volume
                    - mountPath: /root/.config/gcloud
                      name: gcloud-config
                  - name: docker
                    image: docker:23.0
                    command:
                    - /bin/sh
                    - -c
                    - cat
                    tty: true
                    volumeMounts:
                    - mountPath: /var/run/docker.sock
                      name: docker-sock
                    - mountPath: /workspace
                      name: workspace-volume
                  volumes:
                  - name: docker-sock
                    hostPath:
                      path: /var/run/docker.sock
                  - name: workspace-volume
                    emptyDir: {}
                  - name: gcloud-config
                    emptyDir: {}
            '''
            defaultContainer 'cloud-sdk'
        }
    }

    environment {
        // Docker Configuration
        DOCKER_IMAGE = 'irwanpanai/fe-dumbmerch'
        DOCKER_TAG = 'latest'
        
        // Git Configuration
        GIT_REPO = 'https://github.com/irwanpanai/fe-dumbmerch.git'
        GIT_BRANCH = 'main'
        
        // GCP Configuration
        GOOGLE_PROJECT_ID = 'rancher-test-442805'
        GOOGLE_COMPUTE_ZONE = 'us-central1-c'
        CLUSTER_NAME = 'cluster-1'
        
        // Kubernetes Configuration
        KUBERNETES_NAMESPACE = 'dumbmerch'
        DEPLOYMENT_NAME = 'fe-dumbmerch'
        CONTAINER_NAME = 'fe-dumbmerch-container'
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: env.GIT_BRANCH,
                    url: env.GIT_REPO,
                    credentialsId: 'github-token'
            }
        }

        stage('Setup GCP Authentication') {
            steps {
                container('cloud-sdk') {
                    withCredentials([file(credentialsId: 'gcp-credentials', variable: 'GCP_KEY')]) {
                        sh '''
                            gcloud auth activate-service-account --key-file="$GCP_KEY"
                            gcloud config set project ${GOOGLE_PROJECT_ID}
                            gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${GOOGLE_COMPUTE_ZONE} --project ${GOOGLE_PROJECT_ID}
                            gcloud auth configure-docker
                            gcloud components install kubectl
                            gcloud components install gke-gcloud-auth-plugin
                        '''
                    }
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-cred', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh '''
                            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                            docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('cloud-sdk') {
                    script {
                        try {
                            // Create namespace if not exists
                            sh """
                                kubectl create namespace ${KUBERNETES_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                            """

                            // Apply Kubernetes manifests
                            sh """
                                # Update deployment image
                                kubectl set image deployment/${DEPLOYMENT_NAME} \
                                    ${CONTAINER_NAME}=${DOCKER_IMAGE}:${DOCKER_TAG} \
                                    -n ${KUBERNETES_NAMESPACE} --record=true || {
                                    # If deployment doesn't exist, apply the initial deployment
                                    kubectl apply -f fe-dumbmerch-deployment.yaml -n ${KUBERNETES_NAMESPACE}
                                }

                                # Wait for rollout to complete
                                kubectl rollout status deployment/${DEPLOYMENT_NAME} \
                                    -n ${KUBERNETES_NAMESPACE} --timeout=300s
                            """

                            // Verify deployment
                            sh """
                                echo "Deployment Status:"
                                kubectl get deployment ${DEPLOYMENT_NAME} -n ${KUBERNETES_NAMESPACE}
                                
                                echo "Pod Status:"
                                kubectl get pods -n ${KUBERNETES_NAMESPACE} -l app=${DEPLOYMENT_NAME}
                                
                                echo "Service Status:"
                                kubectl get svc -n ${KUBERNETES_NAMESPACE} -l app=${DEPLOYMENT_NAME}
                            """
                        } catch (Exception e) {
                            echo "Deployment failed: ${e.getMessage()}"
                            sh """
                                echo "Detailed Deployment Status:"
                                kubectl describe deployment ${DEPLOYMENT_NAME} -n ${KUBERNETES_NAMESPACE}
                                
                                echo "Pod Details:"
                                kubectl describe pods -n ${KUBERNETES_NAMESPACE} -l app=${DEPLOYMENT_NAME}
                                
                                echo "Events in Namespace:"
                                kubectl get events -n ${KUBERNETES_NAMESPACE}
                                
                                echo "Logs from Pods:"
                                for pod in \$(kubectl get pods -n ${KUBERNETES_NAMESPACE} -l app=${DEPLOYMENT_NAME} -o jsonpath='{.items[*].metadata.name}'); do
                                    echo "=== Logs from \$pod ==="
                                    kubectl logs \$pod -n ${KUBERNETES_NAMESPACE} --tail=100
                                done
                            """
                            throw e
                        }
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
            cleanWs()
        }
        success {
            echo """
                Pipeline berhasil!
                Image: ${DOCKER_IMAGE}:${DOCKER_TAG}
                Namespace: ${KUBERNETES_NAMESPACE}
                Deployment: ${DEPLOYMENT_NAME}
            """
        }
        failure {
            echo 'Pipeline gagal! Silakan cek log untuk detail.'
            script {
                container('cloud-sdk') {
                    sh """
                        echo "Final Deployment Status:"
                        kubectl get deployment ${DEPLOYMENT_NAME} -n ${KUBERNETES_NAMESPACE}
                        
                        echo "Final Pod Status:"
                        kubectl get pods -n ${KUBERNETES_NAMESPACE} -l app=${DEPLOYMENT_NAME}
                        
                        echo "Recent Events:"
                        kubectl get events -n ${KUBERNETES_NAMESPACE} --sort-by='.lastTimestamp' | tail -n 20
                    """
                }
            }
        }
    }
}
