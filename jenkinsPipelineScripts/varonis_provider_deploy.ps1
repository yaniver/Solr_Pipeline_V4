$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$domain_name=$args[2]



$process_name = "Varonis.Infra.MetricsLauncher"
$Folder_destination = 'C:\Program Files\Varonis\DatAdvantage\TopologyManager\EventFlow\Influx\Latest'
$MetricLauncer_path = $Folder_destination + "\" + $process_name


$TimeOut = New-PSSessionOption -IdleTimeoutMSec (New-TimeSpan -Days 14).TotalMilliSeconds #Create Session opened for 3 days so events simulator won't be closed after default of 2 hours
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session = New-PSSession -ComputerName $idu_ip -Credential $Credential -Name Session
$Session2 = New-PSSession -ComputerName $idu_ip -Credential $Credential -Name Session2 -SessionOption $TimeOut



# Deploy Loki and Promtail on IDU server
# ======================================
# The command uses the Using scope modifier to identify a local variable in a remote command
if (Invoke-Command -Session $Session -ScriptBlock {Get-Process $Using:process_name -ErrorAction SilentlyContinue})
{
	Write-Host "Varonis.Infra.MetricsLauncher process with is InfluxDB already exists in IDU server"
}
Else {
	Write-Host "Varonis.Infra.MetricsLauncher process not found in IDU server, start creating this process and other processes required for Varonis metrics collection"
	
	Invoke-Command -Session $Session -ScriptBlock {
		if (Test-Path -Path $Using:Folder_destination) {
			Write-Host "Varonis metrics folder already exists and won't be created again."
		} else {
			Expand-Archive -LiteralPath 'C:\Program Files\Varonis\DatAdvantage\TopologyManager\EventFlow\Influx\Latest.zip' -DestinationPath $Using:Folder_destination
		}
	}

	# Session param set with Timeout param of 14 days so background process (-AsJob flag) won't be killed after 2 hours which is the default
	# Set to 14 days since I need all the time access to InfluxDB created by Varonis.Infra.MetricsLauncher.exe process in IDU server
	Invoke-Command -Session $Session2 -ScriptBlock {
		cmd.exe --% /c cd "C:\Program Files\Varonis\DatAdvantage\TopologyManager\EventFlow\Influx\Latest" & start Varonis.Infra.MetricsLauncher.exe -auto
	} -AsJob
	
	Write-Host "Varonis.Infra.MetricsLauncher+InfluxDB+Grafana processes were created successfully in IDU server."
}
