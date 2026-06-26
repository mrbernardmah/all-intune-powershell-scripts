# 1. Set Background Component Permissions to 'Never'
# This modifies the registry value governing background permissions for the Microsoft Store package
$PackageFamilyName = "Microsoft.WindowsStore_8wekyb3d8bbwe"
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\$PackageFamilyName"

if (-not (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}
# 'DisabledByUser' (Value: 2) corresponds to setting the permission to "Never"
New-ItemProperty -Path $RegistryPath -Name "DisabledByUser" -PropertyType DWord -Value 2 -Force | Out-Null

# 2. Terminate Microsoft Store
# Stops any running processes related to the Microsoft Store instantly
Stop-Process -Name "WinStore.App" -Force -ErrorAction SilentlyContinue

# 3. Click Reset
# This performs the official AppX package reset, clearing app data just like clicking 'Reset' in Settings
Write-Host "Resetting Microsoft Store..." -ForegroundColor Cyan
Get-AppxPackage -Name "Microsoft.WindowsStore" | Reset-AppxPackage

Write-Host "Operations completed successfully!" -ForegroundColor Green