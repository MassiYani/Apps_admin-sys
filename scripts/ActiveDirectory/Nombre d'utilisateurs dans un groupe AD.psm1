# Script - Nombre d'utilisateurs dans un groupe AD
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Utilisateurs dans un groupe AD"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.Text = "Nom du groupe :"
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(150, 20)
$textBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBox)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Vérifier"
$button.Location = New-Object System.Drawing.Point(150, 60)
$button.Add_Click({
    $Group = $textBox.Text
    if ($Group) {
        try {
            $groupMembers = (Get-ADGroup $Group -Properties *).Member.Count
            [System.Windows.Forms.MessageBox]::Show("Nombre d'utilisateurs dans $Group : $groupMembers", "Résultat")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Groupe introuvable", "Erreur")
        }
    }
})
$form.Controls.Add($button)

$form.ShowDialog()
