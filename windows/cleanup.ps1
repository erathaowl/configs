param($action, $UserProfile)

###############################
# CONFIG
###############################
$EnableEventLogsChoice = $false

###############################
# FUNCTIONS
###############################

function Run-AsSystem {
    param($UserProfile, $Task)

    $psi = New-Object System.Diagnostics.ProcessStartInfo "sudo"
    $psi.Arguments = 'psexec -accepteula -nobanner -i -s -d pwsh -File "' +
                     $script:MyInvocation.MyCommand.Path +
                     '" system "' + $UserProfile + '" "' + $Task + '"'

    [System.Diagnostics.Process]::Start($psi)
    timeout 3
    exit
}

function Clean-CleanMgr {
    #sudo cleanmgr.exe /sagerun:2504
    Start-Process "sudo" -ArgumentList "cleanmgr.exe /sagerun:2504" -Wait
	#timeout 150
}

function Clean-FilesAndEventLogs {
    param($UserProfile)

    $SysTempFolder      = [Environment]::ExpandEnvironmentVariables('%temp%\*')
    $UserTempFolder     = "$UserProfile\AppData\Local\Temp\*"
    $UserRDPCacheFolder = "$UserProfile\AppData\Local\Microsoft\Terminal Server Client\Cache\*"
    $UserThumbnailCache = "$UserProfile\AppData\Local\Microsoft\Windows\Explorer\*"
    $UserBrowserCache   = "$UserProfile\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache\Cache_Data"

    sdelete -s -r $UserRDPCacheFolder
    sdelete -s -r $SysTempFolder
    sdelete -s -r $UserTempFolder
    sdelete -s -r $UserThumbnailCache
    sdelete -s -r $UserBrowserCache

    if ($EnableEventLogsChoice) {
        $Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&All","&Minimal","&Cancel")
        $Choice = $host.UI.PromptForChoice("", "Clear Event Logs?", $Choices, 0)
        switch ($Choice) {
            0 { $EventLogs = wevtutil el }
            1 { $EventLogs = @("Application","Security","Setup","System") }
            2 { $EventLogs = @() }
        }
    } else {
        $EventLogs = wevtutil el
    }

    $EventLogs | ForEach-Object -Begin {
        $i = 0; $act = "Clearing event logs..."
    } -Process {
        $i++
        wevtutil cl "$_"
        Write-Progress -Activity $act -Status "$_" -PercentComplete ($i/$EventLogs.Count*100)
    } -End {
        Write-Progress -Activity $act -Completed -Status "Done ($($EventLogs.Count))"
    }
}

function Clean-FreeSpace {
    $drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
    foreach ($d in $drives) {
        sdelete -z $d
    }
}

function Run-All {
    # 1) Disk cleanup (user)
    Clean-CleanMgr

    # 2) Elevate as SYSTEM for the other tasks
    Run-AsSystem $UserProfile "all"
}


###############################
# ENTRY POINT
###############################

# First run: show the menu
if ($null -eq $action) {

    $UserProfile = [Environment]::ExpandEnvironmentVariables('%userprofile%')

    Clear-Host
    Write-Host "===== CLEANUP TOOL ====="
    Write-Host "1) Disk Cleanup"
    Write-Host "2) Folders and EventLogs Cleanup"
    Write-Host "3) Free space Cleanup"
    Write-Host "4) All"
    Write-Host "5) Quit"
    Write-Host ""

    $choice = Read-Host "Seleziona un'opzione"
	switch ($choice) {
        "1" { Clean-CleanMgr; exit }
		"2" { Run-AsSystem $UserProfile "cleanfiles" }
		"3" { Run-AsSystem $UserProfile "freespace" }
		"4" { Run-All }
		default { return }
	}

}

if ($action -eq "system") {

    $UserProfile = $UserProfile
    $Task = $args[0]

    switch ($Task) {
        "cleanfiles" { Clean-FilesAndEventLogs -UserProfile $UserProfile }
        "freespace"  { Clean-FreeSpace }
        "all" {
            Clean-FilesAndEventLogs -UserProfile $UserProfile
            Clean-FreeSpace
        }
        default { exit }
    }

    timeout 10
    exit
}
