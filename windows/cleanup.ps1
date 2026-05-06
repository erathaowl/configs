param(
    [string]$Action,
    [string]$UserProfile,
    [string]$Task
)

###############################
# CONFIG
###############################
$script:EnableEventLogsChoice = $false
$script:CleanMgrProfile = 2504
$script:SDeletePath = "sdelete.exe"
$script:MinimalEventLogs = @("Application", "Security", "Setup", "System")
$script:CleanupPathTemplates = @(
    "%temp%\*",
    "{UserProfile}\AppData\Local\Temp\*",
    "{UserProfile}\AppData\Local\Microsoft\Terminal Server Client\Cache\*",
    "{UserProfile}\AppData\Local\Microsoft\Windows\Explorer\*",
    "{UserProfile}\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache\Cache_Data",
    "F:\Browsers\Brave\Default\Default\Cache"
)
$script:DriveInfoCache = @{}

###############################
# FUNCTIONS
###############################

function Get-ScriptPath {
    $scriptPath = $PSCommandPath
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        $scriptPath = $MyInvocation.PSCommandPath
    }
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        $scriptPath = $script:MyInvocation.MyCommand.Path
    }
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        throw "Unable to determine script path."
    }

    return $scriptPath
}

function Get-PowerShellExecutable {
    try {
        $currentProcess = Get-Process -Id $PID -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace($currentProcess.Path)) {
            return $currentProcess.Path
        }
    }
    catch {
        # Fall back to PATH lookup below.
    }

    $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshCommand) {
        return $pwshCommand.Source
    }

    return "powershell.exe"
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-Elevated {
    param(
        [string]$Action,
        [string]$UserProfile,
        [string]$Task
    )

    $scriptPath = Get-ScriptPath
    $powerShellPath = Get-PowerShellExecutable

    $psi = [System.Diagnostics.ProcessStartInfo]::new($powerShellPath)
    $psi.UseShellExecute = $true
    $psi.Verb = "runas"

    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $scriptPath
    )

    if (-not [string]::IsNullOrWhiteSpace($Action)) {
        $arguments += @("-Action", $Action)
    }
    if (-not [string]::IsNullOrWhiteSpace($UserProfile)) {
        $arguments += @("-UserProfile", $UserProfile)
    }
    if (-not [string]::IsNullOrWhiteSpace($Task)) {
        $arguments += @("-Task", $Task)
    }

    foreach ($argument in $arguments) {
        [void]$psi.ArgumentList.Add($argument)
    }

    try {
        Write-Host "Restarting script with administrative privileges..."
        [void][System.Diagnostics.Process]::Start($psi)
        exit
    }
    catch {
        Write-Warning "Unable to restart script as administrator. Error: $($_.Exception.Message)"
        exit 1
    }
}

function Ensure-Elevated {
    param(
        [string]$Action,
        [string]$UserProfile,
        [string]$Task
    )

    if (Test-IsAdministrator) {
        return
    }

    Start-Elevated -Action $Action -UserProfile $UserProfile -Task $Task
}

function Run-AsSystem {
    param(
        [string]$UserProfile,

        [Parameter(Mandatory = $true)]
        [string]$Task
    )

    if ([string]::IsNullOrWhiteSpace($UserProfile)) {
        $UserProfile = [Environment]::ExpandEnvironmentVariables("%userprofile%")
    }

    if (-not (Test-IsAdministrator)) {
        Start-Elevated -Action "runassystem" -UserProfile $UserProfile -Task $Task
    }

    $psexecCommand = Get-Command psexec -ErrorAction SilentlyContinue
    if (-not $psexecCommand) {
        Write-Error "PsExec not found in PATH. Install Sysinternals PsExec or add it to PATH."
        Start-Sleep -Seconds 10
        exit 1
    }

    $scriptPath = Get-ScriptPath
    $powerShellPath = Get-PowerShellExecutable
    $sessionId = (Get-Process -Id $PID).SessionId

    $psi = [System.Diagnostics.ProcessStartInfo]::new($psexecCommand.Source)
    $psi.UseShellExecute = $false
    $arguments = @(
        "-accepteula",
        "-nobanner",
        "-i",
        [string]$sessionId,
        "-s",
        $powerShellPath,
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $scriptPath,
        "-Action",
        "system",
        "-UserProfile",
        $UserProfile,
        "-Task",
        $Task
    )

    foreach ($argument in $arguments) {
        [void]$psi.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::Start($psi)
    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        Write-Warning "PsExec exited with code $($process.ExitCode)."
        Start-Sleep -Seconds 10
    }

    exit $process.ExitCode
}

function Clean-CleanMgr {
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:$script:CleanMgrProfile" -Wait
}

function Get-DriveLetterFromPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $pathForDrive = $Path.Trim()
    while ($pathForDrive.EndsWith("*")) {
        $pathForDrive = $pathForDrive.Substring(0, $pathForDrive.Length - 1)
    }

    $fullPath = [System.IO.Path]::GetFullPath($pathForDrive)
    $root = [System.IO.Path]::GetPathRoot($fullPath)

    if ([string]::IsNullOrWhiteSpace($root) -or $root -notmatch "^[A-Za-z]:") {
        throw "Unable to identify a local drive for path '$Path'."
    }

    return $root.Substring(0, 1).ToUpperInvariant()
}

function Get-DriveDiskInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriveLetter
    )

    if ([string]::IsNullOrWhiteSpace($DriveLetter)) {
        throw "Drive letter is empty."
    }

    $normalizedDriveLetter = $DriveLetter.Trim().Substring(0, 1).ToUpperInvariant()

    if ($script:DriveInfoCache.ContainsKey($normalizedDriveLetter)) {
        return $script:DriveInfoCache[$normalizedDriveLetter]
    }

    $partition = Get-Partition -DriveLetter $normalizedDriveLetter -ErrorAction Stop | Select-Object -First 1
    $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction Stop
    $mediaType = [string]$disk.MediaType

    if ([string]::IsNullOrWhiteSpace($mediaType) -or $mediaType -eq "Unspecified") {
        $physicalDisk = Get-PhysicalDisk |
            Where-Object { $_.DeviceId -eq $disk.Number.ToString() } |
            Select-Object -First 1

        if ($physicalDisk) {
            $mediaType = [string]$physicalDisk.MediaType
        }
    }

    if ([string]::IsNullOrWhiteSpace($mediaType)) {
        $mediaType = "Unspecified"
    }

    $diskInfo = [pscustomobject]@{
        DriveLetter = $normalizedDriveLetter
        DiskNumber  = $disk.Number
        MediaType   = $mediaType
    }

    $script:DriveInfoCache[$normalizedDriveLetter] = $diskInfo
    return $diskInfo
}

function Remove-PathNormally {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
}

function Remove-PathWithSDelete {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    & $script:SDeletePath -accepteula -s -r $Path
}

function Remove-PathByDiskType {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Host "Path '$Path': not found. Skipping."
        return
    }

    try {
        $driveLetter = Get-DriveLetterFromPath -Path $Path
        $diskInfo = Get-DriveDiskInfo -DriveLetter $driveLetter
    }
    catch {
        Write-Warning "Path '$Path': unable to identify disk type. Running normal delete. Error: $($_.Exception.Message)"
        Remove-PathNormally -Path $Path
        return
    }

    switch ($diskInfo.MediaType) {
        "SSD" {
            Write-Host "Path '$Path': SSD detected. Running normal delete..."
            Remove-PathNormally -Path $Path
        }

        "HDD" {
            Write-Host "Path '$Path': HDD detected. Running SDelete..."
            Remove-PathWithSDelete -Path $Path
        }

        default {
            Write-Warning "Path '$Path': unknown media type '$($diskInfo.MediaType)'. Running normal delete."
            Remove-PathNormally -Path $Path
        }
    }
}

function Get-EventLogsToClear {
    if (-not $script:EnableEventLogsChoice) {
        return @(wevtutil el)
    }

    $choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
        "&All",
        "&Minimal",
        "&Cancel"
    )
    $choice = $host.UI.PromptForChoice("", "Clear Event Logs?", $choices, 0)

    switch ($choice) {
        0 { return @(wevtutil el) }
        1 { return $script:MinimalEventLogs }
        default { return @() }
    }
}

function Clear-EventLogs {
    $eventLogs = @(Get-EventLogsToClear)

    if ($eventLogs.Count -eq 0) {
        Write-Host "Event logs cleanup skipped."
        return
    }

    for ($i = 0; $i -lt $eventLogs.Count; $i++) {
        $logName = $eventLogs[$i]
        $percentComplete = [int](($i + 1) / $eventLogs.Count * 100)

        wevtutil cl "$logName"
        Write-Progress -Activity "Clearing event logs..." -Status $logName -PercentComplete $percentComplete
    }

    Write-Progress -Activity "Clearing event logs..." -Completed -Status "Done ($($eventLogs.Count))"
}

function Clean-Files {
    param(
        [string]$UserProfile
    )

    if ([string]::IsNullOrWhiteSpace($UserProfile)) {
        $UserProfile = [Environment]::ExpandEnvironmentVariables("%userprofile%")
    }

    $cleanupPaths = foreach ($cleanupPathTemplate in $script:CleanupPathTemplates) {
        $resolvedPath = $cleanupPathTemplate.Replace("{UserProfile}", $UserProfile)
        [Environment]::ExpandEnvironmentVariables($resolvedPath)
    }

    foreach ($cleanupPath in $cleanupPaths) {
        Remove-PathByDiskType -Path $cleanupPath
    }
}

function Clean-EventLogs {
    Clear-EventLogs
}

function Clean-FreeSpace {
    $volumes = Get-Volume |
        Where-Object { $_.DriveLetter -and $_.DriveType -eq "Fixed" } |
        Sort-Object DriveLetter

    foreach ($volume in $volumes) {
        $driveLetter = $volume.DriveLetter

        try {
            $diskInfo = Get-DriveDiskInfo -DriveLetter $driveLetter

            switch ($diskInfo.MediaType) {
                "SSD" {
                    Write-Host "Drive $($driveLetter): SSD detected. Running TRIM..."
                    Optimize-Volume -DriveLetter $driveLetter -ReTrim
                    Write-Host "...Done" -ForegroundColor Green
                }
                
                "HDD" {
                    Write-Host "Drive $($driveLetter): HDD detected. Running SDelete free-space cleanup..."
                    & $script:SDeletePath -accepteula -z "$($driveLetter):"
                    Write-Host "...Done" -ForegroundColor Green
                }

                default {
                    Write-Warning "Drive $($driveLetter): unknown media type '$($diskInfo.MediaType)'. Skipping."
                }
            }
        }
        catch {
            Write-Warning "Drive $($driveLetter): failed. Error: $($_.Exception.Message)"
        }
    }
}

function Run-All {
    param(
        [string]$UserProfile
    )

    if ([string]::IsNullOrWhiteSpace($UserProfile)) {
        $UserProfile = [Environment]::ExpandEnvironmentVariables("%userprofile%")
    }

    Clean-CleanMgr
    Run-AsSystem -UserProfile $UserProfile -Task "all"
}

function Show-MainMenu {
    Clear-Host
    Write-Host "===== CLEANUP TOOL ====="
    Write-Host "1) Disk Cleanup"
    Write-Host "2) Folders Cleanup"
    Write-Host "3) Event Logs Cleanup"
    Write-Host "4) Free space Cleanup"
    Write-Host "A) All"
    Write-Host "[any] Exit"
    Write-Host ""
}

function Invoke-MenuChoice {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Choice,

        [Parameter(Mandatory = $true)]
        [string]$UserProfile
    )

    switch ($Choice.Trim().ToUpperInvariant()) {
        "1" { Clean-CleanMgr; exit }
        "2" { Run-AsSystem -UserProfile $UserProfile -Task "cleanfiles" }
        "3" { Run-AsSystem -UserProfile $UserProfile -Task "eventlogs" }
        "4" { Run-AsSystem -UserProfile $UserProfile -Task "freespace" }
        "A" { Run-All -UserProfile $UserProfile }
        "ALL" { Run-All -UserProfile $UserProfile }
        default { return }
    }
}

function Invoke-SystemTask {
    param(
        [string]$UserProfile,
        [string]$Task
    )

    if ([string]::IsNullOrWhiteSpace($UserProfile)) {
        $UserProfile = [Environment]::ExpandEnvironmentVariables("%userprofile%")
    }

    switch ($Task) {
        "cleanfiles" { Clean-Files -UserProfile $UserProfile }
        "eventlogs"  { Clean-EventLogs }
        "freespace"  { Clean-FreeSpace }
        "all" {
            Clean-Files -UserProfile $UserProfile
            Clean-EventLogs
            Clean-FreeSpace
        }
        default {
            Write-Warning "Unknown system task '$Task'."
            exit 1
        }
    }

    Start-Sleep -Seconds 10
    exit
}

###############################
# ENTRY POINT
###############################

if ([string]::IsNullOrWhiteSpace($Action)) {
    if ([string]::IsNullOrWhiteSpace($UserProfile)) {
        $UserProfile = [Environment]::ExpandEnvironmentVariables("%userprofile%")
    }

    Ensure-Elevated -UserProfile $UserProfile

    Show-MainMenu
    $choice = Read-Host "Select an option"
    Invoke-MenuChoice -Choice $choice -UserProfile $UserProfile
    return
}

if ($Action -eq "system") {
    Invoke-SystemTask -UserProfile $UserProfile -Task $Task
}

if ($Action -eq "runassystem") {
    Ensure-Elevated -Action $Action -UserProfile $UserProfile -Task $Task
    Run-AsSystem -UserProfile $UserProfile -Task $Task
}

Write-Warning "Unknown action '$Action'."
exit 1
