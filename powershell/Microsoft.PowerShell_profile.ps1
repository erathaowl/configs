# C:\Users\<username>\Documents\PowerShell

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