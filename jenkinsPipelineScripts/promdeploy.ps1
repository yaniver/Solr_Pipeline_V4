$solr_pipeline_home=$args[0]

cd $solr_pipeline_home
git clone https://github.com/stefanprodan/dockprom
Copy-Item -Path "${SOLR_PIPELINE_HOME}\dockerpromModification\GrafanaDashboardExtra\*.json" -Destination "${SOLR_PIPELINE_HOME}\dockprom\grafana\provisioning\dashboards" -Force -Verbose
Copy-Item -Path "${SOLR_PIPELINE_HOME}\dockerpromModification\Prometheus\*.yml" -Destination "${SOLR_PIPELINE_HOME}\dockprom\prometheus" -Force -Verbose
cd dockprom
$ADMIN_USER="admin"
$ADMIN_PASSWORD="admin"
docker-compose up -d