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

        # Informations sur l'hôte ESXi
        $esxiHostInfo = Get-VMHost | Select-Object -First 1
        $esxiInfo = [PSCustomObject]@{
            Nom         = $esxiHostInfo.Name
            Version     = $esxiHostInfo.Version
            CPU_Cores   = $esxiHostInfo.NumCpu
            vCPU_Total  = ($esxiHostInfo | Get-View | Select-Object -ExpandProperty Hardware | Select-Object -ExpandProperty CpuInfo).NumCpuThreads
            RAM_GB      = [math]::Round($esxiHostInfo.MemoryTotalGB, 2)
        }

        # Liste des VMs
        $vmList = Get-VM | ForEach-Object {
            $vm = $_
            $hardDisks = Get-HardDisk -VM $vm
            $diskAllocated = [math]::Round(($hardDisks | Measure-Object -Property CapacityGB -Sum).Sum, 2)

            # Récupère le datastore principal de la VM
            $vmDatastore = ($vm | Get-Datastore | Select-Object -First 1).Name

            [PSCustomObject]@{
                Nom             = $vm.Name
                vCPU            = $vm.NumCPU
                RAM_GB          = [math]::Round($vm.MemoryGB, 1)
                Disque_Alloué_GB= $diskAllocated
                Datastore       = if ($vmDatastore) { $vmDatastore } else { "Inconnu" }
                Statut          = $vm.PowerState
                Adresse_IP      = if ($vm.Guest.IPAddress) { ($vm.Guest.IPAddress -join ', ') } else { 'Indisponible' }
                OS_Réel         = if ($vm.Guest.OSFullName) { $vm.Guest.OSFullName } else { 'Indisponible' }
            }
        }

        # Datastores
        $datastoreList = Get-Datastore | ForEach-Object {
            [PSCustomObject]@{
                Nom             = $_.Name
                Type            = $_.Type
                Capacité_GB     = [math]::Round($_.CapacityGB, 2)
                Espace_Libre_GB = [math]::Round($_.FreeSpaceGB, 2)
            }
        }

        # Ressources allouées (toutes les VMs)
        $totalAllocated = [PSCustomObject]@{
            vCPU_Total     = ($vmList | Measure-Object -Property vCPU -Sum).Sum
            RAM_Total_GB   = [math]::Round(($vmList | Measure-Object -Property RAM_GB -Sum).Sum, 2)
            Disque_Total_GB= [math]::Round(($vmList | Measure-Object -Property Disque_Alloué_GB -Sum).Sum, 2)
        }

        # Ressources allouées uniquement pour les VMs allumées
        $poweredOnVMs = $vmList | Where-Object { $_.Statut -eq "PoweredOn" }
        $poweredOnAllocated = [PSCustomObject]@{
            vCPU_Total     = ($poweredOnVMs | Measure-Object -Property vCPU -Sum).Sum
            RAM_Total_GB   = [math]::Round(($poweredOnVMs | Measure-Object -Property RAM_GB -Sum).Sum, 2)
            Disque_Total_GB= [math]::Round(($poweredOnVMs | Measure-Object -Property Disque_Alloué_GB -Sum).Sum, 2)
        }

        # Ressources disponibles
        $availableResources = [PSCustomObject]@{
            vCPU_Disponible = [math]::Max(0, $esxiInfo.vCPU_Total - $totalAllocated.vCPU_Total)
            RAM_Disponible_GB = [math]::Max(0, $esxiInfo.RAM_GB - $totalAllocated.RAM_Total_GB)
        }

        # Ressources disponibles par datastore
        $datastoreAvailableResources = $datastoreList | ForEach-Object {
            [PSCustomObject]@{
                Nom = $_.Nom
                Espace_Disponible_GB = $_.Espace_Libre_GB
            }
        }

        Disconnect-VIServer -Server $connection -Confirm:$false

        return @($esxiInfo, $vmList, $datastoreList, $totalAllocated, $poweredOnAllocated, $availableResources, $datastoreAvailableResources)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur de connexion : $($_.Exception.Message)", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $null
    }
}

# Interface de connexion
$form = New-Object System.Windows.Forms.Form
$form.Text = "Connexion à l'ESXi"
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
$label2.Text = "Nom d'utilisateur :"
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

if ($ipBox.Text -and $userBox.Text -and $passBox.Text) {
    $results = Show-ESXiInfo -ESXiHost $ipBox.Text -Username $userBox.Text -Password $passBox.Text
    if ($results) {
        $esxiInfo = $results[0]
        $vmList = $results[1]
        $datastoreList = $results[2]
        $totalAllocated = $results[3]
        $poweredOnAllocated = $results[4]
        $availableResources = $results[5]
        $datastoreAvailableResources = $results[6]

        # Interface principale
        $gridForm = New-Object System.Windows.Forms.Form
        $gridForm.Text = "Informations ESXi & VMs"
        $gridForm.Size = New-Object System.Drawing.Size(1000, 800)
        $gridForm.StartPosition = "CenterScreen"

        # Label : Infos ESXi
        $labelESXi = New-Object System.Windows.Forms.Label
        $labelESXi.Text = "Hôte : $($esxiInfo.Nom) | Version : $($esxiInfo.Version) | CPU : $($esxiInfo.CPU_Cores) cores | vCPU : $($esxiInfo.vCPU_Total) | RAM : $($esxiInfo.RAM_GB) GB"
        $labelESXi.Location = New-Object System.Drawing.Point(10, 10)
        $labelESXi.AutoSize = $true
        $gridForm.Controls.Add($labelESXi)

        # DataGridView : VMs
        $dataGridViewVMs = New-Object System.Windows.Forms.DataGridView
        $dataGridViewVMs.Location = New-Object System.Drawing.Point(10, 50)
        $dataGridViewVMs.Size = New-Object System.Drawing.Size(950, 250)
        $dataGridViewVMs.ReadOnly = $true
        $dataGridViewVMs.AllowUserToAddRows = $false
        $dataGridViewVMs.AutoGenerateColumns = $true
        $dataGridViewVMs.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
        $dataGridViewVMs.DataSource = [System.Collections.ArrayList]@($vmList)

        # Coloration conditionnelle (RowPrePaint)
        $handler = [System.Windows.Forms.DataGridViewRowPrePaintEventHandler]{
            param($sender, $e)
            $row = $dataGridViewVMs.Rows[$e.RowIndex]
            $state = $row.Cells["Statut"].Value

            if ($state -eq "PoweredOn") {
                $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightGreen
            } else {
                $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightSalmon
            }
        }
        $dataGridViewVMs.Add_RowPrePaint($handler)

        $gridForm.Controls.Add($dataGridViewVMs)

        # DataGridView : Datastores
        $dataGridViewDS = New-Object System.Windows.Forms.DataGridView
        $dataGridViewDS.Location = New-Object System.Drawing.Point(10, 310)
        $dataGridViewDS.Size = New-Object System.Drawing.Size(950, 150)
        $dataGridViewDS.ReadOnly = $true
        $dataGridViewDS.AllowUserToAddRows = $false
        $dataGridViewDS.AutoGenerateColumns = $true
        $dataGridViewDS.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
        $dataGridViewDS.DataSource = [System.Collections.ArrayList]@($datastoreList)
        $gridForm.Controls.Add($dataGridViewDS)

        # Labels : Ressources allouées
        $labelTotal = New-Object System.Windows.Forms.Label
        $labelTotal.Text = "Ressources allouées (toutes VMs) : vCPU = $($totalAllocated.vCPU_Total) | RAM = $($totalAllocated.RAM_Total_GB) GB | Disque = $($totalAllocated.Disque_Total_GB) GB"
        $labelTotal.Location = New-Object System.Drawing.Point(10, 470)
        $labelTotal.AutoSize = $true
        $gridForm.Controls.Add($labelTotal)

        $labelPoweredOn = New-Object System.Windows.Forms.Label
        $labelPoweredOn.Text = "Ressources allouées (VMs allumées) : vCPU = $($poweredOnAllocated.vCPU_Total) | RAM = $($poweredOnAllocated.RAM_Total_GB) GB | Disque = $($poweredOnAllocated.Disque_Total_GB) GB"
        $labelPoweredOn.Location = New-Object System.Drawing.Point(10, 500)
        $labelPoweredOn.AutoSize = $true
        $gridForm.Controls.Add($labelPoweredOn)

        $labelAvailable = New-Object System.Windows.Forms.Label
        $labelAvailable.Text = "Ressources disponibles : vCPU = $($availableResources.vCPU_Disponible) | RAM = $($availableResources.RAM_Disponible_GB) GB"
        $labelAvailable.Location = New-Object System.Drawing.Point(10, 530)
        $labelAvailable.AutoSize = $true
        $gridForm.Controls.Add($labelAvailable)

        # Formatage correct de la chaîne pour les datastores
        $dsText = ($datastoreAvailableResources | ForEach-Object { "$($_.Nom) : $($_.Espace_Disponible_GB) GB" }) -join " | "
        $labelDatastoreAvailable = New-Object System.Windows.Forms.Label
        $labelDatastoreAvailable.Text = "Ressources disponibles par datastore : $dsText"
        $labelDatastoreAvailable.Location = New-Object System.Drawing.Point(10, 560)
        $labelDatastoreAvailable.MaximumSize = New-Object System.Drawing.Size(950, 60)
        $labelDatastoreAvailable.AutoSize = $true
        $gridForm.Controls.Add($labelDatastoreAvailable)

        # Bouton d'export en CSV
        $exportButton = New-Object System.Windows.Forms.Button
        $exportButton.Text = "Exporter en CSV"
        $exportButton.Location = New-Object System.Drawing.Point(10, 630)
        $exportButton.Size = New-Object System.Drawing.Size(150, 30)
        $exportButton.Add_Click({
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "Fichier CSV (*.csv)|*.csv"
            $saveDialog.Title = "Enregistrer le fichier CSV"
            $saveDialog.FileName = "ESXi_Info_VM_$(Get-Date -Format 'yyyyMMdd').csv"

            if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $filePath = $saveDialog.FileName
                $vmList | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
                [System.Windows.Forms.MessageBox]::Show("Export terminé avec succès !", "Succès", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        })
        $gridForm.Controls.Add($exportButton)

        $gridForm.ShowDialog()
    }
}