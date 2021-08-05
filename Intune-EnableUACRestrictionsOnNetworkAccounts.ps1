$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\"
$Name = "LocalAccountTokenFilterPolicy"
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