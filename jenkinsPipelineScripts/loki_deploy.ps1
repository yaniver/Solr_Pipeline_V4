$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$domain_name=$args[2]


$loki_full_path=$solr_pipeline_home + "\\Loki_Grafana"
$process_name = "loki"
$Folder_destonation = 'C:\Loki_Promtail\'

$TimeOut = New-PSSessionOption -IdleTimeoutMSec (New-TimeSpan -Days 3).TotalMilliSeconds #Create Session opened for 3 days so events simulator won't be closed after default of 2 hours
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session = New-PSSession -ComputerName $idu_ip -Credential $Credential -Name Session -SessionOption $TimeOut
$Session2 = New-PSSession -ComputerName $idu_ip -Credential $Credential -Name Session2 -SessionOption $TimeOut



# Deploy Loki and Promtail on IDU server
# ======================================
# The command uses the Using scope modifier to identify a local variable in a remote command
if (Invoke-Command -Session $Session -ScriptBlock {Get-Process $Using:process_name -ErrorAction SilentlyContinue})
{
	Write-Host "Loki & Promtail processes already exists in IDU server"
}
Else {
	Write-Host "Loki & Promtail processes not found in IDU server, start creating it"
	
	cd $solr_pipeline_home

	# Set idu ip for influxdb datasource
	$config_path=$solr_pipeline_home + "\\dockerpromModification\\GrafanaDatasource\\datasource.yml"
	$file_content=(Get-Content -path $config_path -Raw)
	$string_to_search="http://(.*):3100"
	$file_content -match $string_to_search
	($file_content -replace $matches[1],$idu_ip) | Set-Content -Path $config_path
	
	$file_content=(Get-Content -path $config_path -Raw)
	$string_to_search="http://(.*):3100/loki"
	$file_content -match $string_to_search
	($file_content -replace $matches[1],$idu_ip) | Set-Content -Path $config_path
	
	Invoke-Command -Session $Session -ScriptBlock {
		if (Test-Path -Path $Using:Folder_destonation) {
			Write-Host "Loki folder already exists and won't be created again."
		} else {
			Write-Host "Copy Loki folder to remote server"
			$source_folder_only_folder_content = $loki_full_path + "\*"
			Copy-Item $source_folder_only_folder_content -Destination $Folder_destonation -ToSession $Session -Recurse -Force
		}
	}

	# Session param set with Timeout param of 3 days so background process (-AsJob flag) won't be killed after 2 hours which is the default
	Invoke-Command -Session $Session -ScriptBlock {
		Start-Process -wait -FilePath "loki-windows-amd64.exe" -WorkingDirectory "C:\Loki_Promtail" -ArgumentList "--config.file C:\Loki_Promtail\loki-local-config.yaml"
	} -AsJob
	
	Start-Sleep -s 10
	
	Write-Host "Loki process created successfully in IDU server."
	
	Invoke-Command -Session $Session2 -ScriptBlock {
		Start-Process -wait -FilePath "promtail-windows-amd64.exe" -WorkingDirectory "C:\Loki_Promtail" -ArgumentList "--config.file C:\Loki_Promtail\promtail-local-config.yaml"
	} -AsJob
	
	Start-Sleep -s 5
	
	Write-Host "Promtail process created successfully in IDU server."
}
