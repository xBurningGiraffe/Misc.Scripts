$HyperVs = @('VMMService','Hyper-V Host Compute Service')

foreach ($HyperV in $HyperVs) {
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-Command `"Get-Service -Name '$HyperV' | Where-Object { $_.Status -ne 'Running' } | ForEach-Object { $_.Start() }`""
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
$Settings = New-ScheduledTaskSettingsSet
# $Principal = New-ScheduledTaskPrincipal -UserID "$env:UserDomain\$env:Username"
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings
$CheckTask = (Get-ScheduledTask -TaskName 'RestartService')
if ($null -eq (Get-ScheduledTask -TaskName 'RestartService')) {
Register-ScheduledTask -TaskName 'RestartService' -InputObject $Task
}
}
