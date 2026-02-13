$UserProfiles = Get-ChildItem "C:\Users" | Where-Object { $_.PSIsContainer -and $_.Name -notmatch "Public|Default|All Users" }

foreach ($Profile in $UserProfiles) {
    $DesktopPath = Join-Path $Profile.FullName "Desktop"
   
    if (Test-Path $DesktopPath) {
        $Acl = Get-Acl $DesktopPath
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $Profile.Name,
            "Write,AppendData",
            "Deny"
        )
        $Acl.AddAccessRule($Ar)
        Set-Acl $DesktopPath $Acl
        Write-Host "Locked Desktop for: $($Profile.Name)"
    }
}