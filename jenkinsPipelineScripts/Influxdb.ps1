$solr_pipeline_home=$args[0]
$lab_name=$args[1]
# Host info
$influxdb_full_path=$solr_pipeline_home + "\\Influxdb"
# Container info
$container_name="influxdb"

$lab_path = $influxdb_full_path + "\\" + $lab_name
If(!(test-path $lab_path))
{
	New-Item -ItemType Directory -Force -Path $lab_path
} else {
	Write-Host "Lab folder already exist"
}

$solrExpoExist=$(docker ps -f name=$container_name --format '{{.Names}}')
if($solrExpoExist -eq 'influxdb') {            
	Write-Host "Influxdb container already exist so no need to create additional container"
} else {
    Write-Host "Influxdb container does not exist, start creating the container..."
	Write-Host "Influxdb Container as volume for presistent data when container is deleted"
	docker run --name $container_name --network=dockprom_monitor-net -d --restart always -p 8086:8086 -v $lab_path:/var/lib/influxdb influxdb:1.8
	Invoke-WebRequest -Uri http://localhost:8086/query -UseBasicParsing -Method Post -Body "q=CREATE DATABASE search"
	Invoke-WebRequest -Uri http://localhost:8086/query -UseBasicParsing -Method Post -Body "q=CREATE DATABASE jmeter"
}