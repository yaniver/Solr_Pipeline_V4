$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$db_ip=$args[2]
$domain_name=$args[3]


# Create sessions for remote servers for using it when I need to run command on remote server
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session = New-PSSession -ComputerName $idu_ip -Credential $Credential
$Session_db = New-PSSession -ComputerName $db_ip -Credential $Credential


Write-Host "Enable access to WinRM listener via HTTP in IDU server"
Invoke-Command -Session $Session -ScriptBlock {
	cmd.exe --% /c winrm set winrm/config/service @{AllowUnencrypted="true"}
}
Write-Host "Enable access to WinRM listener via HTTP in DB server"
Invoke-Command -Session $Session_db -ScriptBlock {
	cmd.exe --% /c winrm set winrm/config/service @{AllowUnencrypted="true"}
}

$clm_connection_string_encoded = Invoke-Command -Session $Session -ScriptBlock {Select-Xml -Path "C:\Program Files (x86)\Varonis\DatAdvantage\CollectionManager\Varonis.CollectionManager.Service.exe.config" -XPath '/configuration/connectionStrings/EncryptedData' | ForEach-Object { $_.Node.InnerXML }}
$clm_connection_string_deencoded = Invoke-Command -ScriptBlock {..\CryptoVaronis\vrnsCrypto.ps1 $clm_connection_string_encoded}
Write-Host "Collection manager connection string value  = " $clm_connection_string_deencoded

Remove-PSSession $Session
Remove-PSSession $Session_db