Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURATION DES OUs CEVITAL ---
$OUsCibles = @(
    "OU=Bejaia,DC=Cevital,DC=com",
    "OU=Cojek,DC=Cevital,DC=com",
    "OU=Lalla Khedidja,DC=Cevital,DC=com"
)

# --- Fenêtre Principale ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Cevital IT - Audit Réinitialisation Mots de Passe"
$form.Size = New-Object System.Drawing.Size(750, 550)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)

# --- Titre ---
$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Text = "Extraction des dates de réinitialisation par OU"
$labelTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$labelTitle.Location = New-Object System.Drawing.Point(20, 15)
$labelTitle.Size = New-Object System.Drawing.Size(500, 30)
$form.Controls.Add($labelTitle)

# --- Grille de données ---
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point(20, 100)
$dataGridView.Size = New-Object System.Drawing.Size(690, 320)
$dataGridView.BackgroundColor = [System.Drawing.Color]::White
$dataGridView.BorderStyle = "None"
$dataGridView.AutoSizeColumnsMode = "Fill"
$dataGridView.ColumnCount = 3
$dataGridView.Columns[0].Name = "Login (SamAccountName)"
$dataGridView.Columns[1].Name = "Dernière Réinitialisation"
$dataGridView.Columns[2].Name = "Unité d'Organisation"
$form.Controls.Add($dataGridView)

# --- Bouton : Scanner les OUs ---
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Lancer l'extraction"
$btnRun.Location = New-Object System.Drawing.Point(20, 60)
$btnRun.Size = New-Object System.Drawing.Size(150, 30)
$btnRun.FlatStyle = "Flat"
$btnRun.BackColor = [System.Drawing.Color]::DarkSlateBlue
$btnRun.ForeColor = [System.Drawing.Color]::White
$btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnRun.Add_Click({
    $dataGridView.Rows.Clear()
    foreach ($OU in $OUsCibles) {
        try {
            # Récupération des utilisateurs actifs avec la propriété PasswordLastSet
            $users = Get-ADUser -Filter 'Enabled -eq $true' -SearchBase $OU -Properties PasswordLastSet
            foreach ($u in $users) {
                $valDate = if ($u.PasswordLastSet) { $u.PasswordLastSet.ToString("dd/MM/yyyy HH:mm") } else { "Jamais" }
                $dataGridView.Rows.Add($u.SamAccountName, $valDate, $OU.Split(',')[0].Replace("OU=",""))
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur d'accès à l'OU : $OU. Vérifiez vos droits admin.", "Erreur")
        }
    }
})
$form.Controls.Add($btnRun)

# --- Bouton : Exporter vers PC ---
$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Exporter Excel (CSV)"
$btnExport.Location = New-Object System.Drawing.Point(560, 440)
$btnExport.Size = New-Object System.Drawing.Size(150, 40)
$btnExport.FlatStyle = "Flat"
$btnExport.BackColor = [System.Drawing.Color]::FromArgb(34, 139, 34)
$btnExport.ForeColor = [System.Drawing.Color]::White
$btnExport.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnExport.Add_Click({
    if ($dataGridView.Rows.Count -le 1) { 
        [System.Windows.Forms.MessageBox]::Show("Le tableau est vide !", "Info")
        return 
    }
    
    $saveFile = New-Object System.Windows.Forms.SaveFileDialog
    $saveFile.Filter = "Fichier CSV (*.csv)|*.csv"
    $saveFile.FileName = "Audit_MotsDePasse_Cevital_$(Get-Date -Format 'dd-MM-yyyy').csv"
    
    if ($saveFile.ShowDialog() -eq "OK") {
        $results = foreach ($row in $dataGridView.Rows) {
            if ($null -ne $row.Cells[0].Value) {
                [PSCustomObject]@{
                    Utilisateur        = $row.Cells[0].Value
                    DateReset         = $row.Cells[1].Value
                    UniteOrganisation = $row.Cells[2].Value
                }
            }
        }
        $results | Export-Csv -Path $saveFile.FileName -NoTypeInformation -Encoding UTF8 -Delimiter ";"
        [System.Windows.Forms.MessageBox]::Show("Rapport exporté avec succès sur votre ordinateur.", "Terminé")
    }
})
$form.Controls.Add($btnExport)

# --- Affichage ---
$form.ShowDialog() | Out-Null