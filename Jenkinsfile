pipeline {
  environment {
    ARGO_SERVER = '98.67.129.254:80'
  }
  agent {
    kubernetes {
      yamlFile 'build-agent.yaml'
      defaultContainer 'maven'
      idleMinutes 1
    }
  }
  stages {
    stage('Build') {
      parallel {
        stage('Compile') {
          steps {
            container('maven') {
              sh 'mvn compile'
            }
          }
        }
      }
    }
    stage('Static Analysis') {
      parallel {
        stage('Unit Tests') {
          steps {
            container('maven') {
              sh 'mvn test'
            }
          }
        }
        stage('SCA') {
          steps {
            container('maven') {
              catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
                sh 'mvn org.owasp:dependency-check-maven:check'
              }
            }
          }    
          post {
            always {
              archiveArtifacts allowEmptyArchive: true, artifacts: 'target/dependency-check-report.html', fingerprint: true, onlyIfSuccessful: true
              // dependencyCheckPublisher pattern: 'report.xml'
            }
          }
        }
        // stage('OSS License Checker') {
        //   steps {
        //     container('licensefinder') {
        //       sh 'ls -al'
        //       sh '''#!/bin/bash --login
        //           /bin/bash --login
        //           rvm use default
        //           gem install license_finder
        //           license_finder
        //       '''
        //     }
        //   }
        // }
      }
    }
    // stage('SAST') {
    //   steps {
    //     container('slscan') {
    //       sh 'scan --type java,depscan --build'
    //       }
    //     }
    //   post {
    //     success {
    //       archiveArtifacts allowEmptyArchive: true, artifacts: 'reports/*', fingerprint: true, onlyIfSuccessful: true
    //     } 
    //   }
    // }
    stage('SAST') {
      steps {
        container('slscan') {
          // Run the scan and capture the exit code
          script {
            def status = sh script: 'scan --type java,depscan --build', returnStatus: true
            // Check if scan was successful or had vulnerabilities
            if (status != 0) {
              echo "Scan detected issues or failed, but proceeding to next stage."
            }
          }
        }
      }
      post {
        success {
          archiveArtifacts allowEmptyArchive: true, artifacts: 'reports/*', fingerprint: true, onlyIfSuccessful: true
        } 
      }
    }
    stage('Package') {
      parallel {
        stage('Create Jarfile') {
          steps {
            container('maven') {
              sh 'mvn package -DskipTests'
            }
          }
        }
        stage('Docker BnP') {
                steps {
                  container('kaniko') {
                    sh '/kaniko/executor --force -f `pwd`/Dockerfile -c `pwd` --insecure --skip-tls-verify --cache=true --destination=docker.io/tvdven/dso-demo-azure'
            } 
          }
        }
      }
    }
    stage('Image Analysis') {
      parallel {
        stage('Image Linting') {
          steps {
            container('docker-tools') {
              sh 'dockle docker.io/tvdven/dso-demo-azure'
            }
          } 
        }
        stage('Image Scan') {
          steps {
            container('docker-tools') {
              sh 'trivy image --exit-code 1 tvdven/dso-demo-azure'
            }
          } 
        }
      } 
    }
    stage('Deploy to Dev') {
      environment {
        AUTH_TOKEN = credentials('argocd-jenkins-deployer-token')
      }
      steps {
        container('docker-tools') {
          sh 'docker run -t schoolofdevops/argocd-cli argocd app sync dso-demo-azure --insecure --server $ARGO_SERVER --auth-token $AUTH_TOKEN'
          sh 'docker run -t schoolofdevops/argocd-cli argocd app wait dso-demo-azure --health --timeout 300   --insecure --server $ARGO_SERVER --auth-token $AUTH_TOKEN'
        } 
      }
    }
  }
}
