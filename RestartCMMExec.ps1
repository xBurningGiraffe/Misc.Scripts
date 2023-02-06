$CMMService = "cmmexec"
# Action for scheduled task
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-Command `"Get-Service -Name '$CMMService' | Where-Object { $_.Status -ne 'Running' } | ForEach-Object { $_.Start() }`""
# Trigger for scheduled task
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
# Task Settings
$Settings = New-ScheduledTaskSettingsSet
# $Principal = New-ScheduledTaskPrincipal -UserID "$env:UserDomain\$env:Username"
# Task Creation
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings
Register-ScheduledTask -TaskName 'RestartCMMExec' -InputObject $Task
