$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$db_ip=$args[2]
$sql_instance=$args[3]
# Remove double backslash since it's required in Jenkinsfile
$sql_instance = $sql_instance -replace '\\(.)', '$1'
$shadow_db_name=$args[4]
$domain_name=$args[5]


$sonar_full_path=$solr_pipeline_home + "\\Sonar"
$sonar_config_path=$sonar_full_path + "\\sonarConfiguration" 
 
# Create session for remote server for using it when I need to run command on remote server
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord


# Deploy Sonar exporter on IDU server
# ==================================
$Session = New-PSSession -ComputerName $idu_ip -Credential $Credential

Invoke-Command -Session $Session -ScriptBlock {
cmd.exe --% /c winrm set winrm/config/service @{AllowUnencrypted="true"}
}

$servicename = "sonard"

# The command uses the Using scope modifier to identify a local variable in a remote command
if (Invoke-Command -Session $Session -ScriptBlock {Get-Service $Using:servicename -ErrorAction SilentlyContinue})
{
	Write-Host "sonard service already exists in IDU server and will not be created again"
}
Else {
	Write-Host "sonard service not found in IDU server, start creating it"
	
	# Copy locally the required configuration before copy the entire folder+configuration to the remote server
	$source_path = $sonar_config_path + "\\IDU\\Sonar.config"
	$dest_path = $sonar_full_path + "\\out\\Config"
	
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
	
	Copy-Item $source_path -Destination $dest_path
	
	
	
	# Replace exporter port and copy locally the required configuration before copy the entire folder+configuration to the remote server
	$destination_path = $sonar_full_path + "\\out"
	$config_path=$sonar_full_path + "\\sonarConfiguration\\Sonard.dll.config"
	$file_content=(Get-Content -path $config_path -Raw)
	$string_to_search='ExporterPort" value="(.*)"'
	$file_content -match $string_to_search
	($file_content -replace $matches[1],"9180") | Set-Content -Path $config_path
	Copy-Item $config_path -Destination $destination_path
	
	#Copy Sonar folder to remote server
	Copy-Item $sonar_full_path -Destination "C:\Sonar\" -ToSession $Session -Recurse
	Start-Sleep -s 5

	# Create Sonard service remotlly + start service
	Invoke-Command -Session $Session -ScriptBlock {sc.exe create sonard binpath=C:\Sonar\out\Sonard.exe start=auto obj=LocalSystem depend="WinRM"}
	Invoke-Command -Session $Session -ScriptBlock {sc.exe start sonard}
	Start-Sleep -s 10
	
	Write-Host "sonard service created successfully in IDU server."
}


# Deploy Sonar exporter on DB server
# ==================================
$Session_db = New-PSSession -ComputerName $db_ip -Credential $Credential

Invoke-Command -Session $Session_db -ScriptBlock {
cmd.exe --% /c winrm set winrm/config/service @{AllowUnencrypted="true"}
}

if (Invoke-Command -Session $Session_db -ScriptBlock {Get-Service $Using:servicename -ErrorAction SilentlyContinue})
{
	Write-Host "sonard service already exists in DB server and will not be created again"
}
Else {
	Write-Host "sonard service not found in DB server, start creating it"
	
	$source_path = $sonar_config_path + "\\DB\\Sonar.config"
	$dest_path = $sonar_full_path + "\\out\\Config"
	Copy-Item $source_path -Destination $dest_path
	$destination_path = $sonar_full_path + "\\out"
	$config_path=$sonar_full_path + "\\sonarConfiguration\\Sonard.dll.config"
	$file_content=(Get-Content -path $config_path -Raw)
	$string_to_search='ExporterPort" value="(.*)"'
	$file_content -match $string_to_search
	($file_content -replace $matches[1],"9190") | Set-Content -Path $config_path
	Copy-Item $config_path -Destination $destination_path
	
	Copy-Item $sonar_full_path -Destination "C:\Sonar\" -ToSession $Session_db -Recurse
	Start-Sleep -s 5

	Invoke-Command -Session $Session_db -ScriptBlock {sc.exe create sonard binpath=C:\Sonar\out\Sonard.exe start=auto obj=LocalSystem depend="WinRM"}
	Invoke-Command -Session $Session_db -ScriptBlock {sc.exe start sonard}
	Start-Sleep -s 10
	
	Write-Host "sonard service created successfully in DB server."
}