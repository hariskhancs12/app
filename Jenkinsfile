pipeline {
  agent any

  environment {
    AWS_REGION   = 'us-east-1'            // change to your region
    ECR_REPO     = 'scenario30-app'
    ECS_CLUSTER  = 'scenario30-cluster'
    ECS_SERVICE  = 'scenario30-service'
    TASK_FAMILY  = 'scenario30-task'
    IMAGE_TAG    = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Resolve AWS account') {
      steps {
        script {
          // Credentials come from the EC2 instance profile (no keys stored in Jenkins)
          env.ACCOUNT_ID   = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
          env.ECR_REGISTRY = "${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
          env.IMAGE_URI    = "${env.ECR_REGISTRY}/${env.ECR_REPO}:${env.IMAGE_TAG}"
        }
      }
    }

    stage('Build image') {
      steps {
        sh 'docker build --build-arg BUILD_NUMBER=$BUILD_NUMBER -t $IMAGE_URI .'
      }
    }

    stage('Push to ECR') {
      steps {
        sh '''
          aws ecr get-login-password --region $AWS_REGION \
            | docker login --username AWS --password-stdin $ECR_REGISTRY
          docker push $IMAGE_URI
        '''
      }
    }

    stage('Register task definition') {
      steps {
        sh '''
          sed -e "s|__IMAGE_URI__|$IMAGE_URI|" \
              -e "s|__ACCOUNT_ID__|$ACCOUNT_ID|" \
              -e "s|__REGION__|$AWS_REGION|" taskdef.json > taskdef-rendered.json
          aws ecs register-task-definition --region $AWS_REGION \
            --cli-input-json file://taskdef-rendered.json > /dev/null
        '''
      }
    }

    stage('Deploy to ECS Fargate') {
      steps {
        sh '''
          aws ecs update-service --region $AWS_REGION \
            --cluster $ECS_CLUSTER --service $ECS_SERVICE \
            --task-definition $TASK_FAMILY --force-new-deployment > /dev/null
          aws ecs wait services-stable --region $AWS_REGION \
            --cluster $ECS_CLUSTER --services $ECS_SERVICE
        '''
      }
    }
  }

  post {
    always  { sh 'docker image prune -f || true' }
    success { echo "Deployed ${env.IMAGE_URI} to ${env.ECS_SERVICE}" }
  }
}
