function LDAPSearch {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LDAPQuery
    )

    # Check if the $LDAPQuery is not provided or empty, and display a usage message if true
    if (-not $LDAPQuery) {
        ShowUsage
        return
    }

    $PDC = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner.Name
    $DN = ([adsi]'').distinguishedName

    $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$PDC/$DN")

    $DirectorySearcher = New-Object System.DirectoryServices.DirectorySearcher($DirectoryEntry, $LDAPQuery)

    return $DirectorySearcher.FindAll()
}

function ShowUsage {
    Write-Host "Usage: LDAPSearch -LDAPQuery <LDAP query>"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "    LDAPSearch -LDAPQuery '(objectClass=user)'"
}

# Example usage message will automatically show up if $LDAPQuery is not provided
