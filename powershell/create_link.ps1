$SOURCE = $PWD

Set-Location $PSHOME
#if exists, delete the existing hard link
if (Test-Path -Path Profile.ps1) {
    Write-Host "Removing existing hard link: Profile.ps1"
    Remove-Item -Path Profile.ps1
}
Write-Host "Creating hard link: Profile.ps1"
New-Item -ItemType HardLink -Name Profile.ps1 -Value $SOURCE\Profile.ps1

Set-Location $HOME\Documents\PowerShell
#if exists, delete the existing hard link
if (Test-Path -Path Microsoft.PowerShell_profile.ps1) {
    Write-Host "Removing existing hard link: Microsoft.PowerShell_profile.ps1"
    Remove-Item -Path Microsoft.PowerShell_profile.ps1
}
Write-Host "Creating hard link: Microsoft.PowerShell_profile.ps1"
New-Item -ItemType HardLink -Name Microsoft.PowerShell_profile.ps1 -Value $SOURCE\Microsoft.PowerShell_profile.ps1

Read-Host "Press any key to continue..."
