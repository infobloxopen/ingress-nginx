@Library('jenkins.shared.library') _

pipeline {
  agent {
    label 'ubuntu_docker_label'
  }
  tools {
    go "Go 1.13"
  }
  options {
    checkoutToSubdirectory('src/github.com/infobloxopen/ingress-nginx')
  }
  environment {
    DIRECTORY = "src/github.com/infobloxopen/ingress-nginx"
    GIT_VERSION = sh(script: "cd ${DIRECTORY} && git describe --always --long --tags",
                       returnStdout: true).trim()
    TAG = "${env.GIT_VERSION}-j${env.BUILD_NUMBER}"
    REGISTRY = 'infoblox'
    IMGNAME = 'nginx-fips'
    PLATFORMS = 'amd64'
    ARCH = 'amd64'
    MULTI_ARCH_IMG="${env.REGISTRY}/${env.IMGNAME}-${env.ARCH}"
    MULTI_ARCH_IMAGE = "${env.REGISTRY}/${env.IMGNAME}"
    BASEIMAGE = "${REGISTRY}/${env.IMGNAME}:${TAG}"
    DOCKER_CLI_EXPERIMENTAL = 'enabled'
    GOPATH = "$WORKSPACE"
  }
  stages {
    stage("Setup docker-ce") {
      when {
        expression {
          DOCKER_VERSION = sh(returnStdout: true, script: "docker -v | awk -F\"[ ,]+\" '/version/ {print \$3}'").trim()
          DOCKER_VERSION < '19.03.0'
        }
      }
      steps {
        sh "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
        sh 'sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"'
        sh "sudo apt-get update"
        sh 'sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce'
      }
    }
    stage("Setup") {
      steps {
        prepareBuild()
      }
    }
    stage("Build NGINX Image") {
      steps {
        dir("$DIRECTORY/images/nginx") {
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
          dir("$DIRECTORY/images/nginx") {
            sh "docker push ${env.REGISTRY}/${env.IMGNAME}:${env.TAG}"
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
        withEnv(["TAG=ingress-${env.TAG}"]) {
          dir("$DIRECTORY") {
            sh "make build && make build-plugin"
            sh "make container"
          }
        }
      }
    }
    stage("Push Ingress Image") {
      when {
        anyOf { branch 'nginx-0.*-fips'; buildingTag() }
      }
      steps {
        withEnv(["TAG=ingress-${env.TAG}"]) {
          withDockerRegistry([credentialsId: "${env.JENKINS_DOCKER_CRED_ID}", url: ""]) {
            dir("$DIRECTORY") {
              sh "make push"
            }
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
