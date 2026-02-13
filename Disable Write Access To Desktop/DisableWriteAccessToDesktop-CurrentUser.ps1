# Define the Desktop path for the current user
$DesktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")

# Get the current ACL (Access Control List)
$Acl = Get-Acl $DesktopPath

# Create a new access rule to Deny Write and Append Data
# Parameters: Identity, Rights, Access Control Type
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME,
    "Write,AppendData",
    "Deny"
)

# Apply the rule to the ACL and save it back to the folder
$Acl.AddAccessRule($Ar)
Set-Acl $DesktopPath $Acl

Write-Host "Saving files to Desktop has been disabled for $env:USERNAME." -ForegroundColor Yellow