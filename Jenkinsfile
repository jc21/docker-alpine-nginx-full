pipeline {
	agent {
		label 'docker-multiarch'
	}
	options {
		buildDiscarder(logRotator(numToKeepStr: '10'))
		disableConcurrentBuilds()
	}
	environment {
		IMAGE = 'alpine-nginx-full'
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
