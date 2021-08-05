#Registry Entry Creation

$RegKeyExists = 'HKLM:\SOFTWARE\Microsoft\Settings\'

$RegKeyPath = 'HKLM:\SOFTWARE\Microsoft\'

if(-not (Test-Path $RegKeyExists)){

    New-Item -Path $RegKeyPath -Name 'Settings' -Force
	
	$RegKeyPath = 'HKLM:\SOFTWARE\Microsoft\Settings'
	New-Item -Path $RegKeyPath -Name 'FindMyDevice' -Force

    $RegKeyPath = 'HKLM:\SOFTWARE\Microsoft\Settings\FindMyDevice'
}	Set-ItemProperty -Path Registry::'HKLM\SOFTWARE\Microsoft\Settings\FindMyDevice' -Name LocationSyncEnabled -Type "DWord" -Value "1" -Force
