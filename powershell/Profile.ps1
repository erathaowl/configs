Import-Module "gsudoModule"
# Set-Alias Prompt gsudoPrompt

function Invoke-Starship-TransientFunction {
    &starship module character
}

Invoke-Expression (&starship init powershell)

#Enable-TransientPrompt

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

# Set-Alias -Name kali -Value wsl-kali
# Set-Alias -Name ubuntu -Value wsl-ubuntu

