# RADERSec Client Onboarding Script
Function WelcomeBanner {
    Start-Sleep -m 200
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor DarkYellow
    Write-Host "===============================================================" -ForegroundColor Green
    Write-Host " RaderSec Operations " -ForegroundColor DarkYellow
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor DarkYellow
    Write-Host "===============================================================" -ForegroundColor Green
    Write-Host " NOTE: Run this with elevated privileges"
    OnboardOption
}

# Function for choosing onboard options


Function OnboardMenu {
    Write-Host "######     #    ######  ####### ######  # # #" -ForegroundColor Green
    Write-Host "#     #   # #   #     # #       #     # # # #" -ForegroundColor Green
    Write-Host "#     #  #   #  #     # #       #     # # # #" -ForegroundColor Green
    Write-Host "######  #     # #     # #####   ######       "        -ForegroundColor Green
    Write-Host "#   #   ####### #     # #       #   #   # # #" -ForegroundColor Green
    Write-Host "#    #  #     # #     # #       #    #  # # #" -ForegroundColor Green
    Write-Host "#     # #     # ######  ####### #     # # # #" -ForegroundColor Green
    Write-Host "_____________________________________________" -ForegroundColor Yellow
    Write-Host "RADERSEC OPERATIONS MENU" -ForegroundColor Green
    Write-Host "------------ General ------------"
    Write-Host "    [0] Powershell Module Installer"
    Write-Host "----------- Onboarding -----------"
    Write-Host "    [1] Full Client Onboard"
    Write-Host "    [2] Enable Organization Customization"
    Write-Host "    [3] Enable Organization-wide Auditing"
    Write-Host "    [4] Enable Litigation Hold"
    Write-Host "    [5] Enable Mailbox Auditing"
    Write-Host "    [6] Configure O365 Outbound Spam Policy"
    Write-Host "    [7] Configure O365 Anti-Spam Policy"
    Write-Host "    [8] Configure O365 Anti-Phish Policy"
    Write-Host "    [9] Configure O365 Anti-Malware Policy"
    Write-Host "    [10] Configure O365 Safe Attachments"
    Write-Host "    [11] Configure O365 Safe Links"
    Write-Host "    [12] Configure MFA Conditional Access Policy"
    Write-Host "    [13] Configure AIP Encryption Rule"
    Write-Host "    [14] Configure Phin bypass spam rule"
    Write-Host "    [15] Configure North-America Only Conditional Access Policy"
    Write-Host " "
    Write-Host "---------- Misc. Options ----------"
    Write-Host "    [P] PwnedUser Log Collection (BEC)"
    Write-Host "    [D] DMARC/DKIM setup (Azure DNS Only)"
    Write-Host " "
    Write-Host "------------- Quit --------------"
    Write-Host "    [Q] Quit"  
    Write-Host "---------------------------------"
}


# Function for executing onboard options
Function OnboardOption {
    Do {
        OnboardMenu
        $script:OnboardType = Read-Host -Prompt 'Please enter a selection from the menu (0 - 15, P, D, or Q) and press Enter'
        switch ($script:OnboardType){
            '0'{
                ModuleInstalls
            }
            '1'{
                Connect-ExchangeOnline 
                Connect-AzureAD 
                Connect-MsolService 
                Connect-AIPService
                Connect-IPPSSession
                FullOnboard
            }
            '2'{
                Connect-ExchangeOnline
                OrgCustomization
                OrgCustomizationCheck
                NullVariables
            }
            '3'{
                Connect-ExchangeOnline
                OrgAuditing
                NullVariables
            }
            '4'{
                Connect-MsolService
                Connect-ExchangeOnline
                LitHold
            
                NullVariables
            }
            '5'{
                Connect-ExchangeOnline
                Connect-MsolService
                MboxAudit
           
                NullVariables

            }
            '6'{
                Connect-ExchangeOnline
                Connect-IPPSSession
                O365OutboundSpam
           
                NullVariables
            }
            '7'{
                Connect-ExchangeOnline
                Connect-IPPSSession
                O365AntiSpam
                NullVariables
            }
            '8'{
                Connect-ExchangeOnline
                Connect-IPPSSession
                O365AntiPhish
                NullVariables
            }
            '9'{
                Connect-ExchangeOnline
                Connect-IPPSSession
                O365AntiMal
                NullVariables
            }
            '10'{
                Connect-ExchangeOnline
                Connect-IPPSSession
                O365SafeAttach
                NullVariables
            }
            '11'{
                Connect-ExchangeOnline
                Connect-IPPSession
                O365SafeLinks
                NullVariables
            }
            '12'{
                Connect-ExchangeOnline
                Connect-AzureAD
                MFAPolicy
                Disconnect-AzureAD
                NullVariables
            }
            '13'{
                Connect-ExchangeOnline
                Connect-AipService
                AIPPolicy
                NullVariables
            }
            '14'{
                Connect-ExchangeOnline
                PhinRule
                NullVariables
            }
            '15'{
                Connect-AzureAD
                NAOnlyPolicy
                Disconnect-AzureAD -Confirm:$false
            }
#            'L'{
#                Connect-ExchangeOnline
#               Connect-PartnerCenter
#                LicenseCheck
#            }
            'P'{
                PwnedUser
            }
            'D'{
                Connect-AzAccount
                Connect-ExchangeOnline
                Connect-AzureAD
            }
            'q'{
                Goodbye
            }
        }
    }
    until ($script:OnboardType -eq 'q')
}


#Function ReturnMenu {
#    if ($script:OnboardType -ne '1'){
#            $script:Return = Read-Host -Prompt "Return to Onboard Menu? [Y] or [N] "
#        switch ($script:Return){
#            'Y'{
#                OnboardMenu
#            }
#            'N'{
#                Write-Host "Exiting..."
#                Goodbye
#            }
#        }
        
#    }
#}

Function ModuleInstalls {
    $Modules = "ExchangeOnlineManagement","AzureAD","AIPService","MSOnline","PartnerCenter"
    foreach ($Module in $Modules){
        if ( ! ( Get-Module -Name "$Module" ) ) {
            Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
            Write-Host "Importing required Powershell modules..." -ForegroundColor "DarkYellow"
            Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
                Import-Module $Module
            } else {
                Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
                Write-Host "Installing required Powershell modules.." -ForegroundColor "DarkYellow"
                Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
                Install-Module $Module
            }
    }
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Required Powershell modules have been installed" -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}




Function FullOnboard {
    OrgCustomization
    OrgAuditing
    LitHold
    PhinRule
    MboxAudit
    OrgCustomizationCheck
    O365OutboundSpam
    O365AntiSpam
    O365AntiPhish
    O365AntiMal
    O365SafeAttach
    O365SafeLinks
    MFAPolicy
    AIPPolicy
    NAOnlyPolicy
    NullVariables
}


Function OrgCustomization {
$GetOrgCust = (Get-OrganizationConfig).IsDehydrated
if ($GetOrgCust -ne $True) {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Enabling Organization Customization..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Enable-OrganizationCustomization
} else {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Organization Customization is now enabled" -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    }
}

# Enable Org-Wide Auditing
Function OrgAuditing {
$CheckAuditing = Get-AdminAuditLogConfig | Format-List UnifiedAuditLogIngestionEnabled
$EnableAuditing = Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

if ($CheckAuditing -ne $True) {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Enabling Organization-Wide Auditing" -ForegroundColor "DarkYellow" 
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    $EnableAuditing
} else {
    $CheckAuditing
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Organization-wide auditing is now enabled" -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}
}


# Enable Litigation Hold for licensed users
Function LitHold {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Enabling litigation hold for all licensed users..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    $GetUsers = (Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox"}) 
    $Licenses = (Get-MsolUser | where {$_.IsLicensed -eq $true}).UserPrincipalName
    $LicensedUsers = $GetUsers.WindowsEmailAddress | Where-Object -FilterScript { $_ -in $Licenses}
    foreach ($LicensedUser in $LicensedUsers){
        Set-Mailbox -Identity $LicensedUser -LitigationHoldEnabled $True
    }
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Litigation hold is now enabled" -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}

Function PhinRule {
    $PhinRule = "Bypass Spam Filtering & SafeLinks (Phin)"
    $SenderIPs = "54.84.153.58","107.21.104.73","198.2.177.227"
    $BypassSpam = (Get-TransportRule).Name | Where-Object -FilterScript {$_ -eq $PhinRule}
    if ($BypassSpam -match $PhinRule) {
        Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
        Write-Host "Phin bypass spam filter rule already exists" -ForegroundColor "DarkYellow"
        Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
} else {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Creating Phin bypass spam filtering rule..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    New-TransportRule -Name $PhinRule -Priority 0 -SenderIpRanges $SenderIPs -SetAuditSeverity DoNotAudit -SetSCL -1 -SetHeaderName X-MS-Exchange-Organization-SkipSafeLinksProcessing -SetHeaderValue 1 -StopRuleProcessing $True
    Start-Sleep -Seconds 60
}
    $BypassSpam
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Phin bypass spam filter rule has been created" -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}


# Mailbox Auditing
Function MboxAudit {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Enabling mailbox auditing for all licensed users..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    $AuditUsers = $GetUsers.PrimarySmtpAddress
    foreach ($AuditUser in $AuditUsers){
        Set-Mailbox -Identity $_.PrimarySmtpAddress -AuditEnabled $true
    }
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Mailbox auditing is now enabled" -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}


# Add security@radersolutions.com to Threat Alerts
# Meh

# OrganizationCustomization Check 2
Function OrgCustomizationCheck {
if ($GetOrgCust -eq $False) {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Making sure Organization Customization is enabled..." -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Enable-OrganizationCustomization
} elseif ($GetOrgCustom -eq $True) {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Organization Customization is now enabled" -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
} else {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Enabling Organization Customization can take quite a while to propagate." -Foreground "Magenta"
    Write-Host "If you receive an error about organization customization in the next section, re-run this script in 24 hours" -Foreground "Magenta"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}
}

# Function for Outbound Spam Policy
Function O365OutboundSpam {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Editing Office365 Outbound Spam Policy..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    $Outbound = (Get-HostedOutboundSpamFilterPolicy).Name
    Set-HostedOutboundSpamFilterPolicy $Outbound -RecipientLimitExternalPerHour 400 -RecipientLimitInternalPerHour 800 -RecipientLimitPerDay 800 -ActionWhenThresholdReached Alert

    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Office365 Outbound Spam Policy configuration complete" -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}


# Function for Anti-Spam
Function O365AntiSpam {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Editing Office365 Anti-spam Policy..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    $Junk = "MoveToJmf"
    $Policy = (Get-HostedContentFilterPolicy).Name
    Set-HostedContentFilterPolicy $Policy -BulkThreshold 7 -HighConfidenceSpamAction $Junk -HighConfidencePhishAction Quarantine -PhishSpamAction $Junk -PhishZapEnable $true -QuarantineRetentionPeriod 30 -EnableRegionBlockList $true -RegionBlockList @{Add="CN","RU","IR","KP","TR","TW","BR","RO","CZ","JP"} -SpamAction $Junk -SpamZapEnabled $true -InlineSafetyTipsEnabled $true

    Write-Host "Office365 Anti-spam Policy configuration complete" -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}


# Default Anti-Phish Policy #
Function O365AntiPhish {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Editing Office365 AntiPhish Policy..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"

    $Policy = "Office365 AntiPhish Default"
    Set-AntiPhishPolicy -Identity $Policy -EnableOrganizationDomainsProtection $true -EnableMailboxIntelligence $true -EnableMailboxIntelligenceProtection $true -EnableSimilarUsersSafetyTips $True -MailboxIntelligenceProtectionAction Quarantine -EnableSpoofIntelligence $true -EnableViaTag $true -EnableUnauthenticatedSender $true -TargetedUserProtectionAction MoveToJmf -TargetedDomainProtectionAction MoveToJmf

    Write-Host "Office365 AntiPhish Policy configuration complete" -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}


# Default Anti-Malware Policy #\
Function O365AntiMal {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Configuring Office365 Anti-Malware Policy..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    $AntiMal = "Default"
    Set-MalwareFilterPolicy $AntiMal -EnableFileFilter $true -FileTypeAction "Quarantine" -ZapEnabled $true
# Error checking and printing relevant results?
# Write-Host -ForegroundColor "Green" $Color "Anti-Malware complete. Results: "
# $GetAM | Format-List

    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Office365 Anti-Malware Policy configuration complete" -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}


# Safe Attachments Policy
Function O365SafeAttach {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Creating Safe Attachments Policy" -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    $Domains = (Get-AcceptedDomain).Name
    $SafeAttach = "Safe Attachments"

    New-SafeAttachmentPolicy -Name $SafeAttach -Enable $true -Redirect $false -QuarantineTag AdminOnlyAccessPolicy
    New-SafeAttachmentRule -Name $SafeAttach -SafeAttachmentPolicy $SafeAttach -RecipientDomainIs $Domains

    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Safe Attachments policy has been created" -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}


# Safe Links Policy
Function O365SafeLinks {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Creating Safe Links Policy" -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    $SafeLinks = "Safe Links"
    $Domains = (Get-AcceptedDomain).Name
    New-SafeLinksPolicy -Name $SafeLinks -EnableSafeLinksForEmail $True -DeliverMessageAfterScan $True -DisableUrlRewrite $False -EnableForInternalSenders $True -EnableSafeLinksForTeams $True -EnableSafeLinksForOffice $True  -TrackClicks $False -AllowClickThrough $False
    New-SafeLinksRule -Name $SafeLinks -SafeLinksPolicy $SafeLinks -RecipientDomainIs $Domains    
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Safe Links policy has been created" -ForegroundColor "Green"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}


# Azure Conditional Access Policy ***Excluded users still need to be added after creation of policy
Function MFAPolicy {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Creating MFA Conditional Access Policy..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
# $ExcludedUsers = Read-Host "Add users to exclude from MFA policy (ex. rs, rsadmin, scanner, scan) "
    $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
    $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
    $conditions.Applications.IncludeApplications = "All"
    $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
    $conditions.Users.IncludeUsers = "All"
# $conditions.Users.ExcludeUsers = $ExcludedUsers
# $conditions.Users.ExcludeGroups = $ExcludeCAGroup.ObjectId
    $conditions.ClientAppTypes = "All"
    $controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
    $controls._Operator = "OR"
    $controls.BuiltInControls = @('MFA')
    $GetMFAPolicy = Get-AzureADMSConditionalAccessPolicy
    if ($GetMFAPolicy.DisplayName -notcontains "Require MFA"){
        Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
        Write-Host "Creating MFA Conditional Access Policy..." -ForegroundColor "DarkYellow"
        Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
        New-AzureADMSConditionalAccessPolicy -DisplayName "Require MFA" -State "enabledForReportingButNotEnforced" -Conditions $conditions -GrantControls $controls
}   elseif ($GetMFAPolicy.DisplayName -contains "Require MFA") {
        Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
        Write-Host "MFA Conditional Access Policy already exists" -ForegroundColor "DarkYellow"
        Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}   else {
        Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
        Write-Host "MFA Conditional Access Policy has been created..." -ForegroundColor "DarkYellow"
        Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}
}

# N.America Logins Only Policy
Function NAOnlyPolicy {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Creating N.America Logins Only Conditional Access Policy..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    # Creates NamedLocations Group
    $NALocations = "CA","US","MX"
    $NAPolicy = New-AzureADMSNamedLocationPolicy -OdataType "#microsoft.graph.countryNamedLocation" -DisplayName "North America" -CountriesAndRegions $NALocations -IncludeUnknownCountriesAndRegions $false
    $NAPolicy
    #Creates CA Policy
    $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
    $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
    $conditions.Applications.IncludeApplications = "all"
    $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
    $conditions.Users.IncludeUsers = "all"
    $conditions.Locations = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessLocationCondition
    $conditions.Locations.IncludeLocations = "All"
    $conditions.Locations.ExcludeLocations = $NAPolicy.Id
    $controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
    $controls._Operator = "OR"
    $controls.BuiltInControls = "block"
    New-AzureADMSConditionalAccessPolicy -DisplayName "Block logins outside North America" -State "enabledForReportingButNotEnforced" -Conditions $conditions -GrantControls $controls
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "N.America Logins Only Conditional Access Policy has been created." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}

#AIP Configuration
Function AIPPolicy {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Configuring AIP settings..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"

    $AzureRMS = Set-IrmConfiguration -AzureRMSLicensingEnabled $true
    $RMSEnable = Enable-Aadrm
    $RMS = Get-AadrmConfiguration
    $License = $RMS.LicensingIntranetDistributionPointUrl
    $AzureRMS
    $RMSEnable
    $RMS
    $License
    Set-IRMConfiguration -LicensingLocation $License
    Set-IRMConfiguration -InternalLicensingEnabled $true

    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Creating AIP email encryption rule..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    $CheckRMS = (Get-RMSTemplate).Name | Where-Object -FilterScript {$_ -eq "Encrypt"}
    $CheckRule = (Get-TransportRule).Name
    $Keywords = "securemail","encryptmail"
    if ($CheckRMS -ne "Encrypt"){
    do {
        $AzureRMS
        $RMSEnable
        $RMS
        $License
        Set-IRMConfiguration -LicensingLocation $License
        Set-IRMConfiguration -InternalLicensingEnabled $true
        Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Red"
        Write-Host "RMS Encryption Template not available yet. Verify that M365 Business Premium Licensing has been applied to the tenant."
        Write-Host ""
        Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Red"
        Start-Sleep -Seconds 60
    }until ($CheckRMS -eq "Encrypt")
    } elseif ($CheckRule -contains "Use Office365 Encryption") {
    Write-Host "'Use Office365 Encryption' rule already exists...check the mail flow rules in Exchange"
    }else {
    New-TransportRule -Name "Use Office365 Encryption" -ApplyRightsProtectionTemplate "Encrypt" -SentToScope NotInOrganization -SubjectOrBodyContainsWords  $Keywords -ExceptIfRecipientDomainIs "radersolutions.com" -Mode Enforce -Enabled $true
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "Email encryption rule has been created. AIP configuration is complete"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}
}

# Function LicenseCheck {
#    foreach ($Domain in $Domains){
#        $GetPartner = Get-PartnerCustomer -domain $Domain
#        $GetLicense = (Get-PartnerCustomerSubscribedSku -customerid $CustomerId)
#        if ($GetPartner.AllowDelegatedAccess -eq $true) {
#            $CustomerId = $GetPartner.CustomerId
#            Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
#            Write-Host "M365 Business Premium licensing status: "
#            Start-Sleep -Seconds 30
#            Get-PartnerCustomerSubscribedSku -customerid $CustomerId | Where-Object {$_.ProductName -match "Microsoft 365 Business Premium" -and $_.CapabilityStatus -match "Enable"}
#            Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
#        } elseif ($GetLicense.ProductName -notcontains "Microsoft 365 Business Premium") {
#            Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor Red
#            Write-Host "M365 Business Premium licensing not found. Current active licenses are: "
#            $GetLicense | Where-Object {$_.CapabilityStatus -match "Enabled" -and $_.ActiveUnits -ne "0"}
#            Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor Red
#        }

#        }
# }

Function PwnedUser {
    $HawkCheck = Get-Module -ListAvailable -Name Hawk
        if ($HawkCheck) {
            Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
            Write-Host "Checking for HAWK module..." -ForegroundColor "DarkYellow"
            Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
            $Pwned = Read-Host  'Enter the compromised user email address'
            Start-HawkUserInvestigation -UserPrincipalName $Pwned
        } else {
            Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
            Write-Host  "Starting Hawk User Investigation..."
            Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
            Set-ExecutionPolicy RemoteSigned -Confirm:$false
            Invoke-WebRequest -Uri https://raw.githubusercontent.com/T0pCyber/hawk/master/install.ps1 -OutFile .\hawkinstall.ps1
            Unblock-File -Path .\hawkinstall.ps1
            .\hawkinstall.ps1
        }
    }

Function DMARCDKIM {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host  "Setting up DKIM..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    $DNSDomain = Read-Host "Enter domain name:"
    $ResGrp = (Get-AzDnsZone | ?{$_.Name -match $DNSDomain})
    $GrpName = $ResGrp.ResourceGroupName
    $Zone = $ResGrp.Name
    $Selector = Get-DkimSigningConfig $DNSDomain
    $Selector1 = $Selector.Selector1CNAME
    $Selector2 = $Selector.Selector2CNAME
    $DKIM1 = New-AzDnsRecordConfig -Cname $Selector1
    $DKIM2 = New-AzDnsRecordConfig -Cname $Selector2

    New-AzDnsRecordSet -Name "selector1._domainkey" -RecordType CNAME -ResourceGroupName $GrpName -Ttl 3600 -ZoneName $Zone -DnsRecords $DKIM1

    New-AzDnsRecordSet -Name "selector2._domainkey" -RecordType CNAME -ResourceGroupName $GrpName -Ttl 3600 -ZoneName $Zone -DnsRecords $DKIM2


    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host  "DKIM keys have been published. DKIM may now be enabled. If you receive an error, try enabling DKIM again in 24 hours. "
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"

    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host  "Setting up DMARC..." -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"

    $DMARC = New-DnsRecordConfig -Value "v=DMARC1; p=quarantine; pct=100"

    New-AzDnsRecordSet -Name "_dmarc" -RecordType TXT -ResourceGroupName $GrpName -Ttl 3600 -ZoneName $Zone -DnsRecords $DMARC

    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host  "DMARC policy has been published in DNS records. You can verify this with https://dmarcanalyzer.com" -ForegroundColor "DarkYellow"
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
}

Function NullVariables {
$ClearVars = "GetUsers","Licenses","LicensedUsers","AuditUsers","Domains"
foreach ($ClearVar in $ClearVars) {
    Clear-Variable -Name $ClearVar -Scope script
}

}

# Function for disconnecting and exiting
Function Goodbye {
    Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor "Green"
    Write-Host "All actions are complete. Don't forget to complete these steps in the O365 online portal: " -ForegroundColor "DarkYellow"
    Write-Host "1. Add any excluded users to the MFA Conditional Access policy (https://portal.azure.com/#view/Microsoft_AAD_ConditionalAccess)" -ForegroundColor "Magenta"
    Write-Host "2. Add the 'security@radersolutions.com' address to following alerts: 'Email sending limit exceeded',Creation of a forwarding/redirect rule','User restricted from sending email','Tenant restricted from sending email'" -ForegroundColor "Magenta"
    Disconnect-ExchangeOnline -Confirm:$false -InformationAction Ignore -ErrorAction SilentlyContinue
    Disconnect-AipService
    Disconnect-AzureAD
    Disconnect-AzAccount
}


WelcomeBanner
