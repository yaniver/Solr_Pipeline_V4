$solr_pipeline_home=$args[0]
$solr_exporter_full_path=$solr_pipeline_home + "\\SolrExporter"

cd $solr_exporter_full_path
$solrexporter_path=/mnt/solrexporter
$volume_path=$solr_exporter_full_path + ":" + $solrexporter_path

docker build -t solrexporter .

$solrExpoExist=$(docker ps -f name=solrexporter)
if($solrExpoExist) {            
    Write-Host "Your string is not EMPTYm meaning solrexporter container exist"           
} else {            
    docker run --name solrexporter --volume $volume_path --network=dockprom_monitor-net -d --restart always -p 8094:8094 -p 8095:8095 -p 8096:8096 solrexporter           
}