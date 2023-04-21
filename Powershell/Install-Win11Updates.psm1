# Requires administrative privileges
Function Install-Win11Updates {
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator."
    Break
}

# Print script status
function Print-Status {
    param($Message)
    Write-Host "$(Get-Date -Format 'HH:mm:ss') - $Message"
}

# Search, download and install updates
function Install-WindowsUpdates {
    $UpdateSession = New-Object -ComObject "Microsoft.Update.Session"
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

    $Timer = New-Object System.Timers.Timer
    $Timer.Interval = 60000 # <= 1 minute

    $Action = {
        Print-Status "Script is still running. Current task: $($script:CurrentTask)"
    }

    Register-ObjectEvent -InputObject $Timer -EventName Elapsed -Action $Action
    $Timer.Start()

    $script:CurrentTask = "Searching for updates"
    Print-Status $CurrentTask
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")

    if ($SearchResult.Updates.Count -eq 0) {
        $script:CurrentTask = "No updates available"
        Print-Status $CurrentTask
    } else {
        $UpdatesToDownload = New-Object -ComObject "Microsoft.Update.UpdateColl"

        foreach ($Update in $SearchResult.Updates) {
            $script:CurrentTask = "Downloading $($Update.Title)"
            Print-Status $CurrentTask
            $UpdatesToDownload.Add($Update) | Out-Null
        }

        $Downloader = $UpdateSession.CreateUpdateDownloader()
        $Downloader.Updates = $UpdatesToDownload
        $DownloadResult = $Downloader.Download()

        if ($DownloadResult.ResultCode -eq 2) {
            $UpdatesToInstall = New-Object -ComObject "Microsoft.Update.UpdateColl"

            foreach ($Update in $SearchResult.Updates) {
                if ($Update.IsDownloaded) {
                    $script:CurrentTask = "Installing $($Update.Title)"
                    Print-Status $CurrentTask
                    $UpdatesToInstall.Add($Update) | Out-Null
                }
            }

            $Installer = $UpdateSession.CreateUpdateInstaller()
            $Installer.Updates = $UpdatesToInstall
            $InstallResult = $Installer.Install()
        }
    }

    $Timer.Stop()
    $Timer.Dispose()
    Unregister-Event -SourceIdentifier ([System.Management.Automation.PSEvent]::Subscriber.SourceIdentifier)
}

# Run Install function
Install-WindowsUpdates



# Schedule a one-time reboot at midnight
$RebootTime = Get-Date -Hour 0 -Minute 0 -Second 0
if ($RebootTime -lt (Get-Date)) {
    $RebootTime = $RebootTime.AddDays(1)
}
$Trigger = New-ScheduledTaskTrigger -Once -At $RebootTime
$Action = New-ScheduledTaskAction -Execute "shutdown.exe" -Argument "/r /t 0"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries
$Principal = New-ScheduledTaskPrincipal -UserId "System" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "Windows 11 updates - one time midnight reboot" -Trigger $Trigger -Action $Action -Settings $Settings -Principal $Principal

Write-Host "Windows 11 updates have been installed. This system will reboot at midnight."
}