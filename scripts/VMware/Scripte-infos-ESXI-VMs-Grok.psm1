Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-ESXiInfo {
    param (
        [string]$ESXiHost,
        [string]$Username,
        [string]$Password
    )

    try {
        $connection = Connect-VIServer -Server $ESXiHost -User $Username -Password $Password -ErrorAction Stop

        # Informations sur l’hôte ESXi
        $esxiHostInfo = Get-VMHost | Select-Object -First 1
        $esxiInfo = [PSCustomObject]@{
            Nom         = $esxiHostInfo.Name
            Version     = $esxiHostInfo.Version
            CPU_Cores   = $esxiHostInfo.NumCpu
            RAM_GB      = [math]::Round($esxiHostInfo.MemoryTotalMB / 1024, 2)
        }

        # Liste des VMs
        $vmList = Get-VM | ForEach-Object {
            $vm = $_
            $hardDisks = Get-HardDisk -VM $vm
            $diskAllocated = [math]::Round(($hardDisks | Measure-Object -Property CapacityGB -Sum).Sum, 2)

            [PSCustomObject]@{
                Nom            = $vm.Name
                vCPU           = $vm.NumCPU
                RAM_GB         = [math]::Round($vm.MemoryMB / 1024, 1)
                Disque_Alloué_GB = $diskAllocated
                Statut         = $vm.PowerState
                Adresse_IP     = if ($vm.Guest.IPAddress) { ($vm.Guest.IPAddress -join ', ') } else { 'Indisponible' }
                OS_Réel        = if ($vm.Guest.OSFullName) { $vm.Guest.OSFullName } else { 'Indisponible' }
            }
        }

        # Calcul des informations sur les datastores
        $allHardDisks = Get-VM | Get-HardDisk
        $provisionedSpace = @{}
        foreach ($hardDisk in $allHardDisks) {
            $ds = Get-Datastore -RelatedObject $hardDisk
            $dsName = $ds.Name
            if (-not $provisionedSpace.ContainsKey($dsName)) {
                $provisionedSpace[$dsName] = 0
            }
            $provisionedSpace[$dsName] += $hardDisk.CapacityGB
        }

        $datastoreList = Get-Datastore | ForEach-Object {
            $dsName = $_.Name
            $provisioned = if ($provisionedSpace.ContainsKey($dsName)) { $provisionedSpace[$dsName] } else { 0 }
            [PSCustomObject]@{
                Nom = $dsName
                Capacité_GB = [math]::Round($_.CapacityGB, 2)
                Espace_Libre_GB = [math]::Round($_.FreeSpaceGB, 2)
                Alloué_aux_VMs_GB = [math]::Round($provisioned, 2)
            }
        }

        # Calcul des ressources totales allouées
        $totalAllocated = [PSCustomObject]@{
            vCPU_Total     = ($vmList | Measure-Object -Property vCPU -Sum).Sum
            RAM_Total_GB   = [math]::Round(($vmList | Measure-Object -Property RAM_GB -Sum).Sum, 2)
            Disque_Total_GB = [math]::Round(($vmList | Measure-Object -Property Disque_Alloué_GB -Sum).Sum, 2)
        }

        # Ressources disponibles
        $availableResources = [PSCustomObject]@{
            vCPU_Disponible = [math]::Max(0, ($esxiInfo.CPU_Cores * 2) - $totalAllocated.vCPU_Total)  # Ratio 2:1
            RAM_Disponible_GB = [math]::Max(0, $esxiInfo.RAM_GB - $totalAllocated.RAM_Total_GB)
            Disque_Disponible_GB = [math]::Round((Get-Datastore | Measure-Object -Property FreeSpaceGB -Sum).Sum, 2)
        }

        Disconnect-VIServer -Server $connection -Confirm:$false

        return @($esxiInfo, $vmList, $datastoreList, $totalAllocated, $availableResources)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur de connexion : $($_.Exception.Message)", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $null
    }
}

# Interface de connexion
$form = New-Object System.Windows.Forms.Form
$form.Text = "Connexion à l’ESXi"
$form.Size = New-Object System.Drawing.Size(320,220)
$form.StartPosition = "CenterScreen"

$label1 = New-Object System.Windows.Forms.Label
$label1.Text = "Adresse IP ESXi :"
$label1.Location = New-Object System.Drawing.Point(10,20)
$label1.Size = New-Object System.Drawing.Size(120,20)
$form.Controls.Add($label1)

$ipBox = New-Object System.Windows.Forms.TextBox
$ipBox.Location = New-Object System.Drawing.Point(140,20)
$ipBox.Size = New-Object System.Drawing.Size(150,20)
$form.Controls.Add($ipBox)

$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "Nom d’utilisateur :"
$label2.Location = New-Object System.Drawing.Point(10,60)
$label2.Size = New-Object System.Drawing.Size(120,20)
$form.Controls.Add($label2)

$userBox = New-Object System.Windows.Forms.TextBox
$userBox.Location = New-Object System.Drawing.Point(140,60)
$userBox.Size = New-Object System.Drawing.Size(150,20)
$form.Controls.Add($userBox)

$label3 = New-Object System.Windows.Forms.Label
$label3.Text = "Mot de passe :"
$label3.Location = New-Object System.Drawing.Point(10,100)
$label3.Size = New-Object System.Drawing.Size(120,20)
$form.Controls.Add($label3)

$passBox = New-Object System.Windows.Forms.TextBox
$passBox.Location = New-Object System.Drawing.Point(140,100)
$passBox.Size = New-Object System.Drawing.Size(150,20)
$passBox.UseSystemPasswordChar = $true
$form.Controls.Add($passBox)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "Connexion"
$okButton.Location = New-Object System.Drawing.Point(100,140)
$okButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($okButton)

$form.ShowDialog()

# Traitement si les champs sont remplis
if ($ipBox.Text -and $userBox.Text -and $passBox.Text) {
    $results = Show-ESXiInfo -ESXiHost $ipBox.Text -Username $userBox.Text -Password $passBox.Text

    if ($results) {
        $esxiInfo = $results[0]
        $vmList = $results[1]
        $datastoreList = $results[2]
        $totalAllocated = $results[3]
        $availableResources = $results[4]

        # Interface d’affichage des résultats
        $gridForm = New-Object System.Windows.Forms.Form
        $gridForm.Text = "Informations ESXi & VMs"
        $gridForm.Size = New-Object System.Drawing.Size(1000,800)
        $gridForm.StartPosition = "CenterScreen"

        # Label pour les infos ESXi
        $labelESXi = New-Object System.Windows.Forms.Label
        $labelESXi.Text = "Hôte : $($esxiInfo.Nom) | Version : $($esxiInfo.Version) | CPU : $($esxiInfo.CPU_Cores) cores | RAM : $($esxiInfo.RAM_GB) GB"
        $labelESXi.Location = New-Object System.Drawing.Point(10,10)
        $labelESXi.Size = New-Object System.Drawing.Size(950,30)
        $gridForm.Controls.Add($labelESXi)

        # DataGridView pour les VMs
        $dataGridVMs = New-Object System.Windows.Forms.DataGridView
        $dataGridVMs.Location = New-Object System.Drawing.Point(10,50)
        $dataGridVMs.Size = New-Object System.Drawing.Size(950,300)
        $dataGridVMs.ReadOnly = $true
        $dataGridVMs.AllowUserToAddRows = $false
        $dataGridVMs.AutoGenerateColumns = $true
        $dataGridVMs.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
        $dataGridVMs.DataSource = [System.Collections.ArrayList]@($vmList)
        $gridForm.Controls.Add($dataGridVMs)

        # DataGridView pour les Datastores
        $dataGridDatastores = New-Object System.Windows.Forms.DataGridView
        $dataGridDatastores.Location = New-Object System.Drawing.Point(10,360)
        $dataGridDatastores.Size = New-Object System.Drawing.Size(950,200)
        $dataGridDatastores.ReadOnly = $true
        $dataGridDatastores.AllowUserToAddRows = $false
        $dataGridDatastores.AutoGenerateColumns = $true
        $dataGridDatastores.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
        $dataGridDatastores.DataSource = [System.Collections.ArrayList]@($datastoreList)
        $gridForm.Controls.Add($dataGridDatastores)

        # Labels pour les ressources totales allouées et disponibles
        $labelTotal = New-Object System.Windows.Forms.Label
        $labelTotal.Text = "Ressources allouées : vCPU = $($totalAllocated.vCPU_Total) | RAM = $($totalAllocated.RAM_Total_GB) GB | Disque = $($totalAllocated.Disque_Total_GB) GB"
        $labelTotal.Location = New-Object System.Drawing.Point(10,570)
        $labelTotal.Size = New-Object System.Drawing.Size(950,30)
        $gridForm.Controls.Add($labelTotal)

        $labelAvailable = New-Object System.Windows.Forms.Label
        $labelAvailable.Text = "Ressources disponibles : vCPU = $($availableResources.vCPU_Disponible) | RAM = $($availableResources.RAM_Disponible_GB) GB | Disque = $($availableResources.Disque_Disponible_GB) GB"
        $labelAvailable.Location = New-Object System.Drawing.Point(10,600)
        $labelAvailable.Size = New-Object System.Drawing.Size(950,30)
        $gridForm.Controls.Add($labelAvailable)

        $gridForm.ShowDialog()
    }
}