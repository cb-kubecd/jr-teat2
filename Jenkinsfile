pipeline {
    agent any
    environment {
      ORG               = 'cb-kubecd'
      APP_NAME          = 'jr-teat2'
      GIT_PROVIDER      = 'github.com'
      CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    }
    stages {
      stage('CI Build and push snapshot') {
        when {
          branch 'PR-*'
        }
        environment {
          PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
          PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
          HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        }
        steps {
          dir ('/home/jenkins/go/src/github.com/cb-kubecd/jr-teat2') {
            checkout scm
            sh "make linux"
            sh 'export VERSION=$PREVIEW_VERSION && skaffold build -f skaffold.yaml'

            sh "jx step validate --min-jx-version 1.2.36"
            sh "jx step post build --image \$DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"
          }
          dir ('/home/jenkins/go/src/github.com/cb-kubecd/jr-teat2/charts/preview') {
            sh "make preview"
            sh "jx preview --app $APP_NAME --dir ../.."
          }
        }
      }
      stage('Build Release') {
        when {
          branch 'master'
        }
        steps {
          dir ('/home/jenkins/go/src/github.com/cb-kubecd/jr-teat2') {
            git 'https://github.com/cb-kubecd/jr-teat2.git'
            // so we can retrieve the version in later steps
            sh "echo \$(jx-release-version) > VERSION"
          }
          // dir ('/home/jenkins/go/src/github.com/cb-kubecd/jr-teat2/charts/jr-teat2') {
            // until we switch to the new kubernetes / jenkins credential implementation use git credentials store
            // sh "git config --global credential.helper store"
            // sh "jx step validate --min-jx-version 1.1.73"
            // sh "jx step git credentials"
          // }s
          dir ('/home/jenkins/go/src/github.com/cb-kubecd/jr-teat2/charts/jr-teat2') {
            sh "make tag"
          }
          dir ('/home/jenkins/go/src/github.com/cb-kubecd/jr-teat2') {
            sh "make build"
            sh 'export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml'
            sh "jx step validate --min-jx-version 1.2.36"
            sh "jx step post build --image \$DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
          }
        }
      }
      stage('Promote to Environments') {
        when {
          branch 'master'
        }
        steps {
          dir ('/home/jenkins/go/src/github.com/cb-kubecd/jr-teat2/charts/jr-teat2') {
            sh 'jx step changelog --version v\$(cat ../../VERSION)'

            // release the helm chart
            sh 'make release'

            // promote through all 'Auto' promotion Environments
            sh 'jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION) --no-wait'
          }
        }
      }
    }
  }
