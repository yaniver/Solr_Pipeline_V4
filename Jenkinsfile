pipeline {
    agent any
    options {
        timeout(time: 15, unit: 'HOURS')
    }
    stages {
        stage('Prometheus') {
            steps {
				echo 'Deploy Prometheus'
				powershell returnStatus: true, script: ".\\jenkinsPipelineScripts\\promdeploy.ps1 '${env.SOLR_PIPELINE_HOME}'"
            }
        }
        stage('Solr Exporter') {
            steps {
				echo 'Deploying Solr Exporter'
				powershell returnStatus: true, script: ".\\jenkinsPipelineScripts\\solrExporterDeploy.ps1 '${env.SOLR_PIPELINE_HOME}'  '${env.ZK_IP_PORT}'"
            }
        }
        stage('Parallel Stage') {
            failFast true
            parallel {
                stage('JMeter run') {
                    steps {
						echo 'Deploying JMeter load'
                        //sh '~/CICD/jenkinsPipelineShellScripts/jmeterScriptExec.sh'
                    }
                }
                stage('Grafana Alerts') {
                    steps {
						echo 'Deploying Grafana Alerts'
                        //sh '~/CICD/jenkinsPipelineShellScripts/grafanaAlert.sh'
                    }
                }
            }
        }
    }
    environment {
        ZK_IP_PORT = '10.10.193.107:2181'
        SOLR_PIPELINE_HOME = 'C:\\Solr_Pipeline'
    }
    post {
        always {
			echo 'Clean environment'
			//cleanWs()
            //sh '~/CICD/jenkinsPipelineShellScripts/clean.sh'
        }
    }
}
