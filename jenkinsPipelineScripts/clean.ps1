$solr_pipeline_home=$args[0]
$delete_all_db_data=$args[1]

docker rm solrexporter -f
docker rm jmeter -f

If ($delete_all_db_data  -eq 'true'){
	docker rm influxdb -f
	docker rm dockprom -f
	
	$delete_folder = $solr_pipeline_home + "\\dockprom"
	Remove-Item -Recurse -Force $delete_folder
}