$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$db_ip=$args[2]
$sql_instance=$args[3]
$shadow_db_name=$args[4]
$domain_name=$args[5]


# Define as global for params used in function (instead of passing them in the function call) which is good practice in case the params are not being change during the script execution
$global:sonar_full_path=$solr_pipeline_home + "\\Sonar"
$global:sonar_config_path=$sonar_full_path + "\\sonarConfiguration"

$sonar_config2_file_path = $sonar_full_path + "\\out\\Config\\Sonar.config"
$sonar_config_file_path = $sonar_full_path + "\\out\\Sonard.dll.config"
$servicename = "sonard"


# Create sessions for remote servers for using it when I need to run command on remote server
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session = New-PSSession -ComputerName $idu_ip -Credential $Credential
$Session_db = New-PSSession -ComputerName $db_ip -Credential $Credential

function SetSonarConfig {
	param( [string]$port, [string]$folder_name )
    # Copy locally the required configuration before copy the entire folder+configuration to the remote server
	$source_path = $sonar_config_path + "\\" + $folder_name + "\\Sonar.config"
	$dest_path = $sonar_full_path + "\\out\\Config"
	
	If ($folder_name  -eq 'IDU'){
		$file_content=(Get-Content -path $source_path -Raw)
		$string_to_search='sqldb" providerName="mssql" connectionString="Server=(.*);Database'
		$file_content -match $string_to_search
		# Add additional backslash otherwise I'll get "the regular expression pattern \ is not valid"
		$matches[1]=$matches[1] -replace '\\', '\\'
		($file_content -replace $matches[1],$sql_instance) | Set-Content -Path $source_path
		
		$file_content=(Get-Content -path $source_path -Raw)
		$string_to_search="Database='(.*)'; User"
		$file_content -match $string_to_search
		($file_content -replace $matches[1],$shadow_db_name) | Set-Content -Path $source_path
		
		$file_content=(Get-Content -path $source_path -Raw)
		$string_to_search='sqldb_vrnsdomaindb" providerName="mssql" connectionString="Server=(.*);Database'
		$file_content -match $string_to_search
		$matches[1]=$matches[1] -replace '\\', '\\'
		($file_content -replace $matches[1],$sql_instance) | Set-Content -Path $source_path
		
		$file_content=(Get-Content -path $source_path -Raw)
		$string_to_search='db" url="http://(.*):5985'
		$file_content -match $string_to_search
		($file_content -replace $matches[1],$db_ip) | Set-Content -Path $source_path
	}
	
	Copy-Item $source_path -Destination $dest_path
	
	
	
	# Replace exporter port and copy locally the required configuration before copy the entire files to  remote server
	$config_path=$sonar_full_path + "\\sonarConfiguration\\Sonard.dll.config"
	$destination_path = $sonar_full_path + "\\out"
	$file_content=(Get-Content -path $config_path -Raw)
	$string_to_search='ExporterPort" value="(.*)"'
	$file_content -match $string_to_search
	($file_content -replace $matches[1],$port) | Set-Content -Path $config_path
	Copy-Item $config_path -Destination $destination_path
}




# Deploy Sonar exporter on IDU server
# ==================================
# The command uses the Using scope modifier to identify a local variable in a remote command
if (Invoke-Command -Session $Session -ScriptBlock {Get-Service $Using:servicename -ErrorAction SilentlyContinue})
{
	Write-Host "sonard service already exists in IDU server"
	Write-Host "Only configuration will be copied and reloaded by the service"
	
	SetSonarConfig -port "9180" -folder_name "IDU"
	
	Write-Host "Copy only configuration files to remote server"
	Copy-Item $sonar_config2_file_path -Destination "C:\Sonar\out\Config\" -ToSession $Session
	Copy-Item $sonar_config_file_path -Destination "C:\Sonar\out\" -ToSession $Session
	
	# Reload new configuration by restart service
	Invoke-Command -Session $Session -ScriptBlock {sc.exe stop sonard}
	Start-Sleep -s 10
	Invoke-Command -Session $Session -ScriptBlock {sc.exe start sonard}
	
	Write-Host "sonard service successfully restarted in IDU server."
}
Else {
	Write-Host "sonard service not found in IDU server, start creating it"
	
	SetSonarConfig -port "9180"
	
	Write-Host "Copy all Sonar exporter files to remote server"
	Copy-Item $sonar_full_path -Destination "C:\Sonar\" -ToSession $Session -Recurse

	# Create Sonard service remotlly + start service
	Invoke-Command -Session $Session -ScriptBlock {sc.exe create sonard binpath=C:\Sonar\out\Sonard.exe start=auto obj=LocalSystem depend="WinRM"}
	Invoke-Command -Session $Session -ScriptBlock {sc.exe start sonard}
	Start-Sleep -s 10
	
	Write-Host "sonard service created successfully in IDU server."
}


# Deploy Sonar exporter on DB server
# ==================================
if (Invoke-Command -Session $Session_db -ScriptBlock {Get-Service $Using:servicename -ErrorAction SilentlyContinue})
{
	Write-Host "sonard service already exists in DB server"
	Write-Host "Only configuration will be copied and reloaded by the service"
	
	SetSonarConfig -port "9190" -folder_name "DB"
	
	Write-Host "Copy only configuration files to remote server"
	Copy-Item $sonar_config2_file_path -Destination "C:\Sonar\out\Config\" -ToSession $Session_db
	Copy-Item $sonar_config_file_path -Destination "C:\Sonar\out\" -ToSession $Session_db
	
	# Reload new configuration
	Invoke-Command -Session $Session_db -ScriptBlock {sc.exe stop sonard}
	Start-Sleep -s 10
	Invoke-Command -Session $Session_db -ScriptBlock {sc.exe start sonard}
	
	Write-Host "sonard service successfully restarted in DB server."
}
Else {	
	Write-Host "sonard service not found in DB server, start creating it"
	
	SetSonarConfig -port "9190" -folder_name "DB"
	
	Write-Host "Copy all Sonar exporter files to remote server"
	Copy-Item $sonar_full_path -Destination "C:\Sonar\" -ToSession $Session_db -Recurse

	Invoke-Command -Session $Session_db -ScriptBlock {sc.exe create sonard binpath=C:\Sonar\out\Sonard.exe start=auto obj=LocalSystem depend="WinRM"}
	Invoke-Command -Session $Session_db -ScriptBlock {sc.exe start sonard}
	Start-Sleep -s 10
	
	Write-Host "sonard service created successfully in DB server."
}

Remove-PSSession $Session
Remove-PSSession $Session_db