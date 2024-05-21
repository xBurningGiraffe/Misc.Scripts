function LDAPSearch {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LDAPQuery,
        
        [Parameter(Mandatory=$false)]
        [switch]$FindNestedGroups,
        
        [Parameter(Mandatory=$false)]
        [string]$TargetGroupDN,
        
        [Parameter(Mandatory=$false)]
        [switch]$ListUserAttributes
    )

    if (-not $LDAPQuery) {
        ShowUsage
        return
    }

    $PDC = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner.Name
    $DN = ([adsi]'').distinguishedName

    $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$PDC/$DN")
    $DirectorySearcher = New-Object System.DirectoryServices.DirectorySearcher($DirectoryEntry, $LDAPQuery)
    $results = $DirectorySearcher.FindAll()

    if ($FindNestedGroups -and $LDAPQuery -like '*objectClass=group*') {
        FindNestedGroups $results
    } elseif ($ListUserAttributes) {
        ListUserAttributes $results $TargetGroupDN
    } else {
        return $results
    }
}

function ListUserAttributes($groups, $targetGroupDN) {
    foreach ($group in $groups) {
        if (!$targetGroupDN -or $group.Properties.distinguishedname[0] -eq $targetGroupDN) {
            $groupDN = $group.Properties.distinguishedname[0]
            $members = $group.Properties.member
            if ($members) {
                foreach ($member in $members) {
                    $memberSearcher = New-Object System.DirectoryServices.DirectorySearcher("LDAP://$member")
                    $memberSearcher.PropertiesToLoad.Add("name")
                    $memberSearcher.PropertiesToLoad.Add("mail")
                    $user = $memberSearcher.FindOne()
                    if ($user) {
                        $userName = $user.Properties["name"][0]
                        $userMail = $user.Properties["mail"][0]
                        Write-Host "User: $userName, Email: $userMail"
                    } else {
                        Write-Host "Member not found or cannot load properties: $member"
                    }
                }
            } else {
                Write-Host "No members in the group: $groupDN"
            }
        }
    }
}

function ShowUsage {
    Write-Host "Usage: LDAPSearch -LDAPQuery <LDAP query> [-FindNestedGroups] [-TargetGroupDN <group DN>] [-ListUserAttributes]"
    Write-Host "Examples:"
    Write-Host "    LDAPSearch -LDAPQuery '(objectClass=user)'"
    Write-Host "    LDAPSearch -LDAPQuery '(objectClass=group)' -FindNestedGroups"
    Write-Host "    LDAPSearch -LDAPQuery '(objectClass=group)' -TargetGroupDN 'CN=ExampleGroup,OU=Groups,DC=example,DC=com' -ListUserAttributes"
}
