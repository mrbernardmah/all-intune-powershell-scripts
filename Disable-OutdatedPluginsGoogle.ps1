#Registry Entry Creation
Set-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome' -Name AllowOutdatedPlugins -Type "DWord" -Value "0"
