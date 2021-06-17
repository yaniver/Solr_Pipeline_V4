$solr_pipeline_home=$args[0]
$idu_ip=$args[1]
$domain_name=$args[2]

$rabbit_full_path=$solr_pipeline_home + "\\RabbitMQ_exporter"
$crypto_full_path_script=$solr_pipeline_home + "\\CryptoVaronis\\vrnsCrypto.ps1"

cd $rabbit_full_path
 
# Create session for remote server for using it when I need to run command on remote server
$User = $domain_name + "\Administrator"
$PWord = ConvertTo-SecureString -String "p@ssword1" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Session2 = New-PSSession -ComputerName $idu_ip -Credential $Credential
$Session3 = New-PSSession -ComputerName $idu_ip -Credential $Credential

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
Copy-Item $rabbit_full_path -Destination "C:\RabbitMQ_exporter\" -ToSession $Session3 -Recurse

# Fail to export metrics so need to be done manually
#Invoke-Command -Session $Session3 -ScriptBlock {
#cmd.exe --% /c C:\RabbitMQ_exporter\rabbitmq_exporter.exe  -config-file config.example.json
#} -AsJob



$file_content=(Get-Content -path $source_path -Raw)
$string_to_search='publish_port": "(.*)",'
$file_content -match $string_to_search
($file_content -replace $matches[1],"9418") | Set-Content -Path $source_path

$file_content=(Get-Content -path $source_path -Raw)
$string_to_search='include_queues": "(.*)",'
$file_content -match $string_to_search
($file_content -replace $matches[1],"enricher") | Set-Content -Path $source_path

#Copy RabbitMQ exporter folder to remote server
Copy-Item $rabbit_full_path -Destination "C:\RabbitMQ_exporter2\" -ToSession $Session2 -Recurse

# Fail to export metrics so need to be done manually
#Invoke-Command -Session $Session2 -ScriptBlock {
#cmd.exe --% /c C:\RabbitMQ_exporter2\rabbitmq_exporter.exe  -config-file config.example.json
#} -AsJob

# Another option to run exporter but also fail to export metrics
# WMIC /NODE:"10.10.193.88" /user:"L1648\Administrator" /password:"p@ssword1" process call create "C:\RabbitMQ_exporter2\rabbitmq_exporter.exe -config-file config.example.json"

Remove-PSSession $Session2
Remove-PSSession $Session3