pipeline {
    agent any
    options {
        timeout(time: 15, unit: 'HOURS')
    }
    stages {
        stage('Prometheus') {
            steps {
				bat "${env.SOLR_PIPELINE_HOME}\\jenkinsPipelineScripts\\promdeploy.ps1 ${env.SOLR_PIPELINE_HOME}"
            }
        }
        stage('Solr Exporter') {
            steps {
				echo 'Deploying Solr Exporter'
                //sh '~/CICD/jenkinsPipelineShellScripts/solrExporterDeploy.sh'
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
        ZK_HOST = '10.10.173.32'
        SOLR_PIPELINE_HOME = 'C:\\Users\\yeran\\AppData\\Local\\Jenkins\\.jenkins\\workspace\\Solr_Pipeline_2_main'
    }
    post {
        always {
			echo 'Clean environment'
            //sh '~/CICD/jenkinsPipelineShellScripts/clean.sh'
        }
    }
}
