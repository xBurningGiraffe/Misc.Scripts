<#
.SYNOPSIS
Invoke-DnsTest runs a Python script to test the resolution speed of a domain using a specific DNS server.

.DESCRIPTION
The function accepts parameters for the DNS servers and the domain to test. It then calls a Python script to perform the test and display the results.

.PARAMETER DnsServers
Specifies the DNS servers to test. Multiple DNS servers can be specified as a comma-separated list.

.PARAMETER Domain
Specifies the domain to resolve.

.EXAMPLE
Invoke-DnsTest -DnsServers "208.67.222.222,208.67.220.220" -Domain "google.com"

This example tests the resolution speed of google.com using the specified DNS servers.

.NOTES
File Name      : Invoke-DnsTest.ps1
Author         : OpenAI
Prerequisite   : Python and the dns.resolver module
Copyright 2023 : OpenAI
#>

function Invoke-DnsTest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, HelpMessage="Specify DNS servers to test as a comma-separated list.")]
        [string]$DnsServers,

        [Parameter(Mandatory=$true, HelpMessage="Specify the domain to resolve.")]
        [string]$Domain
    )
    
    try {
        # Call the Python script with the provided parameters
        $PythonScript = "c:\users\cfont\onedrive\documents\scripts\python\dnstest.py"
        $output = python $PythonScript $DnsServers $Domain
        Write-Output $output
    }
    catch {
        Write-Error "Failed to execute the Python script. Details: $_"
    }
}

# Display the help information if the script is run without any parameters
if ($args.Length -eq 0) {
    Get-Help Invoke-DnsTest -Detailed
    exit
}

# Call the function with the provided arguments
Invoke-DnsTest @args
