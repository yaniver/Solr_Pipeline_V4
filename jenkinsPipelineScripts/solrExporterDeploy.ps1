$solr_pipeline_home=$args[0]
$zk_ip_port=$args[1]

# Host info
$solr_exporter_full_path=$solr_pipeline_home + "\\SolrExporter"

# Container info
$container_name="solrexporter"
$container_solr_exporter_path="/opt/solr-8.8.2/contrib/prometheus-exporter/"

cd $solr_exporter_full_path

$solrExpoExist=$(docker ps -f name=$container_name --format '{{.Names}}')
if($solrExpoExist -eq 'solrexporter') {            
	Write-Host "Solr exporter container already exist so no need to create additional container"
} else {            
    Write-Host "Solr exporter container does not exist, start creating the container..."
	docker run --name $container_name --network=dockprom_monitor-net -d --restart always -p 8094:8094 -p 8095:8095 -p 8096:8096 solr:8.8.2-slim
	
	$solr_exporter_config_core="solr-exporter-config_core.xml"
	$solr_exporter_config_jvm="solr-exporter-config_jvm.xml"
	$solr_exporter_config_other="solr-exporter-config_Jetty_Node_ClusterStatus_OverseerStatus.xml"
	$container_target_config_core=$container_name + ":" + $container_solr_exporter_path + "conf/" + $solr_exporter_config_core
	$container_target_config_jvm=$container_name + ":" + $container_solr_exporter_path + "conf/" + $solr_exporter_config_jvm
	$container_target_config_other=$container_name + ":" + $container_solr_exporter_path + "conf/" + $solr_exporter_config_other
	docker cp $solr_exporter_config_core $container_target_config_core
	docker cp $solr_exporter_config_jvm $container_target_config_jvm
	docker cp $solr_exporter_config_other $container_target_config_other
	
	$container_solr_exporter_command_core=$container_solr_exporter_path + "bin/solr-exporter"  + " -p 8094 -z " + $zk_ip_port + " -f " + $container_solr_exporter_path + "conf/solr-exporter-config_core.xml -n 16 & disown"
	$container_solr_exporter_command_jvm=$container_solr_exporter_path + "bin/solr-exporter"  + " -p 8095 -z " + $zk_ip_port + " -f " + $container_solr_exporter_path + "conf/solr-exporter-config_jvm.xml -n 16 & disown"
	$container_solr_exporter_command_other=$container_solr_exporter_path + "bin/solr-exporter"  + " -p 8096 -z " + $zk_ip_port + " -f " + $container_solr_exporter_path + "conf/solr-exporter-config_Jetty_Node_ClusterStatus_OverseerStatus.xml -n 16 & disown"
	docker exec -u root -i $container_name bash -c $container_solr_exporter_command_core
	docker exec -u root -i $container_name bash -c $container_solr_exporter_command_jvm
	docker exec -u root -i $container_name bash -c $container_solr_exporter_command_other
}