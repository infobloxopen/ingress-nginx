@Library('jenkins.shared.library') _

pipeline {
  agent {
    label 'ubuntu_docker_label'
  }
  tools {
    go "Go 1.14.4"
  }
  options {
    checkoutToSubdirectory('src/github.com/infobloxopen/ingress-nginx')
  }
  environment {
    GIT_VERSION = sh(script: "git describe --always --long --tags",
                       returnStdout: true).trim()
    IMAGE_TAG = "${env.GIT_VERSION}-j${env.BUILD_NUMBER}"
    REGISTRY = 'infoblox'
    IMGNAME = 'nginx-fips'
    PLATFORMS = 'amd64'
    ARCH = 'amd64'
    MULTI_ARCH_IMG="${env.REGISTRY}/${env.IMGNAME}-${env.ARCH}"
    BASEIMAGE = "${REGISTRY}/nginx-fips:${TAG}"
    DOCKER_CLI_EXPERIMENTAL = 'enabled'
    GOPATH = "$WORKSPACE"
    DIRECTORY = "src/github.com/infobloxopen/ingress-nginx"
  }
  stages {
    stage("Setup") {
      steps {
        prepareBuild()
      }
    }
    stage("Build NGINX Image") {
      steps {
        dir("$DIRECTORY") {
          sh "export TAG=${env.IMAGE_TAG}"
          sh "make container"
          sh "make fips-test"
        }
      }
    }
    stage("Push NGINX Image") {
      when {
        anyOf { branch 'nginx-0.27.1-fips'; buildingTag() }
      }
      steps {
        withDockerRegistry([credentialsId: "${env.JENKINS_DOCKER_CRED_ID}", url: ""]) {
          dir("$DIRECTORY") {
            sh "export IMAGE=${env.REGISTRY}/${env.IMGNAME}"
            sh "cd $DIRECTORY && docker tag ${env.MULTI_ARCH_IMG}:${env.TAG} ${env.IMAGE}:${env.TAG} && docker push ${env.IMAGE}:${env.TAG}"
          }
        }
      }
    }
    stage("Ingress Unit Tests") {
      steps {
        dir("$DIRECTORY") {
          sh "make test"
        }
      }
    }
    stage("Build Ingress Image") {
      steps {
        dir("$DIRECTORY") {
          export TAG = "ingress-${env.IMAGE_TAG}"
          sh "make build && make build-plugin"
          sh "make container"
        }
      }
    }
    stage("Push Ingress Image") {
      when {
        anyOf { branch 'nginx-0.27.1-fips'; buildingTag() }
      }
      steps {
        withDockerRegistry([credentialsId: "${env.JENKINS_DOCKER_CRED_ID}", url: ""]) {
          dir("$DIRECTORY") {
            sh "make push"
          }
        }
      }
    }
  }
  post {
    success {
      // finalizeBuild is one of the Secure CICD helper methods
      dir("$DIRECTORY") {
          finalizeBuild()
      }
    }
    cleanup {
      dir("$DIRECTORY") {
        sh "make clean || true"
      }
      cleanWs()
    }
  }
}
