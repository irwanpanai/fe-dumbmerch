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
                   - /bin/sh 
                   - -c
                   - cat
                   tty: true
                   volumeMounts:
                   - mountPath: /var/run/docker.sock
                     name: docker-sock
                 - name: kubectl
                   image: bitnami/kubectl:latest
                   command:
                   - /bin/sh
                   - -c
                   - cat
                   tty: true
                   securityContext:
                     runAsUser: 0
                 volumes:
                 - name: docker-sock
                   hostPath:
                     path: /var/run/docker.sock
           '''
           defaultContainer 'kubectl'
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
                       script {
                           try {
                               sh '''#!/bin/sh
                                   set -x
                                   # Debug info
                                   echo "Current working directory:"
                                   pwd
                                   
                                   echo "Listing directory contents:"
                                   ls -la
                                   
                                   echo "Checking kubectl version:"
                                   kubectl version --client
                                   
                                   echo "Checking current context:"
                                   kubectl config current-context
                                   
                                   # Create namespace if not exists
                                   echo "Creating namespace:"
                                   kubectl create namespace dumbmerch --dry-run=client -o yaml | kubectl apply -f -
                                   
                                   # Check deployment file
                                   echo "Checking if deployment file exists:"
                                   ls -la fe-dumbmerch-deployment.yaml
                                   
                                   # Apply deployment
                                   echo "Applying deployment:"
                                   kubectl apply -f fe-dumbmerch-deployment.yaml -n dumbmerch
                                   
                                   # Verify deployment 
                                   echo "Verifying deployment:"
                                   kubectl get deployments -n dumbmerch
                                   
                                   # Update image
                                   echo "Updating image:"
                                   kubectl set image deployment/fe-dumbmerch fe-dumbmerch-container=${DOCKER_IMAGE}:${DOCKER_TAG} -n dumbmerch
                                   
                                   # Check rollout status
                                   echo "Checking rollout status:"
                                   kubectl rollout status deployment/fe-dumbmerch -n dumbmerch --timeout=120s
                               '''
                           } catch (Exception e) {
                               echo "Error during deployment: ${e.getMessage()}"
                               sh '''
                                   echo "Pod status:"
                                   kubectl get pods -n dumbmerch
                                   
                                   echo "Deployment description:"
                                   kubectl describe deployment fe-dumbmerch -n dumbmerch
                                   
                                   echo "Pod descriptions:"
                                   for pod in $(kubectl get pods -n dumbmerch -o jsonpath='{.items[*].metadata.name}'); do
                                       echo "Description for $pod:"
                                       kubectl describe pod $pod -n dumbmerch
                                       
                                       echo "Logs for $pod:"
                                       kubectl logs $pod -n dumbmerch
                                   done
                               '''
                               throw e
                           }
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
       }
       success {
           echo 'Pipeline berhasil dieksekusi!'
       }
       failure {
           echo 'Pipeline gagal! Silakan cek log untuk detail.'
           
           script {
               container('kubectl') {
                   sh '''
                       echo "Final Pod status:"
                       kubectl get pods -n dumbmerch
                       
                       echo "Events in namespace:"
                       kubectl get events -n dumbmerch
                       
                       echo "Deployment status:"
                       kubectl get deployments -n dumbmerch
                   '''
               }
           }
       }
   }
}
