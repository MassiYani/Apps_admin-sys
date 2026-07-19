Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Créer le formulaire
$form = New-Object System.Windows.Forms.Form
$form.Text = "Nombre d'utilisateurs dans un groupe AD"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White

# Zone de texte pour les résultats
$resultsBox = New-Object System.Windows.Forms.RichTextBox
$resultsBox.Location = New-Object System.Drawing.Point(20, 70)
$resultsBox.Size = New-Object System.Drawing.Size(550, 250)
$resultsBox.ReadOnly = $true
$resultsBox.ScrollBars = "Both"
$resultsBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$resultsBox.BackColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($resultsBox)

# Bouton pour exécuter la fonction
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(20, 20)
$button.Size = New-Object System.Drawing.Size(550, 40)
$button.Text = "2. Nombre d'utilisateurs dans un groupe AD"
$button.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$button.BackColor = [System.Drawing.Color]::LightGray
$button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard

$button.Add_Click({
    $group = [Microsoft.VisualBasic.Interaction]::InputBox("Entrez le nom du groupe", "Saisie groupe")
    if ($group) {
        try {
            $groupInfo = Get-ADGroup -Identity $group -Properties Member -ErrorAction Stop
            $resultsBox.Clear()
            $resultsBox.AppendText("Le groupe $group contient $($groupInfo.Member.Count) utilisateurs.")
        } catch {
            $resultsBox.Clear()
            $resultsBox.AppendText("Aucun groupe AD avec cette nomination.")
        }
    }
})
$form.Controls.Add($button)

# Afficher le formulaire
$form.ShowDialog()