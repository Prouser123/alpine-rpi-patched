// Scripted Pipeline
// Requires libraries from https://github.com/Prouser123/jenkins-tools
// Made by @Prouser123 for https://ci.jcx.ovh.

node('docker-cli') {
  cleanWs()

  docker.image('jcxldn/jenkins-containers:base').inside {

    stage('Patch') {
	  def scmVars = checkout scm
	  echo "found GIT_COMMIT: ${scmVars.GIT_COMMIT}"
	  echo "set env.GIT_COMMIT: ${env.GIT_COMMIT}"
	  env.GIT_COMMIT = scmVars.GIT_COMMIT
	  
	  sh 'chmod +x patcher.sh && ./patcher.sh jenkins'
	  
      archiveArtifacts artifacts: 'alpine-patched.tar.gz', fingerprint: true
	  
      cleanWs()
    }
  }
}