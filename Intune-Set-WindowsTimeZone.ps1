[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [parameter(Mandatory = $false, HelpMessage = "Specify the Azure Maps API shared key available under the Authentication blade of the resource in Azure.")]
    [ValidateNotNullOrEmpty()]
    [string]$AzureMapsSharedKey = "AzureMapSharedKeys"
)
Process {
    # Functions
    function Write-LogEntry {
        param (
            [parameter(Mandatory = $true, HelpMessage = "Value added to the log file.")]
            [ValidateNotNullOrEmpty()]
            [string]$Value,

            [parameter(Mandatory = $true, HelpMessage = "Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
            [string]$Severity
        )
        # Determine log file location
        $LogFilePath = Join-Path -Path (Join-Path -Path $env:windir -ChildPath "Temp") -ChildPath "Set-WindowsTimeZone.log"
        
        # Construct time stamp for log entry
        if (-not(Test-Path -Path 'variable:global:TimezoneBias')) {
            [string]$global:TimezoneBias = [System.TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalMinutes
            if ($TimezoneBias -match "^-") {
                $TimezoneBias = $TimezoneBias.Replace('-', '+')
            }
            else {
                $TimezoneBias = '-' + $TimezoneBias
            }
        }
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), $TimezoneBias)
        
        # Construct date for log entry
        $Date = (Get-Date -Format "MM-dd-yyyy")
        
        # Construct context for log entry
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        
        # Construct final log entry
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""WindowsTimeZone"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
        
        # Add value to log file
        try {
            Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to Set-WindowsTimeZone.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
        }
    }

    function Get-GeoCoordinate {
        # Construct return value object
        $Coordinates = [PSCustomObject]@{
            Latitude = $null
            Longitude = $null
        }

        Write-LogEntry -Value "Attempting to start resolving the current device coordinates" -Severity 1
        $GeoCoordinateWatcher = New-Object -TypeName "System.Device.Location.GeoCoordinateWatcher"
        $GeoCoordinateWatcher.Start()

        # Wait until watcher resolves current location coordinates
        $GeoCounter = 0
        while (($GeoCoordinateWatcher.Status -notlike "Ready") -and ($GeoCoordinateWatcher.Permission -notlike "Denied") -and ($GeoCounter -le 60)) {
            Start-Sleep -Seconds 1
            $GeoCounter++
        }

        # Break operation and return empty object since permission was denied
        if ($GeoCoordinateWatcher.Permission -like "Denied") {
            Write-LogEntry -Value "Permission was denied accessing coordinates from location services" -Severity 3

            # Stop and dispose of the GeCoordinateWatcher object
            $GeoCoordinateWatcher.Stop()
            $GeoCoordinateWatcher.Dispose()

            # Handle return error
            return $Coordinates
        }

        # Set coordinates for return value
        $Coordinates.Latitude = ($GeoCoordinateWatcher.Position.Location.Latitude).ToString().Replace(",", ".")
        $Coordinates.Longitude = ($GeoCoordinateWatcher.Position.Location.Longitude).ToString().Replace(",", ".")

        # Stop and dispose of the GeCoordinateWatcher object
        $GeoCoordinateWatcher.Stop()
        $GeoCoordinateWatcher.Dispose()

        # Handle return value
        return $Coordinates
    }

    function Enable-LocationServices {
        $LocationConsentKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
        Write-LogEntry -Value "Checking registry key presence: $($LocationConsentKey)" -Severity 1
        if (-not(Test-Path -Path $LocationConsentKey)) {
            Write-LogEntry -Value "Presence of '$($LocationConsentKey)' key was not detected, attempting to create it" -Severity 1
            New-Item -Path $LocationConsentKey -Force | Out-Null
        }
        
        $LocationConsentValue = Get-ItemPropertyValue -Path $LocationConsentKey -Name "Value"
        Write-LogEntry -Value "Checking registry value 'Value' configuration in key: $($LocationConsentKey)" -Severity 1
        if ($LocationConsentValue -notlike "Allow") {
            Write-LogEntry -Value "Registry value 'Value' configuration mismatch detected, setting value to: Allow" -Severity 1
            Set-ItemProperty -Path $LocationConsentKey -Name "Value" -Type "String" -Value "Allow" -Force
        }
        
        $SensorPermissionStateRegValue = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
        $SensorPermissionStateValue = Get-ItemPropertyValue -Path $SensorPermissionStateRegValue -Name "SensorPermissionState"
        Write-LogEntry -Value "Checking registry value 'SensorPermissionState' configuration in key: $($SensorPermissionStateRegValue)" -Severity 1
        if ($SensorPermissionStateValue -ne 1) {
            Write-LogEntry -Value "Registry value 'SensorPermissionState' configuration mismatch detected, setting value to: 1" -Severity 1
            Set-ItemProperty -Path $SensorPermissionStateRegValue -Name "SensorPermissionState" -Type "DWord" -Value 1 -Force
        }
        
        $LocationServiceStatusRegValue = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
        Write-LogEntry -Value "Checking registry key presence: $($LocationServiceStatusRegValue)" -Severity 1
        if (-not(Test-Path -Path $LocationServiceStatusRegValue)) {
            Write-LogEntry -Value "Presence of '$($LocationServiceStatusRegValue)' key was not detected, attempting to create it" -Severity 1
            Set-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration' -Name Status -Type "DWord" -Value "1"
        }

        $LocationServiceStatusValue = Get-ItemPropertyValue -Path $LocationServiceStatusRegValue -Name "Status"
        Write-LogEntry -Value "Checking registry value 'Status' configuration in key: $($LocationServiceStatusRegValue)" -Severity 1
        if ($LocationServiceStatusValue -ne 1) {
            Write-LogEntry -Value "Registry value 'Status' configuration mismatch detected, setting value to: 1" -Severity 1
            Set-ItemProperty -Path $LocationServiceStatusRegValue -Name "Status" -Type "DWord" -Value 1 -Force
        }

        $LocationService = Get-Service -Name "lfsvc"
        Write-LogEntry -Value "Checking location service 'lfsvc' for status: Running" -Severity 1
        if ($LocationService.Status -notlike "Running") {
            Write-LogEntry -Value "Location service is not running, attempting to start service" -Severity 1
            Start-Service -Name "lfsvc"
        }
    }

    Write-LogEntry -Value "Starting to determine the desired Windows time zone configuration" -Severity 1

    try {
        # Load required assembly and construct a GeCoordinateWatcher object
        Write-LogEntry -Value "Attempting to load required 'System.Device' assembly" -Severity 1
        Add-Type -AssemblyName "System.Device" -ErrorAction Stop

        try {
            # Ensure Location Services in Windows is enabled and service is running
            Enable-LocationServices

            # Retrieve the latitude and longitude values
            $GeoCoordinates = Get-GeoCoordinate
            if (($GeoCoordinates.Latitude -ne $null) -and ($GeoCoordinates.Longitude -ne $null)) {
                Write-LogEntry -Value "Successfully resolved current device coordinates" -Severity 1
                Write-LogEntry -Value "Detected latitude: $($GeoCoordinates.Latitude)" -Severity 1
                Write-LogEntry -Value "Detected longitude: $($GeoCoordinates.Longitude)" -Severity 1

                # Construct query string for Azure Maps API request
                $AzureMapsQuery = -join@($GeoCoordinates.Latitude, ",", $GeoCoordinates.Longitude)

                try {
                    # Call Azure Maps timezone/byCoordinates API to retrieve IANA time zone id
                    Write-LogEntry -Value "Attempting to determine IANA time zone id from Azure MAPS API using query: $($AzureMapsQuery)" -Severity 1
                    $AzureMapsTimeZoneURI = "https://atlas.microsoft.com/timezone/byCoordinates/json?subscription-key=$($AzureMapsSharedKey)&api-version=1.0&options=all&query=$($AzureMapsQuery)"
                    $AzureMapsTimeZoneResponse = Invoke-RestMethod -Uri $AzureMapsTimeZoneURI -Method "Get" -ErrorAction Stop
                    if ($AzureMapsTimeZoneResponse -ne $null) {
                        $IANATimeZoneValue = $AzureMapsTimeZoneResponse.TimeZones.Id
                        Write-LogEntry -Value "Successfully retrieved IANA time zone id from current position data: $($IANATimeZoneValue)" -Severity 1

                        try {
                            # Call Azure Maps timezone/enumWindows API to retrieve the Windows time zone id
                            Write-LogEntry -Value "Attempting to Azure Maps API to enumerate Windows time zone ids" -Severity 1
                            $AzureMapsWindowsEnumURI = "https://atlas.microsoft.com/timezone/enumWindows/json?subscription-key=$($AzureMapsSharedKey)&api-version=1.0"
                            $AzureMapsWindowsEnumResponse = Invoke-RestMethod -Uri $AzureMapsWindowsEnumURI -Method "Get" -ErrorAction Stop
                            if ($AzureMapsWindowsEnumResponse -ne $null) {
                                $TimeZoneID = $AzureMapsWindowsEnumResponse | Where-Object { ($PSItem.IanaIds -like $IANATimeZoneValue) -and ($PSItem.Territory.Length -eq 2) } | Select-Object -ExpandProperty WindowsId
                                Write-LogEntry -Value "Successfully determined the Windows time zone id: $($TimeZoneID)" -Severity 1

                                try {
                                    # Set the time zone
                                    Write-LogEntry -Value "Attempting to configure the Windows time zone id with value: $($TimeZoneID)" -Severity 1
                                    Set-TimeZone -Id $TimeZoneID -ErrorAction Stop
                                    Write-LogEntry -Value "Successfully configured the Windows time zone" -Severity 1
                                }
                                catch [System.Exception] {
                                    Write-LogEntry -Value "Failed to set Windows time zone. Error message: $($PSItem.Exception.Message)" -Severity 3
                                }
                            }
                            else {
                                Write-LogEntry -Value "Invalid response from Azure Maps call enumerating Windows time zone ids" -Severity 3
                            }
                        }
                        catch [System.Exception] {
                            Write-LogEntry -Value "Failed to call Azure Maps API to enumerate Windows time zone ids. Error message: $($PSItem.Exception.Message)" -Severity 3
                        }
                    }
                    else {
                        Write-LogEntry -Value "Invalid response from Azure Maps query when attempting to retrieve the IANA time zone id" -Severity 3
                    }
                }
                catch [System.Exception] {
                    Write-LogEntry -Value "Failed to retrieve the IANA time zone id based on current position data from Azure Maps. Error message: $($PSItem.Exception.Message)" -Severity 3
                }
            }
            else {
                Write-LogEntry -Value "Unable to determine current device coordinates from location services, breaking operation" -Severity 3
            }
        }
        catch [System.Exception] {
            Write-LogEntry -Value "Failed to determine Windows time zone. Error message: $($PSItem.Exception.Message)" -Severity 3
        }
    }
    catch [System.Exception] {
        Write-LogEntry -Value "Failed to load required 'System.Device' assembly, breaking operation" -Severity 3
    }
}
