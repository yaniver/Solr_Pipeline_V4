$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$db_ip=$args[2]
$sql_instance=$args[3]
$shadow_db_name=$args[4]
$domain_name=$args[5]

 
# Create session for remote server for using it when I need to run command on remote server
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session = New-PSSession -ComputerName $idu_ip -Credential $Credential

Invoke-Command -Session $Session -ScriptBlock {
cmd.exe --% /c winrm set winrm/config/service @{AllowUnencrypted="true"}
}


$servicename = “sonard”
if (Get-Service $servicename -ErrorAction SilentlyContinue)
{
	Write-Host "$servicename already exists and will not be created again"
}
Else {
	Write-Host ” $servicename not found, start creating it”
	
	# Copy locally the required configuration before copy the entire folder+configuration to the remote server 
	Copy-Item "C:\Solr_Pipeline_V2\Sonar\sonarConfiguration\IDU\Sonar.config" -Destination "C:\Solr_Pipeline_V2\Sonar\out\Config"
	#Copy Sonar folder to remote server
	$sonar_full_path=$solr_pipeline_home + "\\Sonar\\"
	Copy-Item $sonar_full_path -Destination "C:\Sonar\" -ToSession $Session -Recurse
	Start-Sleep -s 5

	# Create Sonard service remotlly + start service
	Invoke-Command -Session $Session -ScriptBlock {sc.exe create sonard binpath=C:\Sonar\out\Sonard.exe start=auto obj=LocalSystem depend="WinRM"}
	Invoke-Command -Session $Session -ScriptBlock {sc.exe start sonard}
	Start-Sleep -s 10
	
	Write-Host "$servicename created successfully."
	Write-Host "Service name -"
	Get-Service $servicename -ErrorAction SilentlyContinue
}