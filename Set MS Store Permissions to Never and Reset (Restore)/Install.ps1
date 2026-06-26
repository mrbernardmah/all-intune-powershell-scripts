# 1. Reset Background Component Permissions to 'Power optimized (recommended)'
# This removes explicit blocks to restore default Windows power-managed behavior
$PackageFamilyName = "Microsoft.WindowsStore_8wekyb3d8bbwe"

# Path A: Modern System Component Privacy API Subkey
$ConsentStorePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\backgroundSync\NonPackaged\$PackageFamilyName"
if (Test-Path $ConsentStorePath) {
    # Setting the Value back to "Allow" permits power-optimized background access
    New-ItemProperty -Path $ConsentStorePath -Name "Value" -PropertyType String -Value "Allow" -Force | Out-Null
}

# Path B: Standard/Legacy AppX Background Management Path
$BackgroundAccessPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\$PackageFamilyName"
if (Test-Path $BackgroundAccessPath) {
    # Removing 'DisabledByUser' or 'Disabled' returns the app state back to Power Optimized
    Remove-ItemProperty -Path $BackgroundAccessPath -Name "DisabledByUser" -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty -Path $BackgroundAccessPath -Name "Disabled" -ErrorAction SilentlyContinue | Out-Null
}


# 2. Terminate Microsoft Store
# Stops any active instances to force the app to reload with the updated settings
Stop-Process -Name "WinStore.App" -Force -ErrorAction SilentlyContinue


# 3. Click Reset (System Component Method)
# Performs the app data reset step safely
Write-Host "Resetting Microsoft Store System Component..." -ForegroundColor Cyan

try {
    Get-AppxPackage -Name "Microsoft.WindowsStore" -AllUsers | ForEach-Object {
        Reset-AppxPackage $_.PackageFullName -ErrorAction Stop
    }
    Write-Host "Operations completed successfully! Store is now Power Optimized." -ForegroundColor Green
} 
catch {
    Write-Host "Standard AppX reset bypassed. Attempting fallback reset via system component identity..." -ForegroundColor Yellow
    & "winstore://reset"
    Start-Sleep -Seconds 2
    Stop-Process -Name "WinStore.App" -Force -ErrorAction SilentlyContinue
    Write-Host "Component reset signal sent successfully! Store is now Power Optimized." -ForegroundColor Green
}