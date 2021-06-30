$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$domain_name=$args[2]

$servicename1 = "rabbit_exporter1"
$servicename2 = "rabbit_exporter2"
$rabbit_full_path=$solr_pipeline_home + "\\RabbitMQ_exporter"
$crypto_full_path_script=$solr_pipeline_home + "\\CryptoVaronis\\vrnsCrypto.ps1"

cd $rabbit_full_path
 
# Create session for remote server for using it when I need to run command on remote server
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session2 = New-PSSession -ComputerName $idu_ip -Credential $Credential
$Session3 = New-PSSession -ComputerName $idu_ip -Credential $Credential

if (Invoke-Command -Session $Session2 -ScriptBlock {Get-Service $Using:servicename1 -ErrorAction SilentlyContinue})
{
	Write-Host "RabitMQ exporter services already exists in IDU server and won't be created"
}
Else {
	Write-Host "Start creating RabitMQ exporter services in IDU server"
	
	# Get RabbitMQ password from remote IDU Server
	# ===========================================
	$rabbit_connection_string_encoded = Invoke-Command -Session $Session3 -ScriptBlock {(Get-ItemProperty -Path HKLM:\SOFTWARE\Varonis\VSB -Name ConnectionString).ConnectionString}
	$rabbit_connection_string_deencoded = Invoke-Command -ScriptBlock {..\CryptoVaronis\vrnsCrypto.ps1 $rabbit_connection_string_encoded}
	Write-Host "====rabbit_connection_string_deencoded = $rabbit_connection_string_deencoded"

	# host=localhost;password=7b_9#ag0oOGqn;site=d6363289-6109-420f-8553-bca9cabca783;user=VaronisRabbitMQ;writer_site=d6363289-6109-420f-8553-bca9cabca783
	$string_to_search = "password=(.*);site"
	$rabbit_connection_string_deencoded -match $string_to_search
	$rabbit_password = $matches[1]
	Write-Host "====rabbit password = $rabbit_password"

	$source_path = $rabbit_full_path + "\\config.example.json"
	$file_content=(Get-Content -path $source_path -Raw)
	# "rabbit_pass": "ixu306ecyJ#d",
	$string_to_search='rabbit_pass": "(.*)",'
	$file_content -match $string_to_search
	($file_content -replace $matches[1],$rabbit_password) | Set-Content -Path $source_path

	$file_content=(Get-Content -path $source_path -Raw)
	$string_to_search='publish_port": "(.*)",'
	$file_content -match $string_to_search
	($file_content -replace $matches[1],"9419") | Set-Content -Path $source_path

	$file_content=(Get-Content -path $source_path -Raw)
	$string_to_search='include_queues": "(.*)",'
	$file_content -match $string_to_search
	($file_content -replace $matches[1],"SolrLoader") | Set-Content -Path $source_path

	#Copy RabbitMQ exporter folder to remote server
	$source_folder_only_folder_content = $rabbit_full_path + "\*"
	Copy-Item $source_folder_only_folder_content -Destination "C:\RabbitMQ_exporter\" -ToSession $Session3 -Recurse

	# Option 1 - create service
	Invoke-Command -Session $Session3 -ScriptBlock {
	sc.exe create $Using:servicename1 binpath= "C:\RabbitMQ_exporter\rabbitmq_exporter.exe --config-file C:\RabbitMQ_exporter\config.example.json" DisplayName= "RabbitMQ_Exporter_solrloader" start=auto obj=LocalSystem
	}

	Invoke-Command -Session $Session3 -ScriptBlock {
	sc.exe start $Using:servicename1
	}




	$file_content=(Get-Content -path $source_path -Raw)
	$string_to_search='publish_port": "(.*)",'
	$file_content -match $string_to_search
	($file_content -replace $matches[1],"9418") | Set-Content -Path $source_path

	$file_content=(Get-Content -path $source_path -Raw)
	$string_to_search='include_queues": "(.*)",'
	$file_content -match $string_to_search
	($file_content -replace $matches[1],"enricher") | Set-Content -Path $source_path

	#Copy RabbitMQ exporter folder to remote server
	$source_folder_only_folder_content = $rabbit_full_path + "\*"
	Copy-Item $source_folder_only_folder_content -Destination "C:\RabbitMQ_exporter2\" -ToSession $Session2 -Recurse

	Invoke-Command -Session $Session2 -ScriptBlock {
	sc.exe create $Using:servicename2 binpath= "C:\RabbitMQ_exporter2\rabbitmq_exporter.exe --config-file C:\RabbitMQ_exporter2\config.example.json" DisplayName= "RabbitMQ_Exporter_enricher" start=auto obj=LocalSystem
	}

	Invoke-Command -Session $Session2 -ScriptBlock {
	sc.exe start $Using:servicename2
	}	
}

Remove-PSSession $Session2
Remove-PSSession $Session3