<#
.SYNOPSIS
    Install Chrome and create the registry key to trigger installation of Chrome extension.
.DESCRIPTION
    This script installs Google Chrome by using Chocolatey and creates the registry key that will trigger the installation of the Chrome extension.
    This script is created for usage with Microsoft Intune, which doesn't support parameters yet.
.NOTES
    Author: Peter van der Woude
    Contact: pvanderwoude@hotmail.com
    Date published: 02-07-2018
    Current version: 1.0
.LINK
    http://www.petervanderwoude.nl
.EXAMPLE
    Install-ChromeExtension.ps1
#>

#Set variables as input for the script
$ChocoPackages = @("googlechrome")
$ChocoInstall = Join-Path ([System.Environment]::GetFolderPath("CommonApplicationData")) "Chocolatey\bin\choco.exe"
$KeyPath = "HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist"
$KeyName = "1"
$KeyType = "String"
$KeyValue = "aeblfdkhhhdcdjpifhhbdiojplfjncoa;https://clients2.google.com/service/update2/crx"
$KeyName = "2"
$KeyType = "String"
$KeyValue = "echcggldkblhodogklpincgchnpgcdco;https://clients2.google.com/service/update2/crx"


#Verify if Chocolatey is installed
if(!(Test-Path $ChocoInstall)) {
    try {
        #Install Chocolatey
        Invoke-Expression ((New-Object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop
    }
    catch {
        Write-Output "FAILED to install Chocolatey"
    }       
}

#Run through the required Chocolatey packages 
foreach($Package in $ChocoPackages) {
    try {
        #Install Chocolatey package
        Invoke-Expression "cmd.exe /c $ChocoInstall Install $Package -y" -ErrorAction Stop
    }
    catch {
        Write-Output "FAILED to install $Package"
    }
}

#Verify if the registry path already exists
if(!(Test-Path $KeyPath)) {
    try {
        #Create registry path
        New-Item -Path $KeyPath -ItemType RegistryKey -Force -ErrorAction Stop
    }
    catch {
        Write-Output "FAILED to create the registry path"
    }
}

#Verify if the registry key already exists
if(!((Get-ItemProperty $KeyPath).$KeyName)) {
    try {
        #Create registry key 
        New-ItemProperty -Path $KeyPath -Name $KeyName -PropertyType $KeyType -Value $KeyValue
    }
    catch {
        Write-Output "FAILED to create the registry key"
    }
}