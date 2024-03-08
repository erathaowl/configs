Import-Module "gsudoModule"
# Set-Alias Prompt gsudoPrompt

function Invoke-Starship-TransientFunction {
    # &starship module time
    &starship module character
}

Invoke-Expression (&starship init powershell)

Enable-TransientPrompt

###############################################################
###############################################################

function dns-get {
	Get-DnsClientServerAddress -AddressFamily IPv4 | Format-Table -AutoSize
}

function dns-clear($idx) {
    if (!$idx){
		Write "Usage: dns-clear [INTERFACE-INDEX]"
        Write-Error -Message "Please provide an interface index" -Category InvalidArgument
		Write ""
    } else {
        sudo Set-DnsClientServerAddress -InterfaceIndex $idx -ResetServerAddresses
    }
}

function vi ($File){
    bash -c "vi $File"
}

function nano ($File){
    bash -c "nano $File"
}


# function wsl-kali {
	# wsl -d kali-linux
# }

# function wsl-ubuntu {
	# wsl -d Ubuntu
# }


Set-Alias -Name ll -Value ls

Set-Alias -Name python3 -Value python
Set-Alias -Name python36 -Value "C:\Python\Python36_64\python.exe"
Set-Alias -Name python37 -Value "C:\Python\Python37_64\python.exe"
Set-Alias -Name python38 -Value "C:\Python\Python38_64\python.exe"
Set-Alias -Name python39 -Value "C:\Python\Python39_64\python.exe"
Set-Alias -Name python310 -Value "C:\Python\Python310_64\python.exe"
Set-Alias -Name python311 -Value "C:\Python\Python311_64\python.exe"
Set-Alias -Name python312 -Value "C:\Python\Python312_64\python.exe"

# Set-Alias -Name kali -Value wsl-kali
# Set-Alias -Name ubuntu -Value wsl-ubuntu

