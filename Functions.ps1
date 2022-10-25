# Test if IP is valid and print message if not
function Test-IP {
    Param(
        [Parameter(Position = 0)][string]$LANIP
    )
    $IPregex = "(\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b)"
    if ($LANIP -match $IPregex) {
        Return $LANIP
    }    
    Write-Host "Invalid IP address given. Please try again."
    Return $null
}
# Test if switch number is valid and print message if not
function Test-SwitchNumber {
    Param(
        [Parameter(Position = 0)]$SwitchNumber
    )
    try {
        $SwitchNumber = [int]$SwitchNumber
    } catch {
        Write-Host "You must enter a number."
        Return $null
    }
    if ($SwitchNumber -gt 0 -and $SwitchNumber -lt 10) {
        Return $SwitchNumber
    }    
    Write-Host "Invalid switch number given. Please try again."
    Return $null
}

