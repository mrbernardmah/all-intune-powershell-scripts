$computer = gc env:computername
$key = "XP2XM-3NXB4-XCHQF-XY8TH-T3BQB"
$service = get-wmiObject -query "select * from SoftwareLicensingService" -computername $computer
$service.InstallProductKey($key)
$service.RefreshLicenseStatus()