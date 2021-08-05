#Registry Entry Creation
Set-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SecurityHealthService' -Name Start -Type "DWord" -Value "2"
