$da_version = $args[0] #'8.7'
$global:online_vm = $args[1] #'172.16.2.67'
$idu_ip = $args[2] #'10.10.193.88'
$domain_name = $args[3] #'L1648'
$enable_enricher = 'True' #$args[4]
$global:path = "C:\DownloadVIP\DataStoreVIP\" + $da_version


# This function executed on the IDU Server that come with Varonis.Management.Automation.dll module
function Deploy_DataStoreVIPPackFile{
	Import-Module “C:\Program Files (x86)\Varonis\DatAdvantage\Management Console\Varonis.Management.Automation.dll”
	
	$timeout = New-TimeSpan -Seconds 480
	$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$connectionSucceed = 0
	do {
		try{
		   $IduOut = Connect-Idu
		   if($IduOut -contains 'Succeed' -or $IduOut -ccontains 'Connection unchanged'){
				Write-Host $IduOut
				$connectionSucceed = 1
		   }
		   Write-Host 'success connect to IDU'
		}
		catch{
			Write-Warning $Error[0]
			Start-Sleep -Seconds 15
		}
	} while ($stopwatch.elapsed -lt $timeout -and $connectionSucceed -eq 0)


	# Copy DataStore VIP Pack file from share folder to local IDU folder --> C:\DownloadVIP\DataStoreVIP\$da_version
	If(!(test-path $Using:path))
	{
		New-Item -ItemType Directory -Force -Path $Using:path
        Write-Host "VIP Pack was not deployed until now by automation so creating a new folder for the new downloaded VIP"
	}

	# Deploy DataStore VIP Pack
	$vipPack_path = "\\localhost\Share\DataStore_pack.vip"
	$PackID = Register-Package -Path $vipPack_path
	$FullUserName =$env:UserDomain+'.com\Administrator' 
	$sqlDefaultCred = New-VaronisCredential -Username “sa-lab” -Password “p@ssword1” -Type Sql 
	$hostDefaultCred = New-VaronisCredential -Username $FullUserName -Password “p@ssword1”
	$JobIdsarr = Set-Pack -PackId $PackID -DefaultSqlCredentials $sqlDefaultCred  -DefaultFSCredentials $hostDefaultCred

}






$first_day_of_sprint = '01-Aug-21'
$first_day_of_sprint_dateType = [datetime]::parseexact($first_day_of_sprint, 'dd-MMM-yy', $null)
$sprint_firstDay_list = New-Object Collections.Generic.List[String]

$next_sprint_first_day=$first_day_of_sprint_dateType.AddDays(21)
$sprint_firstDay_list.Add($next_sprint_first_day.ToString('MM/dd/yyyy'))
for ($i=0; $i -lt 500; $i++)
{
    $next_sprint_first_day = $next_sprint_first_day.AddDays(21)
    #echo $next_sprint_first_day
    $date_as_string = $next_sprint_first_day.ToString('MM/dd/yyyy')
    $sprint_firstDay_list.Add($date_as_string)
}

$today_date = (get-date).ToString('MM/dd/yyyy')
#echo $today_date
for ($i=0; $i -lt 500; $i++)
{
    #echo $sprint_firstDay_list[$i]
    if ($today_date -eq $sprint_firstDay_list[$i])
    {
		Write-Host "==================================================================="
        Write-Host $today_date " equal " $sprint_firstDay_list[$i] " - Start deploy new VIP Pack since new Sprint started"
		Write-Host "==================================================================="
		
		$User = $domain_name + "\Administrator"
		$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
		$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
		$global:Session = New-PSSession -ComputerName $idu_ip -Credential $Credential
		$global:Session2 = New-PSSession -ComputerName $idu_ip -Credential $Credential
		$global:Session3 = New-PSSession -ComputerName $idu_ip -Credential $Credential
		
		$txt_source = "\\" + $online_vm + "\DataStoreVIP\" + $da_version + "\last_da_version.txt"
		$remote_da_full_version = Get-Content $txt_source

		$deploy_required = Invoke-Command -Session $Session -ScriptBlock {
			$da_full_version_filename = $Using:path + "\last_da_version.txt"
			if (Test-Path $da_full_version_filename){
				$da_full_version = Get-Content $da_full_version_filename
				Write-Host "Remote DA full version: "$Using:remote_da_full_version
				Write-Host "Local DA full version(empty if no version file found): "$da_full_version

				if ([System.Version]$Using:remote_da_full_version -gt [System.Version]$da_full_version)
				{
					Write-Host "Deploy VIP"
					$required = "True"
					$required #return value of this function that will be saved in $deploy_required
				} 
				else {
					Write-Host "Remote DA version is not bigger then IDU version so VIP Pack won't be installed"
				}
			} 
			else # Deploy VIP_Pack file since no VIP_Pack file installed yet
			{
				Write-Host "Deploy VIP"
				$required = "True"
				$required
			}
		}

		Write-host "deploy_required = "$deploy_required
		if ($deploy_required -eq "True")
		{
			$vip_source = "\\" + $online_vm + "\DataStoreVIP\" + $da_version + "\DataStore_pack.vip"
			$txt_source = "\\" + $online_vm + "\DataStoreVIP\" + $da_version + "\last_da_version.txt"
			Copy-Item $vip_source "\\10.10.193.88\Share"
			Copy-Item $txt_source "\\10.10.193.88\Share"

			Invoke-Command -Session $Session2 -ScriptBlock ${function:Deploy_DataStoreVIPPackFile}
		}

		Invoke-Command -Session $Session3 -ScriptBlock{
			# DBAdapter+SqlExtractor services are not needed when working with Enricher
			if ($enable_enricher -eq "True")
			{
				Write-Host "Enable Enricher service and disable DBAdapter+SqlExtractor services"
				Set-Service -Name Varonis.DBAdapter.Consumer -StartupType Disabled
				Set-Service -Name Varonis.DBAdapter.Consumer -Status Stopped -PassThru
				Set-Service -Name Varonis.DBAdapter.Loader -StartupType Disabled
				Set-Service -Name Varonis.DBAdapter.Loader -Status Stopped -PassThru
				Set-Service -Name Varonis.SqlExtractor.Service -StartupType Disabled
				Set-Service -Name Varonis.SqlExtractor.Service -Status Stopped -PassThru

				# Enable Enricher through configuration change and restart Enricher service
				$source_path = "C:\\Program Files (x86)\\Varonis\\DatAdvantage\\CifsEnricher\\Varonis.Enricher.Cifs.Service.exe.config"
				$file_content=(Get-Content -path $source_path -Raw)
				$string_to_search="<value(.*)/value>"
				$file_content -match $string_to_search
				($file_content -replace $matches[1],">True<") | Set-Content -Path $source_path
				Set-Service -Name Varonis.Enricher.Cifs.Service -StartupType Automatic
				Set-Service -Name Varonis.Enricher.Cifs.Service -Status Stopped -PassThru    
				Set-Service -Name Varonis.Enricher.Cifs.Service -Status Running -PassThru 
			}
			else
			{
				Write-Host "Disable Enricher service and Enable DBAdapter+SqlExtractor services"
				Set-Service -Name Varonis.Enricher.Cifs.Service -StartupType Disabled
				Set-Service -Name Varonis.Enricher.Cifs.Service -Status Stopped -PassThru

				Set-Service -Name Varonis.DBAdapter.Consumer -StartupType Automatic
				Set-Service -Name Varonis.DBAdapter.Consumer -Status Running -PassThru
				Set-Service -Name Varonis.DBAdapter.Loader -StartupType Automatic
				Set-Service -Name Varonis.DBAdapter.Loader -Status Running -PassThru
				Set-Service -Name Varonis.SqlExtractor.Service -StartupType Automatic
				Set-Service -Name Varonis.SqlExtractor.Service -Status Running -PassThru
			}
		}


		Remove-PSSession $Session
		Remove-PSSession $Session2
		Remove-PSSession $Session3
    }
}








