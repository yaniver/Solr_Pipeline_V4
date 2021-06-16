if ($env:Processor_Architecture -ne "x86")  
{ 
    write-warning 'Launching x86 PowerShell'
    &"$env:windir\syswow64\windowspowershell\v1.0\powershell.exe" -noninteractive -noprofile -executionpolicy bypass -Command "C:\Solr_Pipeline_V4\CryptoVaronis\vrnsCrypto.ps1 $($args[0])"
    exit
}

add-type @"
using System;
using System.Runtime.InteropServices;
namespace VRNS {
    public class Crypto {
        [DllImport(@"C:\Solr_Pipeline_V4\CryptoVaronis\Crypto\VrnsCrypto.dll", EntryPoint = "CryptoDecrypt", CharSet = CharSet.Unicode, SetLastError = true, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr DecryptWithMachineKey([MarshalAs(UnmanagedType.LPTStr)] string cipherText);
       
        public static string  Decrypt(string txt) {
            var result = DecryptWithMachineKey(txt);
            return System.Runtime.InteropServices.Marshal.PtrToStringAuto(result);
        }
    }
}
"@

$res = [VRNS.Crypto]::Decrypt($args[0])
Write-Host $res
# $res | Out-File -FilePath c:\rabbit_connection_string_decoded.txt