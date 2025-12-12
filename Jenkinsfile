@Library('jenkins.shared.library') _

pipeline {
  agent {
    label 'ubuntu_20_04_label'
  }
  tools {
    go "Go 1.15"
  }
  options {
    checkoutToSubdirectory('src/github.com/infobloxopen/ingress-nginx')
  }
  environment {
    DIRECTORY = "src/github.com/infobloxopen/ingress-nginx"
    GIT_VERSION = sh(script: "cd ${DIRECTORY} && git describe --always --long --tags --match 'controller-*' | sed s/controller-//",
                       returnStdout: true).trim()
    TAG = "${env.GIT_VERSION}-j${env.BUILD_NUMBER}"
    REGISTRY = 'infoblox'
    PLATFORMS = 'amd64'
    BUILDX_PLATFORMS = 'linux/amd64'
    ARCH = 'amd64'
    BASE_IMAGE = "infoblox/nginx-fips:${TAG}"
    DOCKER_CLI_EXPERIMENTAL = 'enabled'
    GOPATH = "$WORKSPACE"
    DEBUG=1
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
        sh "rm -f $DIRECTORY/images.list"
        prepareBuild()
      }
    }
    stage("Build NGINX Image") {
      steps {
        withDockerRegistry([credentialsId: "${env.JENKINS_DOCKER_CRED_ID}", url: ""]) {
          dir("$DIRECTORY/images/nginx") {
            sh "make build"
          }
        }
      }
    }
    stage("Push NGINX Image") {
      steps {
        withDockerRegistry([credentialsId: "${env.JENKINS_DOCKER_CRED_ID}", url: ""]) {
          dir("$DIRECTORY/images/nginx") {
            sh "make push"
          }
        }
        dir("$DIRECTORY") {
          sh 'echo ${BASE_IMAGE} >> images.list'
        }
      }
    }
    stage("Ingress Unit Tests") {
      steps {
        dir("$DIRECTORY") {
          sh "make test"
          sh "sudo rm -rf .cache .modcache"
        }
      }
    }
    stage("Build Ingress Image") {
      steps {
        withEnv(["TAG=${env.GIT_VERSION}-j${env.BUILD_NUMBER}-ingress", "PLATFORMS=amd64"]) {
          withDockerRegistry([credentialsId: "${env.JENKINS_DOCKER_CRED_ID}", url: ""]) {
            dir("$DIRECTORY") {
              sh "make build"
              sh "make image"
            }
          }
        }
      }
    }
    stage("Push Ingress Image") {
      steps {
        withEnv(["TAG=${env.GIT_VERSION}-j${env.BUILD_NUMBER}-ingress", "PLATFORMS=amd64"]) {
          withDockerRegistry([credentialsId: "${env.JENKINS_DOCKER_CRED_ID}", url: ""]) {
            dir("$DIRECTORY") {
              sh "make release"
              sh 'echo ${REGISTRY}/nginx-fips:${TAG} >> images.list'
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
        sh "touch images.list"
        finalizeBuild(readFile(file: 'images.list'))
      }
    }
    cleanup {
      dir("$DIRECTORY") {
        sh "sudo make clean || true"
        sh "rm -f images.list"
      }
      cleanWs()
    }
  }
}
