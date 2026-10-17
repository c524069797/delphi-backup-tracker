param(
    [ValidateSet('build', 'test', 'run', 'open', 'status')]
    [string]$Action = 'status'
)

[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
chcp 65001 > $null
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$ide = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\bds.exe'
$project = Join-Path $PSScriptRoot 'BackupTracker.dproj'

function Get-ProjectExecutable([string]$Path) {
    $settings = [xml][IO.File]::ReadAllText($Path)
    $root = "/*[local-name()='Project']/*[local-name()='PropertyGroup'][1]"
    $platform = $settings.SelectSingleNode($root + "/*[local-name()='Platform']").InnerText
    $config = $settings.SelectSingleNode($root + "/*[local-name()='Config']").InnerText
    if ($platform -notin @('Win32', 'Win64') -or $config -notin @('Debug', 'Release')) {
        throw 'Unsupported default platform or configuration in the project.'
    }
    $name = [IO.Path]::GetFileNameWithoutExtension($Path)
    return Join-Path $PSScriptRoot ($platform + '\' + $config + '\' + $name + '.exe')
}

$executable = Get-ProjectExecutable $project

function Start-DesktopTask([string]$Name, [string]$Program, [string]$Arguments) {
    $existing = Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
    if ($existing -and $existing.State -eq 'Running') {
        throw "Task $Name is already running. Wait for it to finish."
    }
    $parameters = @{ Execute = $Program; WorkingDirectory = $PSScriptRoot }
    if (![string]::IsNullOrWhiteSpace($Arguments)) { $parameters.Argument = $Arguments }
    $taskAction = New-ScheduledTaskAction @parameters
    $principal = New-ScheduledTaskPrincipal `
        -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) `
        -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
    Register-ScheduledTask -TaskName $Name -Action $taskAction `
        -Principal $principal -Settings $settings -Force | Out-Null
    Start-ScheduledTask -TaskName $Name
}

try {
    if ($Action -eq 'status') {
        [pscustomobject]@{
            Project = $project
            Built = Test-Path -LiteralPath $executable
            Processes = @(Get-Process BackupTracker -ErrorAction SilentlyContinue |
                Select-Object Id, SessionId, StartTime)
        } | ConvertTo-Json -Depth 3
        exit 0
    }
    if ($Action -eq 'open') {
        Start-DesktopTask 'Codex-BackupTracker-Open' "$env:WINDIR\explorer.exe" ('"' + $project + '"')
        Write-Output 'Project opening on the Windows desktop.'
        exit 0
    }
    if ($Action -eq 'run') {
        if (!(Test-Path -LiteralPath $executable)) {
            throw 'BackupTracker.exe does not exist. Build the project first.'
        }
        if (Get-Process BackupTracker -ErrorAction SilentlyContinue) {
            Write-Output 'BackupTracker is already running.'
        } else {
            Start-DesktopTask 'Codex-BackupTracker-Run' $executable ''
            Start-Sleep -Seconds 2
            if (!(Get-Process BackupTracker -ErrorAction SilentlyContinue)) {
                throw 'BackupTracker exited during startup.'
            }
            Write-Output 'BackupTracker is running on the Windows desktop.'
        }
        exit 0
    }

    $name = if ($Action -eq 'test') { 'BackupTrackerTests' } else { 'BackupTracker' }
    if ($Action -eq 'build' -and (Get-Process BackupTracker -ErrorAction SilentlyContinue)) {
        throw 'Close BackupTracker before rebuilding so the executable can be replaced.'
    }
    $project = Join-Path $PSScriptRoot ($name + '.dproj')
    $executable = Get-ProjectExecutable $project
    $logDirectory = Join-Path $PSScriptRoot '.logs'
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    $log = Join-Path $logDirectory ($name + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.err')
    $taskName = 'Codex-BackupTracker-' + $Action
    $started = Get-Date
    Start-DesktopTask $taskName $ide ('"' + $project + '" -b -o"' + $log + '" -ns')
    Write-Output ('Building ' + $name + ' through the Delphi IDE...')
    $logText = ''
    while ($true) {
        if (Test-Path -LiteralPath $log) { $logText = [IO.File]::ReadAllText($log) }
        if ($logText -match '(?m)^(Success|Failed)\r?$') { break }
        if ((Get-ScheduledTask -TaskName $taskName).State -ne 'Running') { break }
        if (((Get-Date) - $started).TotalMinutes -gt 5) {
            throw 'Build has not finished. Check the Delphi window for a prompt; the IDE was left open.'
        }
        Start-Sleep -Seconds 2
    }
    if ($logText) { Write-Output $logText }
    # The IDE can remain running after reporting a completed automatic build.
    # Stop only this script's automatic build task, preserving the user's IDE.
    if ($logText -match '(?m)^(Success|Failed)\r?$' -and
        (Get-ScheduledTask -TaskName $taskName).State -eq 'Running') {
        Stop-ScheduledTask -TaskName $taskName
    }
    if ($logText -notmatch '(?m)^Success\r?$' -or
        !(Test-Path -LiteralPath $executable) -or
        (Get-Item -LiteralPath $executable).LastWriteTime -lt $started) {
        throw "Build did not produce a fresh executable. Check Delphi and $log."
    }
    if ($Action -eq 'test') {
        & $executable
        if ($LASTEXITCODE -ne 0) { throw "Tests failed with exit code $LASTEXITCODE." }
    }
    Write-Output ('Ready: ' + $executable)
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
