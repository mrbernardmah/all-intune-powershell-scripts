# Directly target the 'Staff' profile folder
$StaffProfile = Get-Item "C:\Users\Staff" -ErrorAction SilentlyContinue

if ($StaffProfile) {
    $DesktopPath = Join-Path $StaffProfile.FullName "Desktop"
    
    if (Test-Path $DesktopPath) {
        $Acl = Get-Acl $DesktopPath
        
        # Create the Deny rule for the user 'Staff'
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Staff",
            "Write,AppendData",
            "Deny"
        )
        
        $Acl.AddAccessRule($Ar)
        Set-Acl $DesktopPath $Acl
        
        Write-Host "Successfully locked Desktop for: Staff" -ForegroundColor Green
    } else {
        Write-Warning "Desktop folder not found for Staff profile."
    }
} else {
    Write-Error "Profile folder 'Staff' does not exist in C:\Users."
}