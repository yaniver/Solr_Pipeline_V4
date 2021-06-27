$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$domain_name=$args[2]


$loki_full_path=$solr_pipeline_home + "\\Loki_Grafana"
$servicename = "loki"
$servicename2 = "promtail"

$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session = New-PSSession -ComputerName $idu_ip -Credential $Credential



# Deploy Loki and Promtail on IDU server
# ======================================
# The command uses the Using scope modifier to identify a local variable in a remote command
if (Invoke-Command -Session $Session -ScriptBlock {Get-Service $Using:servicename -ErrorAction SilentlyContinue})
{
	Write-Host "Loki & Promtail services already exists in IDU server"
}
Else {
	Invoke-Command -Session $Session -ScriptBlock {
		cmd.exe --% /c winrm set winrm/config/service @{AllowUnencrypted="true"}
	}

	Write-Host "Loki & Promtail services not found in IDU server, start creating it"
	
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
	
	Write-Host "Copy Loki & promtail files to remote server"
	Copy-Item $loki_full_path -Destination "C:\Loki_Promtail\" -ToSession $Session -Recurse

	# Create service
	Invoke-Command -Session $Session -ScriptBlock {
	sc.exe create $Using:servicename binpath= "C:\Loki_Promtail\loki-windows-amd64.exe --config-file C:\Loki_Promtail\loki-local-config.yaml" DisplayName= "Loki Server" start=auto obj=LocalSystem
	}

	Invoke-Command -Session $Session -ScriptBlock {
	sc.exe start $Using:servicename
	}
	
	Start-Sleep -s 10
	
	Write-Host "Loki service created successfully in IDU server."
	
	Invoke-Command -Session $Session -ScriptBlock {
	sc.exe create $Using:servicename2 binpath= "C:\Loki_Promtail\promtail-windows-amd64.exe --config-file C:\Loki_Promtail\promtail-local-config.yaml" DisplayName= "Promtail Server" start=auto obj=LocalSystem
	}

	Invoke-Command -Session $Session -ScriptBlock {
	sc.exe start $Using:servicename2
	}
	
	Start-Sleep -s 10
	
	Write-Host "Promtail service created successfully in IDU server."
}
