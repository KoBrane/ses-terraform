
pipeline {
    agent {
        label 'docker'
    }
    options {
        skipDefaultCheckout(true)
    }

    parameters {
        choice(
            name: 'ENVIRONMENT', description: 'Select an environment',
            choices: ['default', 'qa']
        )
        string(name: 'terraform_bin', defaultValue: '/opt/terraform/bin/terraform', description: 'Location of the Terraform binary')
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    }
    
    environment {
        PLATFORM_TERRAFORM = credentials('platform-terraform')
        TF_CLI_ARGS        = "-no-color"
        TF_IN_AUTOMATION   = "1"
        AWS_ACCOUNT_ROLE     = 'PlatformTerraformAdminAccess'
        AWS_ACCOUNT_ID     = "${ params.ENVIRONMENT == 'qa' ? '208872934285' : '222974512203' }"
        AWS_REGION         = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        stage('AWS CLI Validate') {
            steps {
                script {
                    withAWS(credentials: 'platform-terraform', region: AWS_REGION, role: AWS_ACCOUNT_ROLE, roleAccount: AWS_ACCOUNT_ID) {
                        sh 'aws sts get-caller-identity'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                script {
                    sh "${params.terraform_bin} version"
                }
            }
        }

        stage('Init') {
            steps {
                withCredentials([gitUsernamePassword(credentialsId: '685cf71a-93da-43fb-bd8f-181eee539770')]) {
                    sh "terraform init -backend-config=environments/backend-${params.ENVIRONMENT}.conf"
                    sh "terraform workspace select -or-create=true ${params.ENVIRONMENT}"
                }
            }
        }

        stage('Plan') {
            steps {
                sh "${params.terraform_bin} plan -out tfplan --var-file=environments/${params.ENVIRONMENT}.tfvars"
                sh "${params.terraform_bin} show -no-color tfplan > tfplan.txt"
            }
        }

        stage('Approval') {
            when {
                not {
                    equals expected: true, actual: params.autoApprove
                }
            }

            steps {
                script {
                    def plan = readFile 'tfplan.txt'
                    timeout(time: 15, unit: 'MINUTES') {
                        input message: "Do you want to apply the plan?",
                            parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                    }
                }
            }
        }

        stage('Apply') {
            steps {
                sh "${params.terraform_bin} apply tfplan"
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'tfplan.txt'
        }
		success {
            emailext recipientProviders: [requestor()],
                    mimeType: 'text/html',
                    to: "edenecke@meso-scale.com,jhell@meso-scale.com,woffei@meso-scale.com",
                    subject: "SES Email Receipt terraform deployment Succeeded: ${currentBuild.fullDisplayName}",
                    body: '${SCRIPT, template="aws-build.template"}'
        }
        failure {
            emailext recipientProviders: [requestor()],
                    mimeType: 'text/html',
                    to: "edenecke@meso-scale.com,jhell@meso-scale.com,woffei@meso-scale.com",
                    subject: "SES Email Receipt terraform deployment Failure: ${currentBuild.fullDisplayName}",
                    body: '${SCRIPT, template="aws-build.template"}'
        }
    }
}