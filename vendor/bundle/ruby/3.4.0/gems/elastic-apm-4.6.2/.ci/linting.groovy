#!/usr/bin/env groovy
@Library('apm@current') _

pipeline {
  agent { label 'docker && linux && immutable' }
  options {
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '20', daysToKeepStr: '30'))
    timestamps()
    ansiColor('xterm')
    disableResume()
    durabilityHint('PERFORMANCE_OPTIMIZED')
    rateLimitBuilds(throttle: [count: 60, durationName: 'hour', userBoost: true])
    quietPeriod(10)
  }
  triggers {
    issueCommentTrigger('(?i).*(?:jenkins\\W+)?run\\W+(?:the\\W+)?linters(?:\\W+please)?.*')
  }
  stages {
    stage('Sanity checks') {
      environment {
        HOME = "${env.WORKSPACE}"
        PATH = "${env.WORKSPACE}/bin:${env.PATH}"
      }
      steps {
        script {
          def sha = getGitCommitSha()
          preCommit(commit: "${sha}", junit: true)
        }
      }
    }
  }
}
