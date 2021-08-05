$Path = "HKLM:\Software\policies\Microsoft\Windows NT\Terminal Services"
$Name = "fAllowToGetHelp"
$value = "0"
If (!(Test-Path $Path))
 {
    New-Item -Path $Path -Force | Out-Null
    New-ItemProperty -Path $Path -Name $Name -Value $value -PropertyType DWORD -Force | Out-Null
}
  ELSE
{
    New-ItemProperty -Path $Path -Name $Name -Value $value -PropertyType DWORD -Force | Out-Null
}