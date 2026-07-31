$SOURCE = $PWD

Write-Host "Creating hard link: Profile.ps1"
Start-Process (Get-Process -Id $PID).Path -Verb RunAs -ArgumentList '-Command', "New-Item -ItemType HardLink -Path '$PSHOME\Profile.ps1'-Target '.\Profile.ps1' -Force"

Write-Host "Creating hard link: $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
New-Item -ItemType HardLink -Path $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 -Target '.\Profile.ps1' -Force

Read-Host "Press any key to continue..."
