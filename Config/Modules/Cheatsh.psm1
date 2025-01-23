if (-not $global:ModuleImportedCheatsh) {
    $global:ModuleImportedCheatsh = $true
} else {
    Write-Debug -Message "Attempting to import module twice!" -Channel "Error" -Condition $DebugProfile -FileAndLine
    return
}

function cht {
    param (
        [string]$topic
    )
    try {
        (Invoke-WebRequest -UseBasicParsing "https://cht.sh/$topic").Content
    }
    catch {
        Write-Output "There was an issue retrieving the cheat sheet."
    }
}

Export-ModuleMember -Function cht
