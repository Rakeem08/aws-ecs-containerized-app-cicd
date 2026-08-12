pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        AWS_REGION          = 'us-east-1'
        ECR_REGISTRY        = '067514125942.dkr.ecr.us-east-1.amazonaws.com'
        FRONTEND_REPOSITORY = 'rakeem-devops-frontend'
        BACKEND_REPOSITORY  = 'rakeem-devops-backend'
        ECS_CLUSTER         = 'rakeem-devops-cluster'
        FRONTEND_SERVICE    = 'rakeem-devops-frontend-service'
        BACKEND_SERVICE     = 'rakeem-devops-backend-service'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    docker --version
                    aws --version
                    aws sts get-caller-identity
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                    aws ecr get-login-password --region "$AWS_REGION" |
                    docker login --username AWS --password-stdin "$ECR_REGISTRY"
                '''
            }
        }

        stage('Build Images') {
            steps {
                sh '''
                    docker build \
                      --build-arg REACT_APP_API_URL=/api \
                      -t "$ECR_REGISTRY/$FRONTEND_REPOSITORY:$BUILD_NUMBER" \
                      -t "$ECR_REGISTRY/$FRONTEND_REPOSITORY:latest" \
                      ./frontend

                    docker build \
                      -t "$ECR_REGISTRY/$BACKEND_REPOSITORY:$BUILD_NUMBER" \
                      -t "$ECR_REGISTRY/$BACKEND_REPOSITORY:latest" \
                      ./backend
                '''
            }
        }

        stage('Push Images') {
            steps {
                sh '''
                    docker push "$ECR_REGISTRY/$FRONTEND_REPOSITORY:$BUILD_NUMBER"
                    docker push "$ECR_REGISTRY/$FRONTEND_REPOSITORY:latest"

                    docker push "$ECR_REGISTRY/$BACKEND_REPOSITORY:$BUILD_NUMBER"
                    docker push "$ECR_REGISTRY/$BACKEND_REPOSITORY:latest"
                '''
            }
        }

        stage('Deploy to ECS') {
            steps {
                sh '''
                    aws ecs update-service \
                      --cluster "$ECS_CLUSTER" \
                      --service "$BACKEND_SERVICE" \
                      --force-new-deployment \
                      --region "$AWS_REGION"

                    aws ecs update-service \
                      --cluster "$ECS_CLUSTER" \
                      --service "$FRONTEND_SERVICE" \
                      --force-new-deployment \
                      --region "$AWS_REGION"
                '''
            }
        }

        stage('Wait for ECS') {
            steps {
                sh '''
                    aws ecs wait services-stable \
                      --cluster "$ECS_CLUSTER" \
                      --services "$BACKEND_SERVICE" "$FRONTEND_SERVICE" \
                      --region "$AWS_REGION"
                '''
            }
        }
    }

    post {
        success {
            echo 'Deployment completed successfully!'
        }

        failure {
            echo 'Deployment failed. Review the stage logs above.'
        }

        always {
            sh 'docker logout "$ECR_REGISTRY" || true'
        }
    }
}