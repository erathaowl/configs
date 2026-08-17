param(
    [string]$Action,
    [string]$UserProfile,
    [string]$Task
)

###############################
# CONFIG
###############################
$script:EnableEventLogsChoice = $true
$script:EnableJumpListCleanup = $false
$script:EnableShellBagCleanup = $false
$script:CleanMgrProfile = 2504
$script:SDeletePath = "sdelete.exe"
$script:SDeleteFreeSpaceReservePercent = 10
$script:MinimalEventLogs = @("Application", "Security", "Setup", "System")
$script:CleanupPathTemplates = @(
    "%temp%\*",
    "%windir%\Temp\*",
    "%windir%\Minidump\*",
    "%windir%\MEMORY.DMP",
    "%ProgramData%\Microsoft\Windows\WER\ReportArchive\*",
    "%ProgramData%\Microsoft\Windows\WER\ReportQueue\*",
    "%ProgramData%\Microsoft\Windows\WER\Temp\*",
    "{UserProfile}\AppData\Local\Temp\*",
    "{UserProfile}\AppData\Local\CrashDumps\*",
    "{UserProfile}\AppData\Local\D3DSCache\*",
    "{UserProfile}\AppData\Local\Microsoft\Terminal Server Client\Cache\*",
    "{UserProfile}\AppData\Local\Microsoft\Windows\Clipboard\*",
    "{UserProfile}\AppData\Local\Microsoft\Windows\Explorer\*",
    "{UserProfile}\AppData\Local\Microsoft\Windows\INetCache\*",
    "{UserProfile}\AppData\Local\Microsoft\Windows\WER\*",
    "{UserProfile}\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\*_history.txt",
    "{UserProfile}\AppData\Roaming\Microsoft\Windows\Recent\*.lnk",
    "{UserProfile}\AppData\Roaming\Microsoft\Windows\Recent\*.url",
    "{UserProfile}\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\*",
    "{UserProfile}\AppData\Local\Mozilla\Firefox\Profiles\*\startupCache\*",
    "{UserProfile}\AppData\Local\Mozilla\Firefox\Profiles\*\thumbnails\*",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\AlternateServices.txt",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\bounce-tracking-protection.sqlite*",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\cookies.sqlite*",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\enumerate_devices.txt",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\favicons.sqlite*",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\formhistory.sqlite*",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\protections.sqlite*",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\sessionCheckpoints.json",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\sessionstore.jsonlz4",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\sessionstore-backups\*",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\storage.sqlite*",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\storage\default\*",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\storage\temporary\*",
    "{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\webappsstore.sqlite*"
)
if ($script:EnableJumpListCleanup) {
    $script:CleanupPathTemplates += @(
        "{UserProfile}\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations\*",
        "{UserProfile}\AppData\Roaming\Microsoft\Windows\Recent\CustomDestinations\*"
    )
}
$script:ChromiumProfileRoots = @(
    "{UserProfile}\AppData\Local\Google\Chrome\User Data\*",
    "{UserProfile}\AppData\Local\Microsoft\Edge\User Data\*",
    "{UserProfile}\AppData\Local\BraveSoftware\Brave-Browser\User Data\*"
)
$script:PortableBraveProfileRoot = "F:\Browsers\Brave\Default\Default"
if (Test-Path -LiteralPath "$script:PortableBraveProfileRoot\Preferences" -PathType Leaf) {
    $script:ChromiumProfileRoots += $script:PortableBraveProfileRoot
}
$script:ChromiumActivityPaths = @(
    "BrowsingTopicsState",
    "Cache\*",
    "Code Cache\*",
    "Cookies",
    "Cookies-journal",
    "Current Session",
    "Current Tabs",
    "DIPS",
    "DIPS-journal",
    "Favicons",
    "Favicons-journal",
    "GPUCache\*",
    "History",
    "History-journal",
    "IndexedDB\*",
    "InterestGroups\*",
    "Last Session",
    "Last Tabs",
    "Local Storage\*",
    "Media History",
    "Media History-journal",
    "Network\Cookies",
    "Network\Cookies-journal",
    "Network\Network Persistent State",
    "Network\Reporting and NEL",
    "Network\Reporting and NEL-journal",
    "Network Action Predictor",
    "Network Action Predictor-journal",
    "Service Worker\*",
    "Session Storage\*",
    "SharedStorage\*",
    "SharedStorage-wal",
    "Sessions\*",
    "Site Characteristics Database\*",
    "Top Sites",
    "Top Sites-journal",
    "Trust Tokens",
    "Trust Tokens-journal",
    "Visited Links",
    "WebStorage\*"
)
$script:CleanupPathTemplates += foreach ($chromiumProfileRoot in $script:ChromiumProfileRoots) {
    foreach ($chromiumActivityPath in $script:ChromiumActivityPaths) {
        "$chromiumProfileRoot\$chromiumActivityPath"
    }
}
$script:UserActivityRegistryPaths = @(
    "HKCU:\Software\Microsoft\Terminal Server Client\Default",
    "HKCU:\Software\Microsoft\Terminal Server Client\Servers",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Paint\Recent File List",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRULegacy",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Map Network Drive MRU",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\JumplistData",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\RecentApps",
    "HKCU:\Software\Microsoft\Internet Explorer\TypedURLs",
    "HKCU:\Software\Microsoft\Internet Explorer\TypedURLsTime",
    "HKCU:\Software\Microsoft\MediaPlayer\Player\RecentFileList",
    "HKCU:\Software\Microsoft\MediaPlayer\Player\RecentURLList",
    "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store",
    "HKCU:\Software\Microsoft\Office\*\*\File MRU",
    "HKCU:\Software\Microsoft\Office\*\*\Place MRU",
    "HKCU:\Software\Microsoft\Office\*\*\User MRU"
)
if ($script:EnableShellBagCleanup) {
    $script:UserActivityRegistryPaths += @(
        "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU",
        "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags",
        "HKCU:\Software\Microsoft\Windows\Shell\BagMRU",
        "HKCU:\Software\Microsoft\Windows\Shell\Bags"
    )
}
$script:DriveInfoCache = @{}
$script:SysinternalsPathCache = @{}

###############################
# FUNCTIONS
###############################

# Returns this script's absolute path; throws when no host API exposes it and has no side effects.
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

# Returns the active PowerShell executable path or throws; it never trusts a same-named executable from PATH.
function Get-PowerShellExecutable {
    try {
        $currentProcess = Get-Process -Id $PID -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace($currentProcess.Path)) {
            return $currentProcess.Path
        }
    }
    catch {
        throw "Unable to resolve the active PowerShell executable. $($_.Exception.Message)"
    }

    throw "The active PowerShell process did not expose an executable path."
}

# Resolves a Microsoft-signed Sysinternals executable; returns its path or throws without starting it.
function Get-ValidatedSysinternalsExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($script:SysinternalsPathCache.ContainsKey($Name)) {
        return $script:SysinternalsPathCache[$Name]
    }

    $command = Get-Command -Name $Name -CommandType Application -ErrorAction Stop |
        Select-Object -First 1
    $signature = Get-AuthenticodeSignature -FilePath $command.Source -ErrorAction Stop
    if ($signature.Status -ne "Valid" -or $signature.SignerCertificate.Subject -notmatch "O=Microsoft Corporation") {
        throw "Sysinternals executable '$($command.Source)' does not have a valid Microsoft signature."
    }

    $script:SysinternalsPathCache[$Name] = $command.Source
    return $command.Source
}

# Returns $true when the current identity is an administrator; it does not modify the process token.
function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Restarts this script with the supplied action context under UAC elevation, then exits the current process.
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

# Returns when already elevated or relaunches with the supplied action context and exits.
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

# Runs one cleanup task interactively as SYSTEM through PsExec and returns only by exiting with its status.
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

    try {
        $psexecPath = Get-ValidatedSysinternalsExecutable -Name "psexec.exe"
    }
    catch {
        Write-Error "Unable to use PsExec. $($_.Exception.Message)"
        Start-Sleep -Seconds 10
        exit 1
    }

    $scriptPath = Get-ScriptPath
    $powerShellPath = Get-PowerShellExecutable
    $sessionId = (Get-Process -Id $PID).SessionId

    $psi = [System.Diagnostics.ProcessStartInfo]::new($psexecPath)
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

# Runs the configured Disk Cleanup profile synchronously; it returns no output and changes selected disk content.
function Clean-CleanMgr {
    $cleanMgrPath = Join-Path -Path ([Environment]::SystemDirectory) -ChildPath "cleanmgr.exe"
    Start-Process -FilePath $cleanMgrPath -ArgumentList "/sagerun:$script:CleanMgrProfile" -Wait
}

# Extracts and returns an uppercase local drive letter from a path; throws for unsupported paths.
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

# Returns cached disk number and media type metadata for a drive letter without changing the disk.
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

# Expands wildcards in a path's parent directories while preserving its final name or contents wildcard.
function Resolve-CleanupPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $parentPath = Split-Path -Path $Path -Parent
    if ($parentPath -notmatch "[?*]") {
        return $Path
    }

    $leafName = Split-Path -Path $Path -Leaf
    $resolvedParents = @(Resolve-Path -Path $parentPath -ErrorAction SilentlyContinue)
    if ($resolvedParents.Count -eq 0) {
        return $Path
    }

    $resolvedPaths = foreach ($resolvedParent in $resolvedParents) {
        $candidatePath = Join-Path -Path $resolvedParent.Path -ChildPath $leafName
        if (Test-Path -Path $candidatePath) {
            $candidatePath
        }
    }

    if (@($resolvedPaths).Count -eq 0) {
        return $Path
    }

    return $resolvedPaths
}

# Recursively removes a supplied path without secure overwriting and suppresses individual deletion errors.
function Remove-PathNormally {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
}

# Securely removes an HDD path with SDelete, using normal deletion when a reparse point could redirect recursion.
function Remove-PathWithSDelete {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # User-writable caches can contain junctions; never let SYSTEM-level SDelete recurse through one.
    $inspectionPath = $Path.TrimEnd("*").TrimEnd("\")
    $reparsePoints = @(
        Get-Item -Path $inspectionPath -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint }
        Get-ChildItem -Path $Path -Force -Recurse -Attributes ReparsePoint -ErrorAction SilentlyContinue
    )

    if ($reparsePoints.Count -gt 0) {
        Write-Warning "Path '$Path': reparse point detected. Using non-following normal deletion for safety."
        Remove-PathNormally -Path $Path
        return
    }

    $sdeletePath = Get-ValidatedSysinternalsExecutable -Name $script:SDeletePath
    & $sdeletePath -accepteula -s -r $Path
}

# Removes a supplied path normally on SSDs or with SDelete on HDDs, falling back safely when detection fails.
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

# Returns all event log names or the configured subset based on the optional interactive choice.
function Get-EventLogsToClear {
    $wevtutilPath = Join-Path -Path ([Environment]::SystemDirectory) -ChildPath "wevtutil.exe"
    if (-not $script:EnableEventLogsChoice) {
        return @(& $wevtutilPath el)
    }

    $choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
        "&All",
        "&Minimal",
        "&Cancel"
    )
    $choice = $host.UI.PromptForChoice("", "Clear Event Logs?", $choices, 2)

    switch ($choice) {
        0 { return @(& $wevtutilPath el) }
        1 { return $script:MinimalEventLogs }
        default { return @() }
    }
}

# Clears the selected Windows event logs and reports progress; it returns no data.
function Clear-EventLogs {
    $eventLogs = @(Get-EventLogsToClear)
    $wevtutilPath = Join-Path -Path ([Environment]::SystemDirectory) -ChildPath "wevtutil.exe"

    if ($eventLogs.Count -eq 0) {
        Write-Host "Event logs cleanup skipped."
        return
    }

    for ($i = 0; $i -lt $eventLogs.Count; $i++) {
        $logName = $eventLogs[$i]
        $percentComplete = [int](($i + 1) / $eventLogs.Count * 100)

        & $wevtutilPath cl "$logName"
        Write-Progress -Activity "Clearing event logs..." -Status $logName -PercentComplete $percentComplete
    }

    Write-Progress -Activity "Clearing event logs..." -Completed -Status "Done ($($eventLogs.Count))"
}

# Resolves a local profile path to its Windows SID; returns the SID or $null without changing state.
function Get-UserSidFromProfile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserProfile
    )

    try {
        $normalizedProfile = [System.IO.Path]::GetFullPath($UserProfile).TrimEnd("\")
        $profile = Get-CimInstance -ClassName Win32_UserProfile -ErrorAction Stop |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_.LocalPath) -and
                [System.IO.Path]::GetFullPath($_.LocalPath).TrimEnd("\") -eq $normalizedProfile
            } |
            Select-Object -First 1

        return $profile.SID
    }
    catch {
        Write-Warning "Unable to resolve the SID for profile '$UserProfile'. Error: $($_.Exception.Message)"
        return $null
    }
}

# Removes the selected profile's Recycle Bin contents on fixed drives; writes progress and no output.
function Clean-RecycleBin {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserProfile
    )

    $userSid = Get-UserSidFromProfile -UserProfile $UserProfile
    if ([string]::IsNullOrWhiteSpace($userSid)) {
        Write-Warning "Recycle Bin cleanup skipped because the user SID was not found."
        return
    }

    $volumes = Get-Volume |
        Where-Object { $_.DriveLetter -and $_.DriveType -eq "Fixed" } |
        Sort-Object DriveLetter

    foreach ($volume in $volumes) {
        $recycleBinPath = "$($volume.DriveLetter):\`$Recycle.Bin\$userSid\*"
        Remove-PathByDiskType -Path $recycleBinPath
    }
}

# Clears volatile DNS resolver records for the Windows instance; writes a warning if Windows rejects the request.
function Clear-NetworkActivity {
    try {
        Clear-DnsClientCache -ErrorAction Stop
        Write-Host "DNS client cache cleared."
    }
    catch {
        Write-Warning "DNS client cache cleanup failed. Error: $($_.Exception.Message)"
    }
}

# Removes MRU registry keys and clipboard data only when HKCU belongs to the supplied profile.
function Clean-UserActivity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserProfile
    )

    try {
        $targetProfile = [System.IO.Path]::GetFullPath($UserProfile).TrimEnd("\")
        $currentProfile = [System.IO.Path]::GetFullPath(
            [Environment]::ExpandEnvironmentVariables("%userprofile%")
        ).TrimEnd("\")
    }
    catch {
        Write-Warning "Current-user activity cleanup skipped because the profile path is invalid."
        return
    }

    if ($targetProfile -ne $currentProfile) {
        Write-Warning "Current-user activity cleanup skipped because HKCU does not belong to '$UserProfile'."
        return
    }

    foreach ($registryPath in $script:UserActivityRegistryPaths) {
        if (Test-Path -Path $registryPath) {
            Remove-Item -Path $registryPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    try {
        Set-Clipboard -Value ([string]::Empty) -ErrorAction Stop
        Write-Host "Current user clipboard cleared."
    }
    catch {
        Write-Warning "Clipboard cleanup failed. Error: $($_.Exception.Message)"
    }
}

# Expands configured paths and removes user/system caches, profile history, Recycle Bin data, and DNS records.
function Clean-Files {
    param(
        [string]$UserProfile
    )

    if ([string]::IsNullOrWhiteSpace($UserProfile)) {
        $UserProfile = [Environment]::ExpandEnvironmentVariables("%userprofile%")
    }

    if (-not (Test-Path -LiteralPath $UserProfile -PathType Container)) {
        throw "User profile '$UserProfile' does not exist. Cleanup stopped."
    }

    $profileRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($UserProfile))
    if ([System.IO.Path]::GetFullPath($UserProfile).TrimEnd("\") -eq $profileRoot.TrimEnd("\")) {
        throw "A drive root cannot be used as a user profile. Cleanup stopped."
    }

    if ([string]::IsNullOrWhiteSpace((Get-UserSidFromProfile -UserProfile $UserProfile))) {
        throw "'$UserProfile' is not a registered Windows user profile. Cleanup stopped."
    }

    $cleanupPaths = foreach ($cleanupPathTemplate in $script:CleanupPathTemplates) {
        $resolvedPath = $cleanupPathTemplate.Replace("{UserProfile}", $UserProfile)
        [Environment]::ExpandEnvironmentVariables($resolvedPath)
    }

    # Never remove live browser databases; skip that browser as a unit and let the user rerun after closing it.
    $runningBrowserPrefixes = @()
    if (Get-Process -Name "chrome" -ErrorAction SilentlyContinue) {
        Write-Warning "Chrome is running. Chrome cleanup will be skipped."
        $runningBrowserPrefixes += "$UserProfile\AppData\Local\Google\Chrome\"
    }
    if (Get-Process -Name "msedge" -ErrorAction SilentlyContinue) {
        Write-Warning "Edge is running. Edge cleanup will be skipped."
        $runningBrowserPrefixes += "$UserProfile\AppData\Local\Microsoft\Edge\"
    }
    if (Get-Process -Name "brave" -ErrorAction SilentlyContinue) {
        Write-Warning "Brave is running. Brave cleanup will be skipped."
        $runningBrowserPrefixes += @(
            "$UserProfile\AppData\Local\BraveSoftware\Brave-Browser\",
            "$script:PortableBraveProfileRoot\"
        )
    }
    if (Get-Process -Name "firefox" -ErrorAction SilentlyContinue) {
        Write-Warning "Firefox is running. Firefox cleanup will be skipped."
        $runningBrowserPrefixes += @(
            "$UserProfile\AppData\Local\Mozilla\Firefox\",
            "$UserProfile\AppData\Roaming\Mozilla\Firefox\"
        )
    }

    foreach ($cleanupPath in $cleanupPaths) {
        $isLiveBrowserPath = $false
        foreach ($runningBrowserPrefix in $runningBrowserPrefixes) {
            if ($cleanupPath.StartsWith($runningBrowserPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $isLiveBrowserPath = $true
                break
            }
        }
        if ($isLiveBrowserPath) {
            continue
        }

        # Expand profile-directory wildcards before invoking native SDelete, which handles only the final wildcard reliably.
        foreach ($resolvedCleanupPath in @(Resolve-CleanupPath -Path $cleanupPath)) {
            Remove-PathByDiskType -Path $resolvedCleanupPath
        }
    }

    Clean-RecycleBin -UserProfile $UserProfile
    Clear-NetworkActivity
}

# Executes event log cleanup; this thin task entry point returns no data.
function Clean-EventLogs {
    Clear-EventLogs
}

# Retrims fixed SSD volumes and wipes free space on fixed HDD volumes, reporting failures per drive.
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
                    # Keep working space available so live services are not forced into a disk-full condition.
                    $sdeletePath = Get-ValidatedSysinternalsExecutable -Name $script:SDeletePath
                    & $sdeletePath -accepteula -c $script:SDeleteFreeSpaceReservePercent "$($driveLetter):"
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

# Runs Disk Cleanup and current-user cleanup, then delegates all privileged cleanup tasks to SYSTEM.
function Run-All {
    param(
        [string]$UserProfile
    )

    if ([string]::IsNullOrWhiteSpace($UserProfile)) {
        $UserProfile = [Environment]::ExpandEnvironmentVariables("%userprofile%")
    }

    Clean-CleanMgr
    Clean-UserActivity -UserProfile $UserProfile
    Run-AsSystem -UserProfile $UserProfile -Task "all"
}

# Clears the console and displays the interactive menu without returning a value.
function Show-MainMenu {
    Clear-Host
    Write-Host "===== CLEANUP TOOL ====="
    Write-Host "1) Disk Cleanup"
    Write-Host "2) User Activity and Files Cleanup"
    Write-Host "3) Event Logs Cleanup"
    Write-Host "4) Free space Cleanup"
    Write-Host "A) All"
    Write-Host "[any] Exit"
    Write-Host ""
}

# Executes the selected menu operation for the supplied profile and exits or delegates when appropriate.
function Invoke-MenuChoice {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Choice,

        [Parameter(Mandatory = $true)]
        [string]$UserProfile
    )

    switch ($Choice.Trim().ToUpperInvariant()) {
        "1" { Clean-CleanMgr; exit }
        "2" { Clean-UserActivity -UserProfile $UserProfile; Run-AsSystem -UserProfile $UserProfile -Task "cleanfiles" }
        "3" { Run-AsSystem -UserProfile $UserProfile -Task "eventlogs" }
        "4" { Run-AsSystem -UserProfile $UserProfile -Task "freespace" }
        "A" { Run-All -UserProfile $UserProfile }
        "ALL" { Run-All -UserProfile $UserProfile }
        default { return }
    }
}

# Dispatches one named SYSTEM cleanup task for the supplied profile, then exits with success or failure.
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
