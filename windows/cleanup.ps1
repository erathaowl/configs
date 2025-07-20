param($action, $UserProfile)

#######################################################################################
$EnableEventLogsChoice = $false;

#######################################################################################
# Disk cleanup, run the configuration saved with "cleanmgr.exe /sageset:1"
sudo cleanmgr.exe /sagerun:1

#######################################################################################
# Run current script as SYSTEM
if ($null -eq $action) {
	$UserProfile = [Environment]::ExpandEnvironmentVariables('%userprofile%')
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "sudo";
    $newProcess.Arguments = 'psexec -accepteula -nobanner -i -s -d pwsh -File "' + $script:MyInvocation.MyCommand.Path + '" go "' + $UserProfile + '"'
    [System.Diagnostics.Process]::Start($newProcess);
    timeout 20
	exit
}

#######################################################################################
$SysTempFolder = [Environment]::ExpandEnvironmentVariables('%temp%\*')
# $RDPCacheFolder = [Environment]::ExpandEnvironmentVariables('%LOCALAPPDATA%\Microsoft\Terminal Server Client\Cache\*')

$UserTempFolder = $UserProfile + '\AppData\Local\Temp\*'
$UserRDPCacheFolder = $UserProfile + '\AppData\Local\Microsoft\Terminal Server Client\Cache\*'
$UserThumbnailCache = $UserProfile + '\AppData\Local\Microsoft\Windows\Explorer\*'

# Clear files in temporary folder
sdelete -s -r $UserRDPCacheFolder
sdelete -s -r $SysTempFolderSys
sdelete -s -r $UserTempFolder
sdelete -s -r $UserThumbnailCache

#######################################################################################
if ($EnableEventLogsChoice -eq $true) {
	# Select wich event log to clear
	$Prompt = "Clear Events Logs?"
	$Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&All", "&Minimal", "&Cancel")
	$Default = 0
	 
	# Prompt for choose which logs to clear
	$Choice = $host.UI.PromptForChoice("", $Prompt, $Choices, $Default)
	 
	# Create a list of event logs to clear based on user choice
	switch($Choice) {
		0 { $EventLogs = (wevtutil el) } # all events logs
		1 { $EventLogs = @("Application", 
						   "Security", 
						   "Setup", 
						   "System") }
		2 { $EventLogs = @()} # none
	}
} else {
	# Clear all event logs
	$EventLogs = (wevtutil el)
}

# Proceed to clear events logs
$EventLogs | Foreach-Object -Begin {
    $i = 0
    $act = "Clearing event logs: "
} -Process {
    $i = $i+1
    wevtutil cl "$_"; 
    Write-Progress -Activity $act -Status "$_" -PercentComplete ($i/$EventLogs.count*100)
} -End {
    if ($EventLogs.count -gt 0) {
        $out = $EventLogs.count.ToString() + " Event logs clearred"
    } Else {
        $out = "Clearing event logs skipped"
    }
    Write-Progress -Activity $act -Status $out -Completed
}

# end
timeout 10
