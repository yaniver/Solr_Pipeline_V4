$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$domain_name=$args[2]
$events_eps_in_thousands=$args[3]
$sql_instance=$args[4]
$shadow_db_name=$args[5]

$servicename1 = "events_injector"
$events_injector_full_path=$solr_pipeline_home + "\\DBAdapter_EventsSimulator"

cd $events_injector_full_path
 
# Create session for remote server for using it when I need to run command on remote server
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session4 = New-PSSession -ComputerName $idu_ip -Credential $Credential

if (Invoke-Command -Session $Session4 -ScriptBlock {Get-Service $Using:servicename1 -ErrorAction SilentlyContinue})
{
	Write-Host "events injector service already exists in IDU server and won't be created"
}
Else {
	Write-Host "Start creating events injector service in IDU server"
	
	$source_path = $events_injector_full_path + "\\EndurenceVSBInjector.exe.config"
	$file_content=(Get-Content -path $source_path -Raw)
	#EPS_inThousands" value="1"/>
	$string_to_search='EPS_inThousands" value="(.*)"'
	$file_content -match $string_to_search
	($file_content -replace $matches[1],$events_eps_in_thousands) | Set-Content -Path $source_path
	
	$file_content=(Get-Content -path $source_path -Raw)
	#sqlShadowDBPrefix" value="L1648-DV1"/>
	$string_to_search='sqlShadowDBPrefix" value="(.*)"'
	$file_content -match $string_to_search
	($file_content -replace $matches[1],$shadow_db_name) | Set-Content -Path $source_path
	
	$file_content=(Get-Content -path $source_path -Raw)
	#sqlInstanceName" value="L1648-DV2\R2"
	$string_to_search='sqlInstanceName" value="(.*)"'
	$file_content -match $string_to_search
	$matches[1]=$matches[1] -replace '\\', '\\'
	($file_content -replace $matches[1],$sql_instance) | Set-Content -Path $source_path

	#Copy events injector to remote server
	Copy-Item $events_injector_full_path -Destination "C:\events_injector\" -ToSession $Session4 -Recurse

	# Create service
	Invoke-Command -Session $Session4 -ScriptBlock {
	sc.exe create $Using:servicename1 binpath= "C:\events_injector\EndurenceVSBInjector.exe" DisplayName= "Events_injector" start=auto obj=LocalSystem
	}

	Invoke-Command -Session $Session4 -ScriptBlock {
	sc.exe start $Using:servicename1
	}
}

Remove-PSSession $Session4