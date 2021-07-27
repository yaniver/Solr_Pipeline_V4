$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$db_ip=$args[2]
$domain_name=$args[3]
$lab_name=$args[4]


# Create sessions for remote servers for using it when I need to run command on remote server
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$global:Session = New-PSSession -ComputerName $idu_ip -Credential $Credential
$global:Session_db = New-PSSession -ComputerName $db_ip -Credential $Credential


function download_vip(){
	#$User = "varonis\<user name>"
	#$PWord = ConvertTo-SecureString -String "<password>" -AsPlainText -Force
	#$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
	$Credential = Get-Credential

	# Extract DA version (used for full DA installation OR getting DataStore VIP)
	$response = (Invoke-WebRequest -Uri 'https://ci.varonis.com/PortalMvc/Admin/Branches/GetBuildVersion?brnachName=V6.4%20Releases%20&scenariosSetsName=DataPlatform%20ATP' -Credential $Credential).Links.Href
	$string_to_search="Unstable\\(.*)"
	$response -match $string_to_search
	Write-Host "`nFull DA installation version: "$matches[1]
	$full_da_version = $matches[1]

	# Check if Last VIP already deployed and if not download it
	$dest = ".\DataStoreVIP"
	$da_version = $dest + "\last_da_version.txt"
	$da_version_fromfile = Get-Content $da_version
	if ([System.Version]$full_da_version -gt [System.Version]$da_version_fromfile)
	{
		# Extarct DataStore VIP Path
		$full_DA_installation_path = "\\varonis.com\global\builds\IDU\6.4-Rel\Unstable\" + $matches[1] + "\WebDAVersion.txt"
		$file_content = Get-Content -Path $full_DA_installation_path -Raw
		Write-Host "`nWebDAVersion.txt content containing VIP path: "$file_content
		$matches[0] = ""
		$matches[1] = ""
		$string_to_search="\\\\varonis.com\\global\\Engineering\\Releases\\DataStore\\(.*)vip"
		$file_content -match $string_to_search

		# Check if DataStore VIP exist in path
		if (Test-Path $matches[0])
		{
		  #then copy
		  $source = $matches[0] + "\DataStore.vip"
		  Copy-Item $source -Destination $dest
		  Set-Content $da_version $full_da_version
		}
	}
	
}

function update_hosts_file_with_solr_ips {
	param( [string]$lab_name )
	$clm_connection_string_encoded = Invoke-Command -Session $Session -ScriptBlock {Select-Xml -Path "C:\Program Files (x86)\Varonis\DatAdvantage\CollectionManager\Varonis.CollectionManager.Service.exe.config" -XPath '/configuration/connectionStrings/EncryptedData' | ForEach-Object { $_.Node.InnerXML }}
	$clm_connection_string_deencoded = Invoke-Command -ScriptBlock {.\CryptoVaronis\vrnsCrypto.ps1 $clm_connection_string_encoded}
	Write-Host "Collection manager connection string value  = " $clm_connection_string_deencoded

    $match = select-string 'SolrConnectionString" connectionString="Data Source=(.*);Initial' -inputobject $clm_connection_string_deencoded
    $match_value = $match.matches.groups[1].value
	$solr_urls = $match_value.Split(",")
	
    For ($i=0; $i -lt $solr_urls.Length; $i++) {
        echo $solr_urls[$i]
    }

	$solr_names = @(0..($solr_urls.Length-1))
	$string_to_search='http://(.*):3182/solr/'
	For ($i=0; $i -lt $solr_urls.Length; $i++) {
		$solr_urls[$i] -match $string_to_search
		$solr_names[$i] = $matches[1]
	}

	$solr_ips = @(0..($solr_urls.Length-1))
	For ($i=0; $i -lt $solr_names.Length; $i++) {
		$solr_name = $solr_names[$i]
		$solr_ips[$i] = Invoke-Command -Session $Session -ScriptBlock {
			(Test-Connection -comp $Using:solr_name -Count 1).ipv4address.ipaddressToString
		}
	}

	$lab_name_path = "C:\Windows\System32\drivers\etc" + "\" + $lab_name + ".txt"
	$host_file_path = "C:\Windows\System32\drivers\etc\hosts"
	$host_file_updated = "false"
	For ($i=0; $i -lt $solr_ips.Length; $i++) {
		$solr_ip = $solr_ips[$i]
		if (Test-Path -Path $lab_name_path) {
			if ($i -eq 0){
				Write-Host "host file was already been updated with solr IP's"
			}
		} else {
			$new_line = $solr_ips[$i] + "    " + $solr_names[$i]
			Add-Content $host_file_path $new_line
			Start-Sleep -s 1
			$host_file_updated = "true"
		}
	}
	if ($host_file_updated -eq "true"){
        Out-File -FilePath $lab_name_path
	}

}

# Done on the client for enabling remote connection to server
Set-Item WSMan:\localhost\Client\TrustedHosts -Value * -Force

Write-Host "Enable access to WinRM listener via HTTP in IDU server"
Invoke-Command -Session $Session -ScriptBlock {
	cmd.exe --% /c winrm set winrm/config/service @{AllowUnencrypted="true"}
}
Write-Host "Enable access to WinRM listener via HTTP in DB server"
Invoke-Command -Session $Session_db -ScriptBlock {
	cmd.exe --% /c winrm set winrm/config/service @{AllowUnencrypted="true"}
}

cd $solr_pipeline_home
update_hosts_file_with_solr_ips -lab_name $lab_name

download_vip

Remove-PSSession $Session
Remove-PSSession $Session_db