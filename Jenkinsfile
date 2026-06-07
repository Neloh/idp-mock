pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        PROJECT_NAME = 'idp-agentcore'
    }

    stages {
        stage('Validate Spec') {
            steps {
                echo '[Stage 1] Validating infrastructure spec...'
                sh 'python3 platform_cli.py submit --spec examples/trade-service.yaml'
            }
        }

        stage('Terraform Plan') {
            steps {
                echo '[Stage 2] Running terraform plan...'
                dir('terraform') {
                    sh 'terraform init -backend=false'
                    sh 'terraform validate'
                    sh 'terraform plan -out=tfplan -input=false'
                }
            }
        }

        stage('Approval Gate') {
            steps {
                input message: 'Review the plan above. Approve deployment?',
                      ok: 'Deploy'
            }
        }

        stage('Terraform Apply') {
            steps {
                echo '[Stage 4] Applying infrastructure...'
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Smoke Test') {
            steps {
                echo '[Stage 5] Running smoke tests...'
                sh 'python3 -m pytest tests/ -v'
            }
        }
    }

    post {
        success {
            echo 'PIPELINE COMPLETE — Infrastructure deployed successfully.'
        }
        failure {
            echo 'PIPELINE FAILED — Check logs above.'
        }
    }
}
