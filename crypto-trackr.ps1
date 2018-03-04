################################################
# Title: Crypto Trackr                         #
# Created by: Nathan Kasco                     #
# Date Started: 2/24/2018                      #
################################################

$ErrorActionPreference = "SilentlyContinue"
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path

#Install CoinMarketCap Module - Credit: https://github.com/lazywinadmin/CoinMarketCap
if(!(Get-Module -Name CoinMarketCap)){
    try{
        Install-Module -ModulePath "$ScriptPath\CoinMarketCap\CoinMarketCap.psm1"
    } catch {
        Write-Error "Unable to load API module"
        Exit
    }
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

#Load most recent coin data
$Coins = @{}
ForEach($Coin in $Config.Coins){
    $Coins[$Coin] = Get-Coin $Coin
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#region begin GUI{ 

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '915,600'
$Form.text                       = "Crypto Trackr"
$Form.TopMost                    = $false
$Form.MaximizeBox                = $false

$ProgressBar1                    = New-Object system.Windows.Forms.ProgressBar
$ProgressBar1.width              = 60
$ProgressBar1.height             = 22
$ProgressBar1.location           = New-Object System.Drawing.Point(853,575)

$LabelTitle                      = New-Object system.Windows.Forms.Label
$LabelTitle.text                 = "Title"
$LabelTitle.AutoSize             = $true
$LabelTitle.width                = 25
$LabelTitle.height               = 10
$LabelTitle.location             = New-Object System.Drawing.Point(139,17)
$LabelTitle.Font                 = 'Microsoft Sans Serif,18'

$ButtonDashboard                 = New-Object system.Windows.Forms.Button
$ButtonDashboard.text            = "Dashboard"
$ButtonDashboard.width           = 111
$ButtonDashboard.height          = 37
$ButtonDashboard.location        = New-Object System.Drawing.Point(11,9)
$ButtonDashboard.Font            = 'Microsoft Sans Serif,10'

$ButtonCoins                     = New-Object system.Windows.Forms.Button
$ButtonCoins.text                = "Coins"
$ButtonCoins.width               = 111
$ButtonCoins.height              = 37
$ButtonCoins.location            = New-Object System.Drawing.Point(11,54)
$ButtonCoins.Font                = 'Microsoft Sans Serif,10'

$ButtonTrends                    = New-Object system.Windows.Forms.Button
$ButtonTrends.text               = "Market Watch"
$ButtonTrends.width              = 111
$ButtonTrends.height             = 37
$ButtonTrends.location           = New-Object System.Drawing.Point(11,99)
$ButtonTrends.Font               = 'Microsoft Sans Serif,10'

$ButtonClose                     = New-Object system.Windows.Forms.Button
$ButtonClose.text                = "Exit"
$ButtonClose.width               = 111
$ButtonClose.height              = 37
$ButtonClose.location            = New-Object System.Drawing.Point(9,553)
$ButtonClose.Font                = 'Microsoft Sans Serif,10'

$PanelContent                    = New-Object system.Windows.Forms.Panel
$PanelContent.height             = 514
$PanelContent.width              = 766
$PanelContent.location           = New-Object System.Drawing.Point(139,48)

$LabelContent                    = New-Object system.Windows.Forms.Label
$LabelContent.text               = "Content"
$LabelContent.AutoSize           = $true
$LabelContent.width              = 510
$LabelContent.height             = 750
$LabelContent.location           = New-Object System.Drawing.Point(5,7)
$LabelContent.Font               = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($ProgressBar1,$LabelTitle,$ButtonDashboard,$ButtonCoins,$ButtonTrends,$ButtonClose,$PanelContent))
$PanelContent.controls.AddRange(@($LabelContent))

#region gui events {
$ButtonClose.Add_Click({ $Form.Close() })

$ButtonDashboard.Add_Click({
    $LabelTitle.Text = "Dashboard"
    $LabelContent.Text = $null
})

$ButtonCoins.Add_Click({
    $LabelTitle.Text = "Coins"
    $LabelContent.Text = $Coins.Values.Name
})

$ButtonTrends.Add_Click({
    $LabelTitle.Text = "Trends"
    $LabelContent.Text = $null
})
#endregion events }

#endregion GUI }

[void]$Form.ShowDialog()