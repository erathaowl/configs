# Create a symlink to:
#   %ProgramFiles%\Powershell\7\Profile.ps1
#   %USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
#
Import-Module "gsudoModule"

#uv related shortcuts
function uvr {
    uv run @args
}

function uvp {
    uv run python @args
}

function uvm {
    uv run python manage.py @args
}

# python3XX run the corrisponding interpretere launching py -3.xx
function python {
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    $invokedAs = $MyInvocation.InvocationName

    # python3  -> lancia l'ultima 3.x disponibile
    if ($invokedAs -eq 'python3') {
        & py -3 @Args
        return
    }

    # python3XX -> lancia 3.XX
    if ($invokedAs -match '^python3(\d{1,2})$') {
        & py "-3.$($matches[1])" @Args
        return
    }

    # fallback
    & py @Args
}

# Alias python3 (latest) + python3XX (specific)
Set-Alias -Name python3 -Value python -Scope Global
3..20 | ForEach-Object { Set-Alias -Name "python3$_" -Value python -Scope Global }

function ll {
    & 'ls' --color=auto -AFhl @args
}

function vi ($File){
    bash -c "vi $File"
}

function nano ($File){
    bash -c "nano $File"
}

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

function pi-sandbox {
    if ($args.Count -gt 0 -and $args[0] -in @("update", "--update")) {
        $buildArgs = @($args | Select-Object -Skip 1)

        docker build @buildArgs `
            -t pi-sandbox `
            "C:\dev\github\configs\pi\"

        return
    }

    docker run --rm -it `
        -v "${PWD}:/workspace" `
        -v "pi-agent-home:/root/.pi/agent" `
        pi-sandbox @args
}

