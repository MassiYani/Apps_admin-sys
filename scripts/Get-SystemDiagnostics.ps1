[CmdletBinding()]
param (
    [string]$ComputerName = "localhost",
    [string]$Action
)

$ErrorActionPreference = "SilentlyContinue"

# Fonction VITALE : Force PS à garder le format JSON correct
function Convert-ToJsonSafe {
    param($Data, $Depth = 3)
    if ($null -eq $Data) { ConvertTo-Json -InputObject @() -Compress }
    elseif ($Data -is [array]) { ConvertTo-Json -InputObject $Data -Depth $Depth -Compress }
    else { ConvertTo-Json -InputObject @($Data) -Depth $Depth -Compress }
}

try {
    if ($Action -eq "system") {
        $OS = Get-CimInstance Win32_OperatingSystem -ComputerName $ComputerName
        
        $SysInfo = Get-CimInstance Win32_ComputerSystem -ComputerName $ComputerName
        $LogicalCores = $SysInfo.NumberOfLogicalProcessors
        if (-not $LogicalCores -or $LogicalCores -eq 0) { $LogicalCores = 1 }
        
        $DisplayVersion = $null
        if ($ComputerName -in @("localhost", "127.0.0.1", $env:COMPUTERNAME)) {
            $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
            $DisplayVersion = if ($reg.DisplayVersion) { $reg.DisplayVersion } else { $reg.ReleaseId }
        } else {
            $RegRemote = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
            $RegKey = $RegRemote.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion")
            $DisplayVersion = $RegKey.GetValue("DisplayVersion")
            if (-not $DisplayVersion) { $DisplayVersion = $RegKey.GetValue("ReleaseId") }
        }
        
        $OS_Full = if ($DisplayVersion) { "$($OS.Caption) $DisplayVersion (Build $($OS.Version))" } else { "$($OS.Caption) (Build $($OS.Version))" }

        $IPs = try {
            (Get-CimInstance Win32_NetworkAdapterConfiguration -ComputerName $ComputerName | 
                Where-Object { $_.IPEnabled -eq $true }).IPAddress | 
                Where-Object { $_ -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' -and $_ -notlike "127.*" -and $_ -notlike "169.254.*" }
        } catch { @() }
        $IP_String = if ($IPs) { $IPs -join ", " } else { "Inconnue / Déconnecté" }

        $TopCPU = try {
            Get-CimInstance Win32_PerfFormattedData_PerfProc_Process -ComputerName $ComputerName |
                Where-Object { $_.Name -notin @("_Total", "Idle") } |
                Sort-Object PercentProcessorTime -Descending | Select-Object -First 10 |
                ForEach-Object { 
                    $RealCPU = [math]::Round($_.PercentProcessorTime / $LogicalCores, 1)
                    @{ "Name"=$_.Name; "CPU"=$RealCPU } 
                }
        } catch {
            Get-CimInstance Win32_Process -ComputerName $ComputerName | 
                Sort-Object WorkingSetSize -Descending | Select-Object -First 10 |
                ForEach-Object { @{ "Name"=$_.Name; "CPU"="N/A" } }
        }

        $TopRAM = Get-CimInstance Win32_Process -ComputerName $ComputerName | 
            Sort-Object WorkingSetSize -Descending | Select-Object -First 10 | 
            ForEach-Object { @{ "Name"=$_.Name; "RAM_MB"=[math]::Round($_.WorkingSetSize / 1MB, 0) } }
        # --- NOUVEAU : Calcul du CPU Global ---
        $TotalCPU = try {
            (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ComputerName $ComputerName -ErrorAction Stop).PercentProcessorTime
        } catch {
            (Get-CimInstance Win32_Processor -ComputerName $ComputerName | Measure-Object -Property LoadPercentage -Average).Average
        }
        if ($null -eq $TotalCPU) { $TotalCPU = 0 }

        # --- NOUVEAU : Calcul de la RAM Globale ---
        $TotalRAM_KB = $OS.TotalVisibleMemorySize
        $FreeRAM_KB = $OS.FreePhysicalMemory
        $UsedRAM_GB = [math]::Round(($TotalRAM_KB - $FreeRAM_KB) / 1MB, 1)
        $RAMUsagePct = if ($TotalRAM_KB -gt 0) { [math]::Round((($TotalRAM_KB - $FreeRAM_KB) / $TotalRAM_KB) * 100, 1) } else { 0 }
        # --- MISE À JOUR de l'objet renvoyé ---
        $out = @{ 
            "OS" = $OS_Full; 
            "IP" = $IP_String;
            "CPU_Model" = $OS.OSArchitecture + " | " + (Get-CimInstance Win32_Processor -ComputerName $ComputerName | Select-Object -First 1).Name; 
            "RAM_Total" = [math]::Round($TotalRAM_KB / 1MB, 0); 
            "CPU_Usage" = $TotalCPU;         # Ajout du % CPU
            "RAM_UsagePct" = $RAMUsagePct;   # Ajout du % RAM
            "RAM_UsedGB" = $UsedRAM_GB;      # Ajout de la RAM utilisée en Go
            "TopCPU" = $TopCPU; 
            "TopRAM" = $TopRAM 
        }
        ConvertTo-Json -InputObject $out -Depth 3 -Compress
    }
    elseif ($Action -eq "disks") {
        $data = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $ComputerName | ForEach-Object {
            $T = [math]::Round($_.Size / 1GB, 0); $F = [math]::Round($_.FreeSpace / 1GB, 0)
            $P = if ($T -gt 0) { [math]::Round((($T - $F) / $T) * 100, 1) } else { 0 }
            @{ "Drive"=$_.DeviceID; "Total"=$T; "Free"=$F; "UsedPct"=$P }
        }
        Convert-ToJsonSafe -Data $data
    }
    elseif ($Action -eq "gpos") {
        $GPOs = @()
        try {
            $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
            $RegPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History"
            $HistoryKey = $Reg.OpenSubKey($RegPath)
            if ($HistoryKey) {
                foreach ($SubKeyName in $HistoryKey.GetSubKeyNames()) {
                    $SubKey = $HistoryKey.OpenSubKey($SubKeyName)
                    foreach ($Index in $SubKey.GetSubKeyNames()) {
                        $GPKey = $SubKey.OpenSubKey($Index)
                        $GPName = $GPKey.GetValue("DisplayName")
                        if ($GPName -and $GPOs -notcontains $GPName) { $GPOs += $GPName }
                    }
                }
            }
        } catch {}
        
        if ($GPOs.Count -eq 0) {
            $GPOs += "Aucune GPO détectée dans l'historique local (Hors-domaine ou cache vide)"
        }
        Convert-ToJsonSafe -Data $GPOs
    }
    elseif ($Action -eq "ports") {
        if ($ComputerName -in @("localhost", "127.0.0.1", $env:COMPUTERNAME)) {
            $PortMap = @{
                21="FTP"; 22="SSH"; 23="Telnet"; 25="SMTP"; 53="DNS"; 80="HTTP (Web)"; 
                110="POP3"; 123="NTP"; 135="RPC"; 139="NetBIOS"; 143="IMAP"; 
                161="SNMP"; 162="SNMP-Trap"; 389="LDAP"; 443="HTTPS (Web)"; 445="SMB (Partage)"; 
                500="IPsec"; 3306="MySQL"; 3389="RDP (Bureau Distant)"; 5432="PostgreSQL"; 8080="HTTP-Alt"
            }

            $tcp = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object LocalPort, OwningProcess, @{Name="Proto";Expression={"TCP"}}
            $udp = Get-NetUDPEndpoint -ErrorAction SilentlyContinue | Select-Object LocalPort, OwningProcess, @{Name="Proto";Expression={"UDP"}}
            
            $data = @($tcp; $udp) | Where-Object { $_.LocalPort } | ForEach-Object {
                $portVal = $_.LocalPort
                $pid_val = $_.OwningProcess
                $proc = try { (Get-Process -Id $pid_val -ErrorAction Stop).ProcessName } catch { "System" }
                $appName = if ($PortMap.ContainsKey($portVal)) { $PortMap[$portVal] } else { "-" }
                
                @{ "Port"=$portVal; "Proto"=$_.Proto; "Service"=$proc; "PID"=$pid_val; "App"=$appName }
            } | Select-Object -Unique Port, Proto, Service, PID, App | Sort-Object Port
            
            Convert-ToJsonSafe -Data $data
        } else {
            Convert-ToJsonSafe -Data @(@{ "Port"="N/A"; "Proto"="N/A"; "Service"="Requiert exécution locale"; "PID"="N/A"; "App"="N/A" })
        }
    }
    elseif ($Action -eq "services") {
        $services = try {
            Get-CimInstance Win32_Service -ComputerName $ComputerName | 
                Select-Object Name, DisplayName, State, StartMode | 
                ForEach-Object {
                    @{
                        "Name"        = $_.Name
                        "DisplayName" = $_.DisplayName
                        "State"       = $_.State
                        "StartMode"   = $_.StartMode
                    }
                }
        } catch {
            @(@{ "Name"="Erreur"; "DisplayName"="Accès WMI refusé"; "State"="N/A"; "StartMode"="N/A" })
        }
        Convert-ToJsonSafe -Data $services
    }
    elseif ($Action -eq "reboots") {
        $events = try {
            Get-WinEvent -ComputerName $ComputerName -FilterHashtable @{LogName="System"; Id=1074,6006,6008} -MaxEvents 50 -ErrorAction Stop |
                ForEach-Object {
                    $responsible = if ($_.Id -eq 1074 -and $_.Properties.Count -ge 7) { $_.Properties[6].Value } else { "Système / non déterminé" }
                    @{ "Time"=$_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss"); "EventID"=$_.Id; "Source"=$_.ProviderName; "Account"=$responsible; "Message"=($_.Message -replace "`n|`r", " ") }
                }
        } catch { @(@{ "Time"="-"; "EventID"="-"; "Source"="Erreur"; "Account"="-"; "Message"="Impossible de lire l'historique des redémarrages." }) }
        Convert-ToJsonSafe -Data $events
    }
    elseif ($Action -eq "events") {
        $events = try {
            Get-WinEvent -ComputerName $ComputerName -FilterHashtable @{LogName=@('System','Application'); Level=2,3} -MaxEvents 200 -ErrorAction Stop | 
                ForEach-Object {
                    @{
                        "Time"    = $_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                        "Log"     = $_.LogName
                        "Source"  = $_.ProviderName
                        "EventID" = $_.Id
                        "Level"   = $_.LevelDisplayName
                        "Message" = $_.Message -replace "`n|`r", " "
                    }
                }
        } catch {
            @(@{ "Time"="-"; "Log"="-"; "Source"="Erreur"; "EventID"="-"; "Level"="Error"; "Message"="Impossible de lire les événements." })
        }
        Convert-ToJsonSafe -Data $events
    }
} catch {
    Convert-ToJsonSafe -Data @{ "Error" = "Erreur fatale PS: $($_.Exception.Message)" }
}
