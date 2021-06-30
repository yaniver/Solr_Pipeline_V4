$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$domain_name=$args[2]
$events_eps_in_thousands=$args[3]
$sql_instance=$args[4]
$shadow_db_name=$args[5]

$process_name = "EndurenceVSBInjector"
$events_injector_full_path=$solr_pipeline_home + "\\DBAdapter_EventsSimulator"

cd $events_injector_full_path
 
# Create session for remote server for using it when I need to run command on remote server
$TimeOut = New-PSSessionOption -IdleTimeoutMSec (New-TimeSpan -Days 3).TotalMilliSeconds #Create Session opened for 3 days so events simulator won't be closed after default of 2 hours
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session4 = New-PSSession -ComputerName $idu_ip -Credential $Credential -Name Session4 -SessionOption $TimeOut

if (Invoke-Command -Session $Session4 -ScriptBlock {Get-Process $Using:process_name -ErrorAction SilentlyContinue})
{
	Write-Host "events injector process already exists in IDU server and won't be created"
}
Else {
	Write-Host "Start creating events injector process in IDU server"
	
	$source_path = $events_injector_full_path + "\\EndurenceVSBInjector.exe.config"
	$file_content=(Get-Content -path $source_path -Raw)
	#EPS_inThousands" value="1"/>
	$string_to_search='EPS_in(.*)"'
	$file_content -match $string_to_search
	$value_to_replace = 'Thousands" value="' + $events_eps_in_thousands
	($file_content -replace $matches[1],$value_to_replace) | Set-Content -Path $source_path
	
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

	$source_folder_only_folder_content = $events_injector_full_path + "\*"
	#Copy events injector to remote server
	Copy-Item $source_folder_only_folder_content -Destination "C:\events_injector\" -ToSession $Session4 -Recurse -Force
	
	# Session4 param set with Timeout param of 3 days so background process (-AsJob flag) won't be killed after 2 hours which is the default
	Invoke-Command -Session $Session4 -ScriptBlock {
	cmd.exe --% /c C:\events_injector\EndurenceVSBInjector.exe
	} -AsJob
}

# Not removing Session4 since otherwise the events simulator process will be killed and I want to kill it only in clean.ps1 script
# Remove-PSSession $Session4