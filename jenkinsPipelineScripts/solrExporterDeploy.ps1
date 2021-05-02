$solr_pipeline_home=$args[0]
$zk_ip_port=$args[1]

# Host info
# $solr_exporter_full_path=$solr_pipeline_home + "\\SolrExporter"
$solr_exporter_config_core="solr-exporter-config_core.xml"
$solr_exporter_config_other="solr-exporter-config_Jetty_Node_ClusterStatus_OverseerStatus.xml"
$solr_exporter_config_jvm="solr-exporter-config_jvm.xml"

# Container info
$container_name="solrexporter"
$container_solr_exporter_path="/opt/solr-8.8.2/contrib/prometheus-exporter/"
$container_solr_exporter_commands=$container_solr_exporter_path + "bin/"  + " -p 8094 -z 10.10.193.107:2181 -f /opt/solr-8.8.2/contrib/prometheus-exporter/conf/solr-exporter-config_core.xml -n 16"


$container_target_config_core=$container_name + ":" + $container_solr_exporter_path + "conf/" + $solr_exporter_config_core
$container_target_config_other=$container_name + ":" + $container_solr_exporter_path + "conf/" + $solr_exporter_config_other
$container_target_config_jvm=$container_name + ":" + $container_solr_exporter_path + "conf/" + $solr_exporter_config_jvm

# cd $solr_exporter_full_path
# Replace Zookeeper IP and Port in script file
# $file_content=(Get-Content -path $script_path -Raw)
#$string_to_search="-z (.*) -f"
#$file_content -match $string_to_search
#($file_content -replace $matches[1],$zk_ip_port) | Set-Content -Path $script_path


$solrExpoExist=$(docker ps -f name=$container_name --format '{{.Names}}')
if($solrExpoExist -eq 'solrexporter') {            
	Write-Host "Solr exporter container already exist so no need to create additional container"
} else {            
    Write-Host "Solr exporter container does not exist, start creating the container"
	docker run --name $container_name --network=dockprom_monitor-net -d --restart always -p 8094:8094 -p 8095:8095 -p 8096:8096 solr:8.8.2-slim
	docker cp $solr_exporter_config_core $container_target_config_core
	#$command_permission="chmod +x " + $container_solr_exporter_script_path
	#docker exec -u root -i $container_name bash -c $command_permission
	#docker exec -u root -i $container_name bash -c "chmod +x /opt/solr-8.8.2/contrib/prometheus-exporter/bin/solr-exporter"
	docker exec -u root -i $container_name bash -c $container_solr_exporter_commands 
	
}