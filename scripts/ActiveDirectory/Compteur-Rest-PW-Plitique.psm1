Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Fonction pour créer les éléments de légende ---
function Add-LegendItemControl {
    param(
        [Parameter(Mandatory)] [System.Windows.Forms.Panel]$parent,
        [Parameter(Mandatory)] [System.Drawing.Color]$color,
        [Parameter(Mandatory)] [string]$text,
        [Parameter(Mandatory)] [int]$x
    )

    # Carré de couleur
    $square = New-Object System.Windows.Forms.Panel
    $square.Size = New-Object System.Drawing.Size(20,20)
    $square.Location = New-Object System.Drawing.Point([int]$x,15)
    $square.BackColor = $color
    $parent.Controls.Add($square)

    # Libellé
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $text
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point([int]($x + 30), 15)
    $parent.Controls.Add($label)

    # Retourner une seule valeur numérique (largeur totale)
    return [int]($label.PreferredWidth + 70)
}

# --- Fonction principale ---
function Test-UserPasswordAge {
    param($User, $DC)

    try {
        $userInfo = Get-ADUser $User -Server $DC -Properties PasswordLastSet, Enabled, LockedOut, AccountExpirationDate, EmployeeID, LastLogonDate

        $passwordLastSet = $userInfo.PasswordLastSet
        $passwordExpiration = if ($passwordLastSet) { $passwordLastSet.AddDays(90) } else { $null }

        [PSCustomObject]@{
            Utilisateur        = $User
            EmployeeID         = $userInfo.EmployeeID
            Controleur         = $DC
            PasswordLastSet    = $passwordLastSet
            PasswordExpiration = $passwordExpiration
            LastLogonDate      = $userInfo.LastLogonDate
            LockedOut          = $userInfo.LockedOut
            Enabled            = $userInfo.Enabled
        }
    }
    catch {
        Write-Warning "Erreur interrogation $User sur $DC"
        return $null
    }
}

# --- Fonction de vérification ---
function Start-Verification {
    $grid.Rows.Clear()
    $users = $txtUsers.Text -split "[,`n]" | ForEach-Object { $_.Trim() } | Where-Object { $_ }

    if ($users.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Veuillez entrer au moins un compte utilisateur.")
        return
    }

    Write-Host "Lancement de la vérification pour $($users.Count) utilisateur(s)..."
    $DomainControllers = @("cevsrv1001.CEVITAL.com", "cevsrv1002.CEVITAL.com")
    $global:Results = @()

    foreach ($user in $users) {
        foreach ($dc in $DomainControllers) {
            Write-Host "[INFO] Interrogation de $user sur $dc ..."
            $r = Test-UserPasswordAge -User $user -DC $dc
            if ($r) { $global:Results += $r }
        }
    }

    # Comparaison DC1 / DC2
    $grouped = $global:Results | Group-Object Utilisateur
    foreach ($g in $grouped) {
        if ($g.Group.Count -eq 2) {
            $a = $g.Group[0]
            $b = $g.Group[1]
            $delta = [math]::Abs(($a.PasswordLastSet - $b.PasswordLastSet).TotalSeconds)
            $status = if ($delta -lt 5) { "OK (synchro)" } else { "🔶 Différence DC" }

            $grid.Rows.Add($a.Utilisateur, $a.EmployeeID, $a.Controleur, $a.PasswordLastSet, $a.PasswordExpiration, $a.LastLogonDate, $a.LockedOut, $a.Enabled, $delta, $status)
            $grid.Rows.Add($b.Utilisateur, $b.EmployeeID, $b.Controleur, $b.PasswordLastSet, $b.PasswordExpiration, $b.LastLogonDate, $b.LockedOut, $b.Enabled, $delta, $status)

            # Séparation visuelle entre utilisateurs
            $sepRow = $grid.Rows.Add("", "", "", "", "", "", "", "", "", "")
            $grid.Rows[$sepRow].DefaultCellStyle.BackColor = [System.Drawing.Color]::LightGray
        }
    }

    # Mise en couleur
    foreach ($row in $grid.Rows) {
        if (-not $row.Cells[0].Value) { continue } # ignorer les lignes vides
        if ($row.Cells[6].Value -eq $true) {
            $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::Khaki    # 🟡 verrouillé
        }
        elseif ($row.Cells[7].Value -eq $false) {
            $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightCoral   # 🔴 désactivé
        }
        elseif ($row.Cells[9].Value -match "Différence") {
            $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::Orange   # 🔶 différence DC
        }
        else {
            $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::PaleGreen   # 🟢 OK
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Vérification terminée pour $($users.Count) utilisateur(s).")
}

# --- Export CSV avec sélection de l’emplacement ---
function Export-Results {
    if (-not $global:Results -or $global:Results.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Aucun résultat à exporter.")
        return
    }

    # Ouvre une boîte de dialogue "Enregistrer sous"
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Title = "Enregistrer le rapport CSV"
    $saveDialog.Filter = "Fichiers CSV (*.csv)|*.csv"
    $saveDialog.FileName = "Résultats_Verif_AD.csv"
    $saveDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")

    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $global:Results | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $saveDialog.FileName
            [System.Windows.Forms.MessageBox]::Show("Résultats exportés avec succès vers :`n$($saveDialog.FileName)")
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur lors de l'exportation : $_")
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Exportation annulée.")
    }
}

# --- Interface graphique ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "🧭 Vérification Synchronisation et Statut des Comptes AD"
$form.Size = New-Object System.Drawing.Size(1250, 750)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

# Label instructions
$lblUsers = New-Object System.Windows.Forms.Label
$lblUsers.Text = "Liste des utilisateurs (séparés par des virgules) :"
$lblUsers.Location = New-Object System.Drawing.Point(10,10)
$lblUsers.Size = New-Object System.Drawing.Size(400,20)
$form.Controls.Add($lblUsers)

# Champ texte utilisateurs
$txtUsers = New-Object System.Windows.Forms.TextBox
$txtUsers.Multiline = $false
$txtUsers.Size = New-Object System.Drawing.Size(600,20)
$txtUsers.Location = New-Object System.Drawing.Point(10,30)
$form.Controls.Add($txtUsers)

# Bouton lancer
$btnCheck = New-Object System.Windows.Forms.Button
$btnCheck.Text = "Lancer la vérification"
$btnCheck.BackColor = [System.Drawing.Color]::LightSteelBlue
$btnCheck.Size = New-Object System.Drawing.Size(180,30)
$btnCheck.Location = New-Object System.Drawing.Point(650,25)
$btnCheck.Add_Click({ Start-Verification })
$form.Controls.Add($btnCheck)

# Bouton export CSV
$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Exporter vers CSV"
$btnExport.BackColor = [System.Drawing.Color]::LightGreen
$btnExport.Size = New-Object System.Drawing.Size(180,30)
$btnExport.Location = New-Object System.Drawing.Point(850,25)
$btnExport.Add_Click({ Export-Results })
$form.Controls.Add($btnExport)

# Grille des résultats
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(10,70)
$grid.Size = New-Object System.Drawing.Size(1210,560)
$grid.AutoSizeColumnsMode = "Fill"
$grid.ColumnCount = 10
$grid.Columns[0].Name = "Utilisateur"
$grid.Columns[1].Name = "EmployeeID"
$grid.Columns[2].Name = "Controleur"
$grid.Columns[3].Name = "PasswordLastSet"
$grid.Columns[4].Name = "PasswordExpiration"
$grid.Columns[5].Name = "LastLogonDate"
$grid.Columns[6].Name = "LockedOut"
$grid.Columns[7].Name = "Enabled"
$grid.Columns[8].Name = "Delta (sec)"
$grid.Columns[9].Name = "Statut"
$form.Controls.Add($grid)

# --- Légende centrée et corrigée ---
$legendPanel = New-Object System.Windows.Forms.Panel
$legendPanel.Size = New-Object System.Drawing.Size(1150, 55)
$legendPanel.Location = New-Object System.Drawing.Point(50, 640)
$legendPanel.BackColor = [System.Drawing.Color]::WhiteSmoke
$legendPanel.BorderStyle = 'FixedSingle'
$form.Controls.Add($legendPanel)

$x = 20
$x += [int](Add-LegendItemControl -parent $legendPanel -color ([System.Drawing.Color]::LightCoral) -text "🔴 Compte désactivé" -x $x)
$x += [int](Add-LegendItemControl -parent $legendPanel -color ([System.Drawing.Color]::Khaki) -text "🟡 Compte verrouillé" -x $x)
$x += [int](Add-LegendItemControl -parent $legendPanel -color ([System.Drawing.Color]::PaleGreen) -text "🟢 Actif" -x $x)
$x += [int](Add-LegendItemControl -parent $legendPanel -color ([System.Drawing.Color]::Orange) -text "🔶 Différence DC" -x $x)

# --- Lancer ---
[void]$form.ShowDialog()
