# Usage: .\new.ps1 post-name
if (-not $args[0]) {
    Write-Host 'Usage: .\new.ps1 post-name'
    exit 1
}

Set-Location $PSScriptRoot
hugo new "posts/$($args[0]).md"
