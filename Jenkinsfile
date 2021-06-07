pipeline {
    agent any
    options {
        timeout(time: 15, unit: 'HOURS')
    }
    stages {
		stage('Influxdb') {
            steps {
				echo 'Deploy Influxdb'
				powershell returnStatus: true, script: ".\\jenkinsPipelineScripts\\Influxdb.ps1 '${env.SOLR_PIPELINE_HOME}'  '${env.LAB_NAME}'"
			}
			}
		stage('Prometheus & Grafana') {
            steps {
				echo 'Deploy Prometheus & Grafana'
				powershell returnStatus: true, script: ".\\jenkinsPipelineScripts\\promdeploy.ps1 '${env.SOLR_PIPELINE_HOME}'  '${env.IDU_IP}'"
            }
        }
		stage('Solr Exporter') {
            steps {
				echo 'Deploying Solr Exporter'
				powershell returnStatus: true, script: ".\\jenkinsPipelineScripts\\solrExporterDeploy.ps1 '${env.SOLR_PIPELINE_HOME}'  '${env.ZK_IP_PORT}'"
            }
        }
		stage('Loki - Grafana logs collector') {
            steps {
				echo 'Deploying Loki - Grafana logs collector'
				//powershell returnStatus: true, script: ".\\jenkinsPipelineScripts\\solrExporterDeploy.ps1 '${env.SOLR_PIPELINE_HOME}'  '${env.ZK_IP_PORT}'"
            }
        }
        stage('Parallel Stage') {
            failFast true
            parallel {
                stage('Empty step') {
                    steps {
						echo 'Empty step'
                    }
                }
                stage('JMeter run') {
                    steps {
						echo 'Deploying JMeter load'
						powershell returnStatus: true, script: ".\\jenkinsPipelineScripts\\jmeterScriptExec.ps1 '${env.SOLR_PIPELINE_HOME}'  '${env.IDU_IP}'  '${env.SEARCH_DAY_FROM}'  '${env.DOMAIN}'"
                    }
                }

            }
        }
    }
    environment {
        ZK_IP_PORT = '10.10.193.92:2181'
        SOLR_PIPELINE_HOME = 'C:\\Solr_Pipeline_V2'
		LAB_NAME = 'L1648_v8.7'
		IDU_IP = '10.10.193.88'
		SEARCH_DAY_FROM = '2021-05-09'
		DOMAIN = 'L1648'
    }
    post {
        always {
			echo 'Clean environment'
			//cleanWs()
            //sh '~/CICD/jenkinsPipelineShellScripts/clean.sh'
        }
    }
}
