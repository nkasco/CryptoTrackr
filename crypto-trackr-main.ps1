################################################
# Title: Crypto Trackr                         #
# Created by: Nathan Kasco                     #
# Date Started: 5/13/2018                      #
################################################

$ErrorActionPreference = "SilentlyContinue"
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path

#Install CoinMarketCap Module - Credit: https://github.com/lazywinadmin/CoinMarketCap
if(!(Get-Module -Name CoinMarketCap)){
    try{
        Install-Module -ModulePath "$ScriptPath\CoinMarketCap.psm1"
    } catch {
        Write-Error "Unable to load API module"
        Exit
    }
}

Function ConvertFrom-Unix($UnixDate) {
    [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
}

#Load config data or create initial data
$ConfigLocation = "$env:LOCALAPPDATA\CryptoTrackr\config.csv"
if(Test-Path $ConfigLocation){
    $Config = Import-Csv $ConfigLocation
} else {
    #Build blank config file
    if(!(Test-Path(Split-Path $ConfigLocation))){
        New-Item (Split-Path $ConfigLocation) -ItemType Directory -Force | Out-Null
    }
    
    [PSCustomObject]@{
        Symbols = "BTC"
        Coins = 1
    } | Export-Csv $ConfigLocation -NoTypeInformation

    $Config = Import-Csv $ConfigLocation
}

$ActiveConfig = @()
$BuildConfig = [ordered]@{}
foreach($Coin in $Config){
    $BuildConfig.Symbols = $Coin.Symbols
    $BuildConfig.Coins = $Coin.Coins

    $ActiveConfig += [PSCustomObject]$BuildConfig
}

#Initialize Menu System
$Title = "Crypto Trackr"
$Message = "Please enter a command:"

$r = New-Object System.Management.Automation.Host.ChoiceDescription "&Refresh data", `
    "Refreshes coin data."

$c = New-Object System.Management.Automation.Host.ChoiceDescription "&Check coin", `
    "Prompts for a coin identifier to check the latest data for according to CoinMarketCap."

$a = New-Object System.Management.Automation.Host.ChoiceDescription "&Add coin", `
    "Adds a coin to your config."

$m = New-Object System.Management.Automation.Host.ChoiceDescription "&Modify coin", `
    "Add/remove shares for a coin in your config."

$d = New-Object System.Management.Automation.Host.ChoiceDescription "&Delete coin", `
    "Removes a coin from your config."

$e = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit", `
    "Exits Crypto Trackr."

$Options = [System.Management.Automation.Host.ChoiceDescription[]]($r,$c, $a, $m, $d, $e)

$Default = 0

do{
    #Load most recent coin data
    $CoinData = @{}
    ForEach($Coin in $ActiveConfig.Symbols){
        $CoinData[$Coin] = Get-Coin $Coin
    }

    $TotalValue = 0

    Write-Host "Coin Data:`n"
    #Display latest coin values, portfolio total value, and latest update time
    foreach($CoinValue in $CoinData.Values){
        $CurrentCoin = $CoinValue.symbol
        $Shares = ($ActiveConfig | Where-Object Symbols -eq $CurrentCoin).Coins
        $CurrentValue = $CoinValue.price_usd
        $LastUpdated = ConvertFrom-Unix $CoinValue.last_updated

        $TotalCoinValue = [Math]::Round([decimal]::Parse($CurrentValue) * [decimal]::Parse($Shares),2)
        $TotalValue += [decimal]::Parse($TotalCoinValue)

        Write-Host "$CurrentCoin - `$$CurrentValue - Coins: $Shares - Total Value (USD): `$$TotalCoinValue - Last Updated: $LastUpdated"
    }

    Write-Host "`nTotal portfolio: `$$TotalValue`n"

    $Command = $Host.ui.PromptForChoice($Title, $Message, $Options, $Default)
    Clear-Host

    switch($Command){
        0{
            #Do nothing since all we need to do is let coin data refresh
        }

        1{
            #Check coin
            do{
                $CoinToCheck = Read-Host "Enter symbol of coin to check"
                $CoinData = Get-Coin -CoinId $CoinToCheck
                if($CoinData){
                    $CoinData
                }

                $Answer = Read-Host "Check another coin? (Y/N)"
                Write-Host ""
            }while($Answer.ToUpper() -ne "N")
        }

        2{
            #Add coin to config
            $AddCoin = Read-Host "Enter symbol of coin to add to config"
            $CoinCheck = Get-Coin -CoinId $AddCoin

            if($CoinCheck){
                if(![bool]($ActiveConfig -match $AddCoin)){
                    $Shares = Read-Host "How many coins to be added"
                    $BuildCoin = [ordered]@{
                        Symbols = $AddCoin
                        Coins = $Shares
                    }

                    $ActiveConfig += [PSCustomObject]$BuildCoin
                } else {
                    Write-Host -ForegroundColor Red "Error: Coin already added."
                    Start-Sleep -Seconds 2
                }
            } else {
                Write-Host -ForegroundColor Red "Error: Coin ($AddCoin) not found, do you have the correct symbol?"
                Start-Sleep -Seconds 2
            }
        }

        3{
            #Modify coin from config
            $ModifyCoin = Read-Host "Enter symbol of coin to remove from config"
            if([bool]($ActiveConfig -match $ModifyCoin)){
                do{
                    $Action = Read-Host "Add or remove coins? (A/R)"
                }while(($Action.ToUpper() -ne "A") -and ($Action.ToUpper() -ne "R"))

                do{
                    $Amount = Read-Host "How many"
                }until($Amount -ne "")

                $CurrentCoins = ($ActiveConfig | Where-Object Symbols -eq $ModifyCoin).Coins

                if($Action.ToUpper() -eq "A"){
                    #Add coins
                    $ActiveConfig = $ActiveConfig -notmatch $ModifyCoin
                    $NewCoins = [decimal]::Parse($CurrentCoins) + [decimal]::Parse($Amount)

                    $BuildCoin = [ordered]@{
                        Symbols = $ModifyCoin
                        Coins = $NewCoins
                    }

                    $ActiveConfig += [PSCustomObject]$BuildCoin
                } else {
                    #Remove coins
                    $ActiveConfig = $ActiveConfig -notmatch $ModifyCoin
                    $NewCoins = [decimal]::Parse($CurrentCoins) - [decimal]::Parse($Amount)
                    if($NewCoins -ne 0){
                        $BuildCoin = [ordered]@{
                            Symbols = $ModifyCoin
                            Coins = $NewCoins
                        }
    
                        $ActiveConfig += [PSCustomObject]$BuildCoin
                    }
                }
            } else {
                Write-Host -ForegroundColor Red "Error: Coin not loaded into current config."
                Start-Sleep -Seconds 2
            }
        }

        4{
            #Remove coin from config
            $RemoveCoin = Read-Host "Enter symbol of coin to remove from config"
            if([bool]($ActiveConfig.Symbols -match $RemoveCoin)){
                $ActiveConfig = $ActiveConfig -notmatch $RemoveCoin
            } else {
                Write-Host -ForegroundColor Red "Error: Coin not loaded into current config."
                Start-Sleep -Seconds 2
            }
        }
    }
}until($Command -eq 5)

try{
    $ActiveConfig | Export-Csv -Path $ConfigLocation -NoTypeInformation -Force
} catch {
    Write-Host -ForegroundColor Red "Error: Unable to save changes to config"
}