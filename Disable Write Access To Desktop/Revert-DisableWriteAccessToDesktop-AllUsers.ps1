$UserProfiles = Get-ChildItem "C:\Users" | Where-Object { $_.PSIsContainer -and $_.Name -notmatch "Public|Default|All Users" }

foreach ($Profile in $UserProfiles) {
    $DesktopPath = Join-Path $Profile.FullName "Desktop"
   
    if (Test-Path $DesktopPath) {
        $Acl = Get-Acl $DesktopPath
       
        # Define the exact rule that was applied previously
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $Profile.Name,
            "Write,AppendData",
            "Deny"
        )
       
        # Remove that specific rule from the ACL
        $Acl.RemoveAccessRule($Ar)
       
        # Apply the cleaned ACL back to the folder
        Set-Acl $DesktopPath $Acl
        Write-Host "Restored Desktop access for: $($Profile.Name)"
    }
}