# Admin-context script to set the administrative language defaults, system locale and install optional features for the primary language

# Language codes
$PrimaryLanguage = "en-AU"
$SecondaryLanguage = "en-US"
$PrimaryInputCode = "0c09:00000409"
$SecondaryInputCode = "0409:00000409"
$PrimaryGeoID = "12"

# Enable side-loading
# Required for appx/msix prior to build 18956 (1909 insider)
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowAllTrustedApps -Value 1 -PropertyType DWORD -Force

# Provision Local Experience Pack
$BlobURL = "https://name.blob.core.windows.net/language-packs/en-gb.zip?sp=r&st=2021-01-20T01:00:00Z&se=2021-12-30T14:00:00Z&spr=https&sv=2019-12-12&sr=b&sig=r6%2BuqgqbGhCy5THvT1QDqXdvnd%2F0cGbivF1RSLOlTV8%3D"
$DownloadedFile = "$env:LOCALAPPDATA\en-GB.zip"
Try
{
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($BlobURL, $DownloadedFile)
    Unblock-File -Path $DownloadedFile -ErrorAction SilentlyContinue
    Expand-Archive -Path $DownloadedFile -DestinationPath $env:LOCALAPPDATA -Force -ErrorAction Stop
    Add-AppxProvisionedPackage -Online -PackagePath "$env:LOCALAPPDATA\en-gb\LanguageExperiencePack.en-gb.Neutral.appx" -LicensePath "$env:LOCALAPPDATA\en-gb\License.xml" -ErrorAction Stop
    Remove-Item -Path $DownloadedFile -Force -ErrorAction SilentlyContinue
}
Catch
{
    Write-Host "Failed to install Local Experience Pack: $_"
}

# Install optional features for primary language
$UKCapabilities = Get-WindowsCapability -Online | Where {$_.Name -match "$PrimaryLanguage" -and $_.State -ne "Installed"}
$UKCapabilities | foreach {
    Add-WindowsCapability -Online -Name $_.Name
}

# Apply custom XML to set administrative language defaults
$XML = @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
 
<!-- user list --> 
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/> 
    </gs:UserList>
 
    <!-- GeoID -->
    <gs:LocationPreferences> 
        <gs:GeoID Value="$PrimaryGeoID"/>
    </gs:LocationPreferences>
 
    <gs:MUILanguagePreferences>
        <gs:MUILanguage Value="$PrimaryLanguage"/>
        <gs:MUIFallback Value="$SecondaryLanguage"/>
    </gs:MUILanguagePreferences>
 
    <!-- system locale -->
    <gs:SystemLocale Name="$PrimaryLanguage"/>
 
    <!-- input preferences -->
    <gs:InputPreferences>
        <gs:InputLanguageID Action="add" ID="$PrimaryInputCode" Default="true"/>
        <gs:InputLanguageID Action="add" ID="$SecondaryInputCode"/>
      </gs:InputPreferences>
 
    <!-- user locale -->
    <gs:UserLocale>
        <gs:Locale Name="$PrimaryLanguage" SetAsCurrent="true" ResetAllSettings="false"/>
    </gs:UserLocale>
 </gs:GlobalizationServices>
"@

New-Item -Path $env:TEMP -Name "en-GB.xml" -ItemType File -Value $XML -Force

$Process = Start-Process -FilePath Control.exe -ArgumentList "intl.cpl,,/f:""$env:Temp\en-GB.xml""" -NoNewWindow -PassThru -Wait
$Process.ExitCode