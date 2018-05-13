########################################
# Crypto Trackr Installer               #
# Copies to %localappdata%\CryptoTrackr #
#########################################

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path

$InstallFiles = @(
    "CoinMarketCap.psm1"
    "crypto-trackr-main.ps1"
    "icon.ico"
)

New-Item "$Env:LOCALAPPDATA\CryptoTrackr" -ItemType Directory -Force | Out-Null

foreach($File in $InstallFiles){
    Copy-Item "$ScriptPath\$File" -Destination "$Env:LOCALAPPDATA\CryptoTrackr" -Force
}

Copy-Item "$ScriptPath\Crypto Trackr.lnk" -Destination "$Env:USERPROFILE\Desktop" -Force