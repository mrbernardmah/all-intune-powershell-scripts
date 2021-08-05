Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install 7zip --force -y
choco install choco-upgrade-all-at --params "'/WEEKLY:yes /DAY:FRI /TIME:13:00 /ABORTTIME:15:00'" --force -y