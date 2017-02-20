node {
    stage("PreCheck") {
        RequestPath=RequestPath.replace(" ","").toLowerCase()
        ServiceName=ServiceName.replace(" ","").toLowerCase()
    }
    stage("Build") {
        print "Checkout Source Code"
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/AchuthSankar/HelloWorld.git']]])
        sh "mvn -DskipTests=true package"
    }
    stage("Unit Testing") {
        build 'HelloWorldServiceTest'
    }
    stage("DEV Tool Checkout") {
        print "Checkout Env Setup"
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'scripts']], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/AchuthSankar/iaac.git']]])       
        sh """
        echo $RequestPath
        echo $ServiceName
        echo $ServicePort
        echo $StripRequestPath
        """
    }
    stage("Dev Containerizing") {
       withEnv(["ServiceName=Test"]) {
        sh returnStatus: true, script: """
            export ServiceName=$ServiceName
            data=`./scripts/docker_image_deploy.sh`
            exit 0
        """
       }
    }
    stage("Dev API configuration") {
        sh """
        curl -i -X DELETE \
          --url http://localhost:8001/apis/${ServiceName}
        data=`curl -i -X POST \
          -o /dev/null \
          -s -w "%{http_code}" \
          --url http://localhost:8001/apis/ \
          --data "name=${ServiceName}" \
          --data "upstream_url=${ServicePort}" \
          --data "request_path=${RequestPath}"`
        if [ \$data != 201 ]; then
          exit 1  
        fi
        """
    }
    stage("Integration Testing") {
        
    }
    stage("Stage Infrastructure") {
        
    }
    stage("Stage Deployment") {
        
    }
    
    input message: 'Do you want to deploy to production ???', ok: 'Deploy', submitterParameter: 'isDeployableReady'
    
    stage("Production Deployment") {
        if (${isDeployableReady}) {
            echo "Deploy"
        } else {
            echo "Cancelled"
        }
    }
}