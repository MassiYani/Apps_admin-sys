# Import du module VMware.PowerCLI
Import-Module VMware.PowerCLI -ErrorAction Stop

# Chargement des assemblies pour Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Création du formulaire principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Informations serveur VMware ESXi"
$form.Size = New-Object System.Drawing.Size(950,750)
$form.StartPosition = "CenterScreen"

# Contrôles de connexion
$labelServer = New-Object System.Windows.Forms.Label
$labelServer.Location = New-Object System.Drawing.Point(10,10)
$labelServer.Size = New-Object System.Drawing.Size(100,20)
$labelServer.Text = "Serveur ESXi:"

$textBoxServer = New-Object System.Windows.Forms.TextBox
$textBoxServer.Location = New-Object System.Drawing.Point(120,10)
$textBoxServer.Size = New-Object System.Drawing.Size(200,20)

$labelUser = New-Object System.Windows.Forms.Label
$labelUser.Location = New-Object System.Drawing.Point(10,40)
$labelUser.Size = New-Object System.Drawing.Size(100,20)
$labelUser.Text = "Utilisateur:"

$textBoxUser = New-Object System.Windows.Forms.TextBox
$textBoxUser.Location = New-Object System.Drawing.Point(120,40)
$textBoxUser.Size = New-Object System.Drawing.Size(200,20)

$labelPassword = New-Object System.Windows.Forms.Label
$labelPassword.Location = New-Object System.Drawing.Point(10,70)
$labelPassword.Size = New-Object System.Drawing.Size(100,20)
$labelPassword.Text = "Mot de passe:"

$textBoxPassword = New-Object System.Windows.Forms.TextBox
$textBoxPassword.Location = New-Object System.Drawing.Point(120,70)
$textBoxPassword.Size = New-Object System.Drawing.Size(200,20)
$textBoxPassword.UseSystemPasswordChar = $true

# Bouton de connexion
$buttonConnect = New-Object System.Windows.Forms.Button
$buttonConnect.Location = New-Object System.Drawing.Point(10,100)
$buttonConnect.Size = New-Object System.Drawing.Size(100,30)
$buttonConnect.Text = "Connecter"

# Zone de sortie RichTextBox
$outputTextBox = New-Object System.Windows.Forms.RichTextBox
$outputTextBox.Location = New-Object System.Drawing.Point(10,150)
$outputTextBox.Size = New-Object System.Drawing.Size(920,550)
$outputTextBox.Font = New-Object System.Drawing.Font("Consolas",10)
$outputTextBox.ReadOnly = $true

# Ajout des contrôles au formulaire
$form.Controls.Add($labelServer)
$form.Controls.Add($textBoxServer)
$form.Controls.Add($labelUser)
$form.Controls.Add($textBoxUser)
$form.Controls.Add($labelPassword)
$form.Controls.Add($textBoxPassword)
$form.Controls.Add($buttonConnect)
$form.Controls.Add($outputTextBox)

# Fonction d'affichage avec horodatage
function Update-Output {
    param([string]$text)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $outputTextBox.AppendText("$timestamp : $text`r`n")
}

# Fonction pour texte coloré
function Write-ColoredLine {
    param(
        [string]$text,
        [System.Drawing.Color]$color
    )
    $outputTextBox.SelectionStart = $outputTextBox.TextLength
    $outputTextBox.SelectionLength = 0
    $outputTextBox.SelectionColor = $color
    $outputTextBox.AppendText("$text`r`n")
    $outputTextBox.SelectionColor = $outputTextBox.ForeColor
}

# Clic sur "Connecter"
$buttonConnect.Add_Click({
    $outputTextBox.Clear()
    Update-Output "Tentative de connexion au serveur ESXi..."
    try {
        $server = $textBoxServer.Text
        $user = $textBoxUser.Text
        $password = $textBoxPassword.Text

        if ([string]::IsNullOrEmpty($server) -or [string]::IsNullOrEmpty($user) -or [string]::IsNullOrEmpty($password)) {
            throw "Tous les champs doivent être remplis."
        }

        $cred = New-Object System.Management.Automation.PSCredential ($user, (ConvertTo-SecureString $password -AsPlainText -Force))
        $connection = Connect-VIServer -Server $server -Credential $cred -ErrorAction Stop
        Update-Output "Connexion établie avec $server."

        $esxiHost = Get-VMHost -Server $server -ErrorAction Stop
        $global:hostNetwork = Get-VMHostNetwork -VMHost $esxiHost

        Update-Output "=== Caractéristiques du serveur ESXi ==="
        Update-Output "Nom: $($esxiHost.Name)"
        Update-Output "Version: $($esxiHost.Version)"
        Update-Output "Build: $($esxiHost.Build)"
        Update-Output "État: $($esxiHost.State)"

        $hostView = $esxiHost | Get-View

        Update-Output "=== CPU du serveur ==="
        $cpuInfo = $hostView.Hardware.CpuInfo
        Update-Output "Packages: $($cpuInfo.NumCpuPackages), Cœurs: $($cpuInfo.NumCpuCores), Threads: $($cpuInfo.NumCpuThreads)"
        foreach ($cpuPkg in $hostView.Hardware.CpuPkg) {
            $mhz = [math]::Round($cpuPkg.Hz / 1e6, 2)
            Update-Output "CPU: $($cpuPkg.Description) - $mhz MHz - Cœurs: $($cpuPkg.NumCpuCores)"
        }

        Update-Output "=== Stockage ==="
        foreach ($ds in Get-Datastore) {
            $used = [math]::Round($ds.CapacityGB - $ds.FreeSpaceGB, 2)
            Update-Output "Datastore: $($ds.Name) - Capacité: $($ds.CapacityGB)GB, Utilisé: $used GB, Libre: $($ds.FreeSpaceGB) GB"
        }

        Update-Output "=== Mémoire ==="
        $totalMem = [math]::Round($hostView.Hardware.MemorySize / 1GB, 2)
        $usedMem = [math]::Round($hostView.Summary.QuickStats.OverallMemoryUsage / 1024, 2)
        Update-Output "Mémoire Totale: ${totalMem}GB, Utilisée: ${usedMem}GB, Libre: $([math]::Round($totalMem - $usedMem,2))GB"

        Update-Output "=== Réseau ==="
        Update-Output "Adresse IP du serveur: $($global:hostNetwork.IPAddress)"
        foreach ($vs in $global:hostNetwork.VirtualSwitch) {
            Update-Output "VSwitch: $($vs.Name)"
            foreach ($uplink in $vs.Uplink) {
                Update-Output "  - Uplink: $uplink"
            }
        }
        foreach ($pg in $global:hostNetwork.PortGroup) {
            Update-Output "PortGroup: $($pg.Name) - VLAN: $($pg.VlanId) - VSwitch: $($pg.VirtualSwitch)"
        }

        Update-Output "=== Cartes réseau physiques ==="
        foreach ($nic in Get-VMHostNetworkAdapter -VMHost $esxiHost) {
            Update-Output "NIC: $($nic.Name) - MAC: $($nic.Mac) - Statut: $($nic.Status) - Vitesse: $($nic.SpeedMb) Mb/s"
        }

        ################## VMs ##################
        $vms = Get-VM
        if ($vms.Count -eq 0) {
            Update-Output "Aucune VM trouvée."
        } else {
            Update-Output "=== Informations sur les VMs ==="
            foreach ($vm in $vms) {
                Update-Output "Nom: $($vm.Name)"
                Update-Output "   CPU: $($vm.NumCpu), RAM: $($vm.MemoryMB)MB"

                $os = $vm.ExtensionData.Guest.GuestFullName
                $ip = $vm.ExtensionData.Guest.IpAddress
                Update-Output "   OS: $os"
                if ($ip) {
    Update-Output "   IP: $ip"
} else {
    Update-Output "   IP: Non disponible"
}


                $ds = ($vm | Get-Datastore).Name -join ", "
                Update-Output "   Datastore(s): $ds"

                $vmView = $vm | Get-View
                foreach ($nic in $vmView.Config.Hardware.Device | Where-Object { $_ -is [VMware.Vim.VirtualEthernetCard] }) {
                    $nicName = $nic.DeviceInfo.Label
                    $net = $nic.Backing.DeviceName
                    Update-Output "   NIC: $nicName connectée à $net"
                    $pgInfo = $global:hostNetwork.PortGroup | Where-Object { $_.Name -eq $net }
                    if ($pgInfo) {
                        Update-Output "      PortGroup: $($pgInfo.Name), VSwitch: $($pgInfo.VirtualSwitch), VLAN: $($pgInfo.VlanId)"
                    }
                }
                Update-Output "-----------------------------"
            }
        }

    } catch {
        Write-ColoredLine "Erreur : $_" ([System.Drawing.Color]::Red)
    }
})

# Récupération des VMs connectées au vSwitch via les port groups
foreach ($vSwitch in $vSwitches) {
    Update-Output "-------------------------------------------------"
    Update-Output "vSwitch: $($vSwitch.Name)"
    Update-Output "   Type: $($vSwitch.SwitchType)"
    Update-Output "   MTU : $($vSwitch.Mtu)"

    $connectedVMs = @()

    # Trouver les port groups associés à ce vSwitch
    $portGroups = $portGroups | Where-Object { $_.VirtualSwitch -eq $vSwitch.Name }

    foreach ($pg in $portGroups) {
        # Pour chaque port group, chercher les VMNetworkAdapters connectés
        $vmNics = Get-VM | Get-NetworkAdapter | Where-Object { $_.NetworkName -eq $pg.Name }
        foreach ($nic in $vmNics) {
            $vm = $nic | Get-VM
            if ($vm -and -not $connectedVMs.Contains($vm.Name)) {
                $connectedVMs += $vm.Name
            }
        }
    }

    if ($connectedVMs.Count -gt 0) {
        Update-Output "   VMs connectées :"
        foreach ($vmName in $connectedVMs | Sort-Object) {
            Update-Output "      - $vmName"
        }
    } else {
        Update-Output "   Aucune VM connectée"
    }
}


# Afficher le formulaire
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()