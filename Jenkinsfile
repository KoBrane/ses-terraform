pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=plan.tfplan'
            }
        }

        stage('Terraform Apply') {
            when {
                branch 'main'
            }
            steps {
                sh 'terraform apply plan.tfplan'
            }
        }

        stage('Tag Release') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def releaseTag = getNextReleaseTag()
                    sh "git tag -a ${releaseTag} -m 'Release ${releaseTag}'"
                    sh "git push origin ${releaseTag}"
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}

def getNextReleaseTag() {
    def latestTag = sh(script: "git describe --tags --abbrev=0", returnStdout: true).trim()
    def versionParts = latestTag.split('\\.')
    def majorVersion = versionParts[0].toInteger()
    def minorVersion = versionParts[1].toInteger()
    def patchVersion = versionParts[2].toInteger() + 1

    return "${majorVersion}.${minorVersion}.${patchVersion}"
}