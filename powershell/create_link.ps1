$SOURCE = $PWD
cd $PSHOME
New-Item -ItemType HardLink -Name Profile.ps1 -Value $SOURCE\Profile.ps1
