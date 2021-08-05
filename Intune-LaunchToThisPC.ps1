#Registry Entry Creation
Set-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name LaunchTo -Type "DWord" -Value "1"
