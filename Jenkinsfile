// Scripted Pipeline
// Requires libraries from https://github.com/Prouser123/jenkins-tools
// Made by @Prouser123 for https://ci.jcx.ovh.

node('docker-cli') {
  cleanWs()

  docker.image('jcxldn/jenkins-containers:base').inside {

    stage('Patch') {
      checkout scm
	  
	  sh 'chmod +x patcher.sh && ./patcher.sh'
	  
      archiveArtifacts artifacts: 'alpine-patched.tar.gz', fingerprint: true
	  
      cleanWs()
    }
  }
}