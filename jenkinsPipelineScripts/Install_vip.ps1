$da_version="8.7" #$args[0]
Import-Module “C:\Program Files (x86)\Varonis\DatAdvantage\Management Console\Varonis.Management.Automation.dll”
$global:path = "C:\DownloadVIP\DataStoreVIP\" + $da_version
$global:remote_vm = "172.16.2.67"

function Deploy_DataStoreVIPPackFile{
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


    # Copy DataStore VIP Pack file from share folder to local folder --> C:\DownloadVIP\DataStoreVIP\$da_version
    If(!(test-path $path))
    {
	    New-Item -ItemType Directory -Force -Path $path
    }
    $vip_source = "\\" + $remote_vm + "\DataStoreVIP\" + $da_version + "\DataStore_pack.vip"
    $txt_source = "\\" + $remote_vm + "\DataStoreVIP\" + $da_version + "\last_da_version.txt"
    Copy-Item $vip_source $path
    Copy-Item $txt_source $path


    # Deploy DataStore VIP Pack
    $vipPack_path = $path + "\DataStore_pack.vip"
    $PackID = Register-Package -Path $vipPack_path
    $FullUserName =$env:UserDomain+'.com\Administrator' 
    $sqlDefaultCred = New-VaronisCredential -Username “sa-lab” -Password “p@ssword1” -Type Sql 
    $hostDefaultCred = New-VaronisCredential -Username $FullUserName -Password “p@ssword1”
    $JobIdsarr = Set-Pack -PackId $PackID -DefaultSqlCredentials $sqlDefaultCred  -DefaultFSCredentials $hostDefaultCred
}


$txt_source = "\\" + $remote_vm + "\DataStoreVIP\" + $da_version + "\last_da_version.txt"
$remote_da_full_version = Get-Content $txt_source
$da_full_version_filename = $path + "\last_da_version.txt"
if (Test-Path $da_full_version_filename){
    $da_full_version = Get-Content $da_full_version_filename
    Write-Host "Remote DA full version: "$remote_da_full_version
    Write-Host "Local DA full version(empty if no version file found): "$da_full_version

    if ([System.Version]$remote_da_full_version -gt [System.Version]$da_full_version)
    {
        Deploy_DataStoreVIPPackFile
    }
} else { # Deploy VIP_Pack file since no VIP_Pack file installed yet
    Deploy_DataStoreVIPPackFile
}
		

