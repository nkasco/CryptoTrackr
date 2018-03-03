################################################
# Title: Crypto Trackr                         #
# Created by: Nathan Kasco                     #
# Date Started: 2/24/2018                      #
################################################

$ErrorActionPreference = "SilentlyContinue"

#Install CoinMarketCap Module - Credit: https://github.com/lazywinadmin/CoinMarketCap
if(!(Get-Module -Name CoinMarketCap)){
    Install-Module -ModulePath "CoinMarketCap\CoinMarketCap.psm1"
}

#Load config from AppData
$ConfigLocation = "$env:LOCALAPPDATA\CryptoTrackr\config.csv"
if(Test-Path $ConfigLocation){
    $Config = Import-Csv $ConfigLocation
} else {
    #Build blank config file
    if(!(Test-Path(Split-Path $ConfigLocation))){
        New-Item (Split-Path $ConfigLocation) -ItemType Directory | Out-Null
    }
    @("Coins`nBTC`nETH`nLTC") | Out-File $ConfigLocation -Force
    $Config = Import-Csv $ConfigLocation
}