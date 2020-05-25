pipeline {
	agent {
		label 'docker-multiarch'
	}
	options {
		buildDiscarder(logRotator(numToKeepStr: '5'))
		disableConcurrentBuilds()
		ansiColor('xterm')
	}
	environment {
		IMAGE        = 'alpine-nginx-full'
		BUILDX_NAME  = "${IMAGE}_${GIT_BRANCH}_${BUILD_NUMBER}"
		BRANCH_LOWER = "${BRANCH_NAME.toLowerCase().replaceAll('/', '-')}"
	}
	stages {
		stage('Environment') {
			parallel {
				stage('Master') {
					when {
						branch 'master'
					}
					steps {
						script {
							env.BUILDX_PUSH_TAGS        = "-t docker.io/jc21/${IMAGE}:latest"
							env.BUILDX_PUSH_TAGS_NODE   = "-t docker.io/jc21/${IMAGE}:node"
							env.BUILDX_PUSH_TAGS_GOLANG = "-t docker.io/jc21/${IMAGE}:golang"
						}
					}
				}
				stage('Other') {
					when {
						not {
							branch 'master'
						}
					}
					steps {
						script {
							// Defaults to the Branch name, which is applies to all branches AND pr's
							env.BUILDX_PUSH_TAGS        = "-t docker.io/jc21/${IMAGE}:github-${BRANCH_LOWER}"
							env.BUILDX_PUSH_TAGS_NODE   = "${BUILDX_PUSH_TAGS}-node"
							env.BUILDX_PUSH_TAGS_GOLANG = "${BUILDX_PUSH_TAGS}-golang"
						}
					}
				}
			}
		}
		stage('Base Build') {
			steps {
				withCredentials([usernamePassword(credentialsId: 'jc21-dockerhub', passwordVariable: 'dpass', usernameVariable: 'duser')]) {
					sh "docker login -u '${duser}' -p '${dpass}'"
					sh "./scripts/buildx --push ${BUILDX_PUSH_TAGS}"
				}
			}
		}
		stage('Node Build') {
			steps {
				withCredentials([usernamePassword(credentialsId: 'jc21-dockerhub', passwordVariable: 'dpass', usernameVariable: 'duser')]) {
					sh "docker login -u '${duser}' -p '${dpass}'"
					sh "./scripts/buildx --push -f Dockerfile.node ${BUILDX_PUSH_TAGS_NODE}"
				}
			}
		}
		stage('Golang Build') {
			steps {
				withCredentials([usernamePassword(credentialsId: 'jc21-dockerhub', passwordVariable: 'dpass', usernameVariable: 'duser')]) {
					sh "docker login -u '${duser}' -p '${dpass}'"
					sh "./scripts/buildx --push -f Dockerfile.golang ${BUILDX_PUSH_TAGS_GOLANG}"
				}
			}
		}
		stage('PR Comment') {
			when {
				allOf {
					changeRequest()
					not {
						equals expected: 'UNSTABLE', actual: currentBuild.result
					}
				}
			}
			steps {
				script {
					def comment = pullRequest.comment("""Docker Image for build ${BUILD_NUMBER} is available on [DockerHub](https://cloud.docker.com/repository/docker/jc21/${IMAGE}) as:

- `jc21/${IMAGE}:github-${BRANCH_LOWER}`
- `jc21/${IMAGE}:github-${BRANCH_LOWER}-node`
- `jc21/${IMAGE}:github-${BRANCH_LOWER}-golang`
""")
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
		unstable {
			juxtapose event: 'unstable'
			sh 'figlet "UNSTABLE"'
		}
	}
}
