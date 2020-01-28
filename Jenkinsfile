pipeline {
	agent {
		label 'docker-multiarch'
	}
	options {
		buildDiscarder(logRotator(numToKeepStr: '5'))
		disableConcurrentBuilds()
	}
	environment {
		IMAGE       = 'alpine-nginx-full'
		BUILDX_NAME = "${IMAGE}_${GIT_BRANCH}_${BUILD_NUMBER}"

	}
	stages {
		stage('MultiArch Build') {
			when {
				branch 'master'
			}
			steps {
				ansiColor('xterm') {
					withCredentials([usernamePassword(credentialsId: 'jc21-dockerhub', passwordVariable: 'dpass', usernameVariable: 'duser')]) {
						sh "docker login -u '${duser}' -p '${dpass}'"
						sh './scripts/buildx --push -t docker.io/jc21/${IMAGE}:latest'
					}
				}
			}
		}
		stage('Node Build') {
			when {
				branch 'master'
			}
			steps {
				ansiColor('xterm') {
					withCredentials([usernamePassword(credentialsId: 'jc21-dockerhub', passwordVariable: 'dpass', usernameVariable: 'duser')]) {
						sh "docker login -u '${duser}' -p '${dpass}'"
						sh './scripts/buildx --push -t docker.io/jc21/${IMAGE}:node -f Dockerfile.node'
					}
				}
			}
		}
		stage('Golang Build') {
			when {
				branch 'master'
			}
			steps {
				ansiColor('xterm') {
					withCredentials([usernamePassword(credentialsId: 'jc21-dockerhub', passwordVariable: 'dpass', usernameVariable: 'duser')]) {
						sh "docker login -u '${duser}' -p '${dpass}'"
						sh './scripts/buildx --push -t docker.io/jc21/${IMAGE}:golang -f Dockerfile.golang'
					}
				}
			}
		}
	}
	post {
		success {
			juxtapose event: 'success'
			sh 'figlet "SUCCESS"'
		}
		failure {
			juxtapose event: 'failure'
			sh 'figlet "FAILURE"'
		}
	}
}
