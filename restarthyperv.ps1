$HyperVs = @('VMMService','Hyper-V Host Compute Service')
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-Command `"Get-Service -Name '<ServiceName>' | Where-Object { $_.Status -ne 'Running' } | ForEach-Object { $_.Start() }`""
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
$Settings = New-ScheduledTaskSettingsSet
$Principal = New-ScheduledTaskPrincipal -UserID "$env:UserDomain\$env:Username" -LogonType Password
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal

Register-ScheduledTask -TaskName 'RestartService' -InputObject $Task