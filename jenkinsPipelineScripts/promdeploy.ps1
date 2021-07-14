$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$db_ip=$args[2]
$grafana_version=$args[3]


cd $solr_pipeline_home

# Set idu ip for influxdb datasource
$config_path=$solr_pipeline_home + "\\dockerpromModification\\GrafanaDatasource\\datasource.yml"
$file_content=(Get-Content -path $config_path -Raw)
$string_to_search="http://(.*):8086"
$file_content -match $string_to_search
($file_content -replace $matches[1],$idu_ip) | Set-Content -Path $config_path

$config_prometheus_path=$solr_pipeline_home + "\\dockerpromModification\\Prometheus\\prometheus.yml"
$file_content=(Get-Content -path $config_prometheus_path -Raw)
$string_to_search="'(.*):9190"
$file_content -match $string_to_search
($file_content -replace $matches[1],$db_ip) | Set-Content -Path $config_prometheus_path

$file_content=(Get-Content -path $config_prometheus_path -Raw)
$string_to_search="'(.*):9180"
$file_content -match $string_to_search
($file_content -replace $matches[1],$idu_ip) | Set-Content -Path $config_prometheus_path

$file_content=(Get-Content -path $config_prometheus_path -Raw)
$string_to_search="'(.*):9419"
$file_content -match $string_to_search
($file_content -replace $matches[1],$idu_ip) | Set-Content -Path $config_prometheus_path

$file_content=(Get-Content -path $config_prometheus_path -Raw)
$string_to_search="'(.*):9418"
$file_content -match $string_to_search
($file_content -replace $matches[1],$idu_ip) | Set-Content -Path $config_prometheus_path

git clone https://github.com/stefanprodan/dockprom
Copy-Item -Path "${SOLR_PIPELINE_HOME}\dockerpromModification\GrafanaDashboardExtra\*.json" -Destination "${SOLR_PIPELINE_HOME}\dockprom\grafana\provisioning\dashboards" -Force -Verbose
Copy-Item -Path "${SOLR_PIPELINE_HOME}\dockerpromModification\GrafanaDatasource\*.yml" -Destination "${SOLR_PIPELINE_HOME}\dockprom\grafana\provisioning\datasources" -Force -Verbose
Copy-Item -Path "${SOLR_PIPELINE_HOME}\dockerpromModification\GrafanaPlugins\*.*" -Destination "${SOLR_PIPELINE_HOME}\dockprom\grafana\provisioning\plugins" -Force -Verbose
Copy-Item -Path "${SOLR_PIPELINE_HOME}\dockerpromModification\Prometheus\*.yml" -Destination "${SOLR_PIPELINE_HOME}\dockprom\prometheus" -Force -Verbose
cd dockprom

$config_path = $solr_pipeline_home + "\\dockprom\\docker-compose.yml"
$file_content=(Get-Content -path $config_path -Raw)
$string_to_search='grafana/grafana:(.*)'
$file_content -match $string_to_search
($file_content -replace $matches[1],$grafana_version) | Set-Content -Path $config_path

$ADMIN_USER="admin"
$ADMIN_PASSWORD="admin"
docker-compose up -d