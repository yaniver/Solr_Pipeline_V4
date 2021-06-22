$solr_pipeline_home=$args[0]
$delete_all_db_data=$args[1]
$idu_ip=$args[2]
$domain_name=$args[3]

$servicename1 = "events_injector"

# Create session for remote server for using it when I need to run command on remote server
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session4 = New-PSSession -ComputerName $idu_ip -Credential $Credential

docker rm solrexporter -f
docker rm jmeter -f

Invoke-Command -Session $Session4 -ScriptBlock {
	taskkill /IM EndurenceVSBInjector.exe /F
}

Remove-PSSession $Session4

If ($delete_all_db_data  -eq 'true'){
	docker rm influxdb -f
	docker rm dockprom -f
	
	$delete_folder = $solr_pipeline_home + "\\dockprom"
	Remove-Item -Recurse -Force $delete_folder
}

