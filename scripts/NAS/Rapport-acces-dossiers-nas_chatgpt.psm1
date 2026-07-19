Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-FolderPermissions {
    param ([string]$Path)

    $results = @()

    if (!(Test-Path -Path $Path)) {
        [System.Windows.Forms.MessageBox]::Show("Chemin invalide ou inaccessible.", "Erreur", 'OK', 'Error')
        return $results
    }

    $items = Get-ChildItem -Path $Path -Recurse -Directory -Force -ErrorAction SilentlyContinue
    $items += Get-Item $Path

    foreach ($item in $items) {
        try {
            $acl = Get-Acl $item.FullName
            $inheritance = if ($acl.AreAccessRulesProtected) { 'Non Hérité' } else { 'Hérité' }

            foreach ($access in $acl.Access) {
                $entry = [PSCustomObject]@{
                    Dossier   = $item.FullName
                    Héritage  = $inheritance
                    Identité  = $access.IdentityReference
                    TypeAccès = $access.AccessControlType
                    Droits    = $access.FileSystemRights
                }
                $results += $entry
            }
        } catch {
            Write-Warning "Impossible d'obtenir les ACL de $($item.FullName)"
        }
    }
    return $results
}

# Créer formulaire
$form = New-Object System.Windows.Forms.Form
$form.Text = "Audit des Accès - Interface Colorée"
$form.Size = New-Object System.Drawing.Size(900, 600)
$form.StartPosition = "CenterScreen"
$form.TopMost = $false

# Label
$labelPath = New-Object System.Windows.Forms.Label
$labelPath.Text = "Chemin du dossier :"
$labelPath.Location = New-Object System.Drawing.Point(10, 15)
$labelPath.Size = New-Object System.Drawing.Size(120, 20)
$form.Controls.Add($labelPath)

# TextBox
$textBoxPath = New-Object System.Windows.Forms.TextBox
$textBoxPath.Location = New-Object System.Drawing.Point(130, 12)
$textBoxPath.Size = New-Object System.Drawing.Size(550, 20)
$form.Controls.Add($textBoxPath)

# Bouton parcourir
$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Text = "Parcourir"
$browseBtn.Location = New-Object System.Drawing.Point(700, 10)
$browseBtn.Size = New-Object System.Drawing.Size(75, 23)
$browseBtn.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderDialog.ShowDialog() -eq "OK") {
        $textBoxPath.Text = $folderDialog.SelectedPath
    }
})
$form.Controls.Add($browseBtn)

# Bouton analyser
$analyzeBtn = New-Object System.Windows.Forms.Button
$analyzeBtn.Text = "Analyser"
$analyzeBtn.Location = New-Object System.Drawing.Point(780, 10)
$analyzeBtn.Size = New-Object System.Drawing.Size(75, 23)
$form.Controls.Add($analyzeBtn)

# DataGridView
$dataGrid = New-Object System.Windows.Forms.DataGridView
$dataGrid.Location = New-Object System.Drawing.Point(10, 45)
$dataGrid.Size = New-Object System.Drawing.Size(860, 460)
$dataGrid.ReadOnly = $true
$dataGrid.AllowUserToAddRows = $false
$dataGrid.RowHeadersVisible = $false
$dataGrid.AutoSizeColumnsMode = "Fill"
$form.Controls.Add($dataGrid)

# Bouton exporter
$exportBtn = New-Object System.Windows.Forms.Button
$exportBtn.Text = "Exporter en CSV"
$exportBtn.Location = New-Object System.Drawing.Point(10, 515)
$exportBtn.Size = New-Object System.Drawing.Size(150, 30)
$form.Controls.Add($exportBtn)

# Analyse dossier et remplissage DataGrid
$analyzeBtn.Add_Click({
    $dataGrid.Rows.Clear()
    $dataGrid.Columns.Clear()

    $path = $textBoxPath.Text
    if (-not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("Chemin invalide ou inaccessible.", "Erreur", 'OK', 'Error')
        return
    }

    $results = Get-FolderPermissions -Path $path

    if ($results.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Aucun résultat à afficher.", "Info", 'OK', 'Information')
        return
    }

    # Colonnes
    $columns = @("Dossier", "Héritage", "Identité", "TypeAccès", "Droits")
    foreach ($col in $columns) {
        $null = $dataGrid.Columns.Add($col, $col)
    }

    foreach ($row in $results) {
        $index = $dataGrid.Rows.Add($row.Dossier, $row.Héritage, $row.Identité, $row.TypeAccès, $row.Droits)

        if ($row.Héritage -eq "Non Hérité") {
            $dataGrid.Rows[$index].DefaultCellStyle.BackColor = 'Tomato'
        } elseif ($row.Héritage -eq "Hérité") {
            $dataGrid.Rows[$index].DefaultCellStyle.BackColor = 'LightGreen'
        }
    }
})

# Export CSV
$exportBtn.Add_Click({
    if ($dataGrid.Rows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Aucune donnée à exporter.", "Erreur", 'OK', 'Error')
        return
    }

    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Fichier CSV (*.csv)|*.csv"
    $saveDialog.Title = "Enregistrer l'export"
    $saveDialog.FileName = "Audit_NAS.csv"

    if ($saveDialog.ShowDialog() -eq "OK") {
        $export = @()
        foreach ($row in $dataGrid.Rows) {
            $entry = [PSCustomObject]@{
                Dossier   = $row.Cells[0].Value
                Héritage  = $row.Cells[1].Value
                Identité  = $row.Cells[2].Value
                TypeAccès = $row.Cells[3].Value
                Droits    = $row.Cells[4].Value
            }
            $export += $entry
        }
        $export | Export-Csv -Path $saveDialog.FileName -NoTypeInformation -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Exportation terminée.", "Succès", 'OK', 'Information')
    }
})

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()