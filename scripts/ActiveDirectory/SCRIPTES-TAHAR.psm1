##[Ps1 To Exe]
##
##Kd3HDZOFADWE8uO1
##Nc3NCtDXThU=
##Kd3HFJGZHWLWoLaVvnQnhQ==
##LM/RF4eFHHGZ7/K1
##K8rLFtDXTiW5
##OsHQCZGeTiiZ4NI=
##OcrLFtDXTiW5
##LM/BD5WYTiiZ4tI=
##McvWDJ+OTiiZ4tI=
##OMvOC56PFnzN8u+Vs1Q=
##M9jHFoeYB2Hc8u+Vs1Q=
##PdrWFpmIG2HcofKIo2QX
##OMfRFJyLFzWE8uK1
##KsfMAp/KUzWJ0g==
##OsfOAYaPHGbQvbyVvnQX
##LNzNAIWJGmPcoKHc7Do3uAuO
##LNzNAIWJGnvYv7eVvnQX
##M9zLA5mED3nfu77Q7TV64AuzAgg=
##NcDWAYKED3nfu77Q7TV64AuzAgg=
##OMvRB4KDHmHQvbyVvnQX
##P8HPFJGEFzWE8tI=
##KNzDAJWHD2fS8u+Vgw==
##P8HSHYKDCX3N8u+Vgw==
##LNzLEpGeC3fMu77Ro2k3hQ==
##L97HB5mLAnfMu77Ro2k3hQ==
##P8HPCZWEGmaZ7/K1
##L8/UAdDXTlaDjofG5iZk2V/2QVcqasiSt4qDwZK36+X8hxbaW5MEXRRWvxXPB1m0SeYzcbsQrNRx
##Kc/BRM3KXhU=
##
##
##fd6a9f26a06ea3bc99616d4851b372ba
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Créer le formulaire principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Gestion des utilisateurs AD"
$form.Size = New-Object System.Drawing.Size(1200, 800)  # Taille agrandie pour une meilleure visibilité
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White

# Ajouter un grand titre
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Les tâches quotidiennes d'un administrateur système"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::DarkBlue
$titleLabel.BackColor = [System.Drawing.Color]::LightSteelBlue
$titleLabel.AutoSize = $false
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$titleLabel.Size = New-Object System.Drawing.Size(1180, 50)
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($titleLabel)

# Zone de texte pour afficher les résultats
$resultsBox = New-Object System.Windows.Forms.RichTextBox
$resultsBox.Location = New-Object System.Drawing.Point(400, 70)
$resultsBox.Size = New-Object System.Drawing.Size(580, 500)  # Zone de résultats agrandie
$resultsBox.ReadOnly = $true
$resultsBox.ScrollBars = "Both"  # Ajouter des barres de défilement horizontales et verticales
$resultsBox.Font = New-Object System.Drawing.Font("Consolas", 10)  # Police à largeur fixe pour un affichage aligné
$resultsBox.BackColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($resultsBox)

# Bouton "Exporter vers un fichier CSV"
$buttonExport = New-Object System.Windows.Forms.Button
$buttonExport.Location = New-Object System.Drawing.Point(490, 580)  # Position ajustée pour être aligné sous la zone de résultats
$buttonExport.Size = New-Object System.Drawing.Size(190, 40)
$buttonExport.Text = "Exporter vers un fichier CSV"
$buttonExport.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$buttonExport.ForeColor = [System.Drawing.Color]::Black
$buttonExport.BackColor = [System.Drawing.Color]::LightGray
$buttonExport.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
$buttonExport.Add_Click({
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "Fichiers CSV (*.csv)|*.csv"
    $saveFileDialog.Title = "Exporter vers un fichier CSV"
    $saveFileDialog.FileName = "Resultats_AD.csv"
    if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $resultsBox.Text | Out-File -FilePath $saveFileDialog.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Les résultats ont été exportés dans $($saveFileDialog.FileName)", "Export réussi")
    }
})
$form.Controls.Add($buttonExport)

# Bouton "Quitter"
$buttonExit = New-Object System.Windows.Forms.Button
$buttonExit.Location = New-Object System.Drawing.Point(720, 580)  # Position ajustée pour être plus éloigné du bouton "Exporter"
$buttonExit.Size = New-Object System.Drawing.Size(190, 40)
$buttonExit.Text = "Quitter"
$buttonExit.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$buttonExit.ForeColor = [System.Drawing.Color]::Black
$buttonExit.BackColor = [System.Drawing.Color]::LightGray
$buttonExit.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
$buttonExit.Add_Click({ $form.Close() })
$form.Controls.Add($buttonExit)

# Fonction pour afficher une boîte de dialogue de saisie
function Get-UserInput {
    param (
        [string]$Prompt,
        [string]$Title
    )
    $inputBox = New-Object System.Windows.Forms.Form
    $inputBox.Text = $Title
    $inputBox.Size = New-Object System.Drawing.Size(300, 150)
    $inputBox.StartPosition = "CenterScreen"

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Prompt
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(280, 20)
    $inputBox.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 50)
    $textBox.Size = New-Object System.Drawing.Size(260, 20)
    $inputBox.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75, 80)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $inputBox.Controls.Add($okButton)

    $inputBox.AcceptButton = $okButton
    $result = $inputBox.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $textBox.Text
    }
    return $null
}

# Fonction pour afficher les résultats dans la zone de texte
function Show-Result {
    param (
        [string]$Result
    )
    $resultsBox.Text = $Result
}

# Style des boutons
$buttonStyle = @{
    Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    ForeColor = [System.Drawing.Color]::Black
    BackColor = [System.Drawing.Color]::LightGray
    FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    Size = New-Object System.Drawing.Size(300, 40)
}

# Bouton 1 : Date de réinitialisation et expiration du mot de passe
$button1 = New-Object System.Windows.Forms.Button
$button1.Location = New-Object System.Drawing.Point(50, 70)
$button1.Text = "1. Date de réinitialisation et expiration du mot de passe"
$button1.Font = $buttonStyle.Font
$button1.ForeColor = $buttonStyle.ForeColor
$button1.BackColor = $buttonStyle.BackColor
$button1.FlatStyle = $buttonStyle.FlatStyle
$button1.Size = $buttonStyle.Size
$button1.Add_Click({
    $user = Get-UserInput -Prompt "Entrez le nom d'utilisateur (Identifiant)" -Title "Saisie utilisateur"
    if ($user) {
        try {
            # Vérifier si l'utilisateur existe
            $userInfo = Get-ADUser -Identity $user -Properties passwordlastset, msDS-UserPasswordExpiryTimeComputed, PasswordNeverExpires -ErrorAction Stop

            # Formater la date de réinitialisation du mot de passe
            $passwordLastSet = $userInfo.passwordlastset
            $passwordLastSetFormatted = $passwordLastSet.ToString("dddd dd/MM/yyyy à HH:mm", [System.Globalization.CultureInfo]::CreateSpecificCulture("fr-FR"))

            # Effacer le contenu actuel de la RichTextBox
            $resultsBox.Clear()

            # Ajouter le texte normal
            $resultsBox.AppendText("Le mot de passe de l'utilisateur ")

            # Ajouter le nom de l'utilisateur en bleu et en gras
            $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("$user")

            # Revenir à la police normale et à la couleur par défaut
            $resultsBox.SelectionColor = $resultsBox.ForeColor
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
            $resultsBox.AppendText(" a été ")

            # Ajouter "réinitialisé" en bleu et en gras
            $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("réinitialisé")

            # Revenir à la police normale et à la couleur par défaut
            $resultsBox.SelectionColor = $resultsBox.ForeColor
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
            $resultsBox.AppendText(" le ")

            # Ajouter la date et l'heure en bleu et en gras
            $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("$passwordLastSetFormatted")

            # Revenir à la police normale et à la couleur par défaut
            $resultsBox.SelectionColor = $resultsBox.ForeColor
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
            $resultsBox.AppendText(".`n`n")  # Deux sauts de ligne ici

            # Vérifier si le mot de passe n'expire jamais
            if ($userInfo.PasswordNeverExpires -eq $true) {
                # Ajouter le texte normal pour le deuxième message
                $resultsBox.AppendText("Le mot de passe du compte en question ")

                # Ajouter "n'expire jamais" en rouge et en gras
                $resultsBox.SelectionColor = [System.Drawing.Color]::Red
                $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
                $resultsBox.AppendText("n'expire jamais")

                # Revenir à la police normale et à la couleur par défaut
                $resultsBox.SelectionColor = $resultsBox.ForeColor
                $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
                $resultsBox.AppendText(".`n`n")
            } else {
                # Formater la date d'expiration du mot de passe
                $passwordExpiryTime = [datetime]::FromFileTime($userInfo.'msDS-UserPasswordExpiryTimeComputed')
                $passwordExpiryTimeFormatted = $passwordExpiryTime.ToString("dddd dd/MM/yyyy à HH:mm", [System.Globalization.CultureInfo]::CreateSpecificCulture("fr-FR"))

                # Ajouter le texte normal pour le deuxième message
                $resultsBox.AppendText("Le mot de passe du compte en question va ")

                # Ajouter "expirer" en rouge et en gras
                $resultsBox.SelectionColor = [System.Drawing.Color]::Red
                $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
                $resultsBox.AppendText("expirer")

                # Revenir à la police normale et à la couleur par défaut
                $resultsBox.SelectionColor = $resultsBox.ForeColor
                $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
                $resultsBox.AppendText(" le ")

                # Ajouter la date d'expiration en rouge et en gras
                $resultsBox.SelectionColor = [System.Drawing.Color]::Red
                $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
                $resultsBox.AppendText("$passwordExpiryTimeFormatted")

                # Revenir à la police normale et à la couleur par défaut
                $resultsBox.SelectionColor = $resultsBox.ForeColor
                $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
                $resultsBox.AppendText(".`n`n")
            }

            # Afficher le résultat du script comme dans PowerShell
            $expiryDateFormatted = if ($userInfo.PasswordNeverExpires -eq $true) {
                "Jamais"
            } else {
                [datetime]::FromFileTime($userInfo.'msDS-UserPasswordExpiryTimeComputed').ToString("dddd dd/MM/yyyy à HH:mm", [System.Globalization.CultureInfo]::CreateSpecificCulture("fr-FR"))
            }

            $scriptResult = @"
samaccountname         : $($userInfo.SamAccountName)
passwordlastset        : $($passwordLastSetFormatted)
expirydate             : $($expiryDateFormatted)
PasswordNeverExpires   : $($userInfo.PasswordNeverExpires)
"@
            $resultsBox.AppendText("Résultat du script :`n")
            $resultsBox.AppendText($scriptResult)
        } catch {
            # Si l'utilisateur n'existe pas, afficher un message d'erreur
            $resultsBox.Clear()
            $resultsBox.SelectionColor = [System.Drawing.Color]::Red  # Message d'erreur en rouge
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("Aucun compte AD avec cette nomination.")
        }
    }
})
$form.Controls.Add($button1)

# Bouton 2 : Nombre d'utilisateurs dans un groupe AD
$button2 = New-Object System.Windows.Forms.Button
$button2.Location = New-Object System.Drawing.Point(50, 120)
$button2.Text = "2. Nombre d'utilisateurs dans un groupe AD"
$button2.Font = $buttonStyle.Font
$button2.ForeColor = $buttonStyle.ForeColor
$button2.BackColor = $buttonStyle.BackColor
$button2.FlatStyle = $buttonStyle.FlatStyle
$button2.Size = $buttonStyle.Size
$button2.Add_Click({
    $group = Get-UserInput -Prompt "Entrez le nom du groupe" -Title "Saisie groupe"
    if ($group) {
        try {
            # Vérifier si le groupe existe
            $groupExists = Get-ADGroup -Identity $group -ErrorAction Stop

            # Récupérer le nombre d'utilisateurs dans le groupe
            $count = (Get-ADGroup $group -Properties *).Member.Count

            # Effacer le contenu actuel de la RichTextBox
            $resultsBox.Clear()

            # Ajouter le texte normal
            $resultsBox.AppendText("Le nombre d'utilisateurs dans le groupe ")

            # Ajouter le nom du groupe en bleu et en gras
            $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("$group")

            # Revenir à la police normale et à la couleur par défaut
            $resultsBox.SelectionColor = $resultsBox.ForeColor
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
            $resultsBox.AppendText(" est : ")

            # Ajouter le nombre d'utilisateurs en bleu et en gras
            $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("$count")

            # Revenir à la police normale et à la couleur par défaut
            $resultsBox.SelectionColor = $resultsBox.ForeColor
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
        } catch {
            # Si le groupe n'existe pas, afficher un message d'erreur
            $resultsBox.Clear()
            $resultsBox.SelectionColor = [System.Drawing.Color]::Red  # Message d'erreur en rouge
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("Aucun groupe AD avec cette nomination.")
        }
    }
})
$form.Controls.Add($button2)

# Bouton 3 : Liste des comptes utilisateurs créés entre deux dates (avec calendrier et sélection des OU)
$button3 = New-Object System.Windows.Forms.Button
$button3.Location = New-Object System.Drawing.Point(50, 170)
$button3.Text = "3. Comptes utilisateurs créés entre deux dates"
$button3.Font = $buttonStyle.Font
$button3.ForeColor = $buttonStyle.ForeColor
$button3.BackColor = $buttonStyle.BackColor
$button3.FlatStyle = $buttonStyle.FlatStyle
$button3.Size = $buttonStyle.Size
$button3.Add_Click({
    # Créer une nouvelle boîte de dialogue pour sélectionner les dates et les OU
    $dateDialog = New-Object System.Windows.Forms.Form
    $dateDialog.Text = "Sélectionner les dates et les OU"
    $dateDialog.Size = New-Object System.Drawing.Size(350, 300) # Ajuster la taille pour tout afficher
    $dateDialog.StartPosition = "CenterScreen"
    $dateDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $dateDialog.MaximizeBox = $false
    $dateDialog.MinimizeBox = $false

    # Ajouter un calendrier pour la date de début
    $labelStart = New-Object System.Windows.Forms.Label
    $labelStart.Text = "Date de début :"
    $labelStart.Location = New-Object System.Drawing.Point(10, 20)
    $labelStart.Size = New-Object System.Drawing.Size(100, 20)
    $dateDialog.Controls.Add($labelStart)

    $datePickerStart = New-Object System.Windows.Forms.DateTimePicker
    $datePickerStart.Location = New-Object System.Drawing.Point(120, 20)
    $datePickerStart.Size = New-Object System.Drawing.Size(150, 20)
    $datePickerStart.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
    $dateDialog.Controls.Add($datePickerStart)

    # Ajouter un calendrier pour la date de fin
    $labelEnd = New-Object System.Windows.Forms.Label
    $labelEnd.Text = "Date de fin :"
    $labelEnd.Location = New-Object System.Drawing.Point(10, 60)
    $labelEnd.Size = New-Object System.Drawing.Size(100, 20)
    $dateDialog.Controls.Add($labelEnd)

    $datePickerEnd = New-Object System.Windows.Forms.DateTimePicker
    $datePickerEnd.Location = New-Object System.Drawing.Point(120, 60)
    $datePickerEnd.Size = New-Object System.Drawing.Size(150, 20)
    $datePickerEnd.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
    $dateDialog.Controls.Add($datePickerEnd)

    # Ajouter un label "Sélectionner les OU :"
    $labelOU = New-Object System.Windows.Forms.Label
    $labelOU.Text = "Sélectionner les OU :"
    $labelOU.Location = New-Object System.Drawing.Point(10, 100)
    $labelOU.Size = New-Object System.Drawing.Size(150, 20)
    $dateDialog.Controls.Add($labelOU)

    # Case à cocher pour Bejaia (alignée sous le label)
    $checkBoxBejaia = New-Object System.Windows.Forms.CheckBox
    $checkBoxBejaia.Text = "Bejaia"
    $checkBoxBejaia.Location = New-Object System.Drawing.Point(10, 130)
    $checkBoxBejaia.Size = New-Object System.Drawing.Size(100, 20)
    $dateDialog.Controls.Add($checkBoxBejaia)

    # Case à cocher pour Cojek (alignée sous Bejaia)
    $checkBoxCojek = New-Object System.Windows.Forms.CheckBox
    $checkBoxCojek.Text = "Cojek"
    $checkBoxCojek.Location = New-Object System.Drawing.Point(10, 160)
    $checkBoxCojek.Size = New-Object System.Drawing.Size(100, 20)
    $dateDialog.Controls.Add($checkBoxCojek)

    # Case à cocher pour Lalla Khedidja (alignée sous Cojek)
    $checkBoxLallaKhedidja = New-Object System.Windows.Forms.CheckBox
    $checkBoxLallaKhedidja.Text = "Lalla Khedidja"
    $checkBoxLallaKhedidja.Location = New-Object System.Drawing.Point(10, 190)
    $checkBoxLallaKhedidja.Size = New-Object System.Drawing.Size(120, 20)
    $dateDialog.Controls.Add($checkBoxLallaKhedidja)

    # Ajouter un bouton "OK" pour valider les dates et les OU
    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Location = New-Object System.Drawing.Point(100, 230)
    $buttonOK.Size = New-Object System.Drawing.Size(75, 30)
    $buttonOK.Text = "OK"
    $buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dateDialog.AcceptButton = $buttonOK
    $dateDialog.Controls.Add($buttonOK)

    # Afficher la boîte de dialogue et vérifier si l'utilisateur a cliqué sur OK
    if ($dateDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $startDate = $datePickerStart.Value.Date
        $endDate = $datePickerEnd.Value.Date

        # Vérifier que la date de début n'est pas postérieure à la date de fin
        if ($startDate -gt $endDate) {
            $resultsBox.Clear()
            $resultsBox.SelectionColor = [System.Drawing.Color]::Red  # Message d'erreur en rouge
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("Erreur : La date de début ne peut pas être postérieure à la date de fin.")
        } else {
            # Liste des OU sélectionnées
            $selectedOUs = @()
            if ($checkBoxBejaia.Checked) { $selectedOUs += 'OU=bejaia,DC=cevital,DC=com' }
            if ($checkBoxCojek.Checked) { $selectedOUs += 'OU=Cojek,DC=cevital,DC=com' }
            if ($checkBoxLallaKhedidja.Checked) { $selectedOUs += 'OU=Lalla Khedidja,DC=cevital,DC=com' }

            # Récupérer les utilisateurs créés entre les deux dates pour chaque OU sélectionnée
            $results = @()
            foreach ($ou in $selectedOUs) {
                $users = Get-ADUser -Filter { whenCreated -ge $startDate -and whenCreated -le $endDate } `
                         -SearchBase $ou `
                         -Properties whenCreated, DistinguishedName | `
                         Select-Object Name, whenCreated, @{Name="OU"; Expression={
                             # Extraire le premier OU avant DC=cevital,DC=com
                             ($_.DistinguishedName -split ',') | Where-Object { $_ -like 'OU=*' } | Select-Object -Last 1 | ForEach-Object { $_ -replace 'OU=', '' }
                         }}
                $results += $users
            }

            # Afficher les résultats dans la RichTextBox sous forme de tableau
            $resultsBox.Clear()
            if ($results.Count -gt 0) {
                # Si plusieurs OU sont sélectionnées, afficher la colonne OU
                if ($selectedOUs.Count -gt 1) {
                    $resultsBox.AppendText("Name          whenCreated           OU`n")
                    $resultsBox.AppendText("----          -----------           --`n")
                    $results | Sort-Object whenCreated | ForEach-Object {
                        $resultsBox.AppendText(("{0,-15} {1,-20} {2}" -f $_.Name, $_.whenCreated, $_.OU) + "`n")
                    }
                } else {
                    # Si une seule OU est sélectionnée, ne pas afficher la colonne OU
                    $resultsBox.AppendText("Name          whenCreated`n")
                    $resultsBox.AppendText("----          -----------`n")
                    $results | Sort-Object whenCreated | ForEach-Object {
                        $resultsBox.AppendText(("{0,-15} {1,-20}" -f $_.Name, $_.whenCreated) + "`n")
                    }
                }
            } else {
                $resultsBox.SelectionColor = [System.Drawing.Color]::Red  # Message d'erreur en rouge
                $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
                $resultsBox.AppendText("Aucun utilisateur trouvé dans les OU sélectionnées pour la période spécifiée.")
            }
        }
    }
})
$form.Controls.Add($button3)

# Bouton 4 : Vérifier si un utilisateur possède Office365
$button4 = New-Object System.Windows.Forms.Button
$button4.Location = New-Object System.Drawing.Point(50, 220)
$button4.Text = "4. Vérifier si un utilisateur possède Office365"
$button4.Font = $buttonStyle.Font
$button4.ForeColor = $buttonStyle.ForeColor
$button4.BackColor = $buttonStyle.BackColor
$button4.FlatStyle = $buttonStyle.FlatStyle
$button4.Size = $buttonStyle.Size
$button4.Add_Click({
    $user = Get-UserInput -Prompt "Entrez le nom d'utilisateur (Identifiant)" -Title "Saisie utilisateur"
    if ($user) {
        try {
            # Vérifier si l'utilisateur existe dans AD
            $adUser = Get-ADUser -Identity $user -Properties msDS-cloudExtensionAttribute20 -ErrorAction Stop

            # Effacer le contenu actuel de la RichTextBox
            $resultsBox.Clear()

            # Ajouter le texte normal
            $resultsBox.AppendText("L'utilisateur ")

            # Ajouter le nom de l'utilisateur en bleu et en gras
            $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("$user")

            # Revenir à la police normale et à la couleur par défaut
            $resultsBox.SelectionColor = $resultsBox.ForeColor
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
            $resultsBox.AppendText(" ")

            # Vérifier si l'attribut msDS-cloudExtensionAttribute20 est présent
            if ($adUser.'msDS-cloudExtensionAttribute20') {
                # Convertir la valeur en minuscules pour la comparaison
                $attributeValue = $adUser.'msDS-cloudExtensionAttribute20'.ToLower()

                if ($attributeValue -eq "office365") {
                    # Ajouter "possède une licence Office365" en vert et en gras
                    $resultsBox.SelectionColor = [System.Drawing.Color]::Green
                    $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
                    $resultsBox.AppendText("possède une licence Office365")
                } else {
                    # Ajouter "ne possède pas de licence office365 car la valeur saisie est incorrecte" en rouge et en gras
                    $resultsBox.SelectionColor = [System.Drawing.Color]::red
                    $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
                    $resultsBox.AppendText("ne possède pas de licence office365 car la valeur saisie est incorrecte")
                }
            } else {
                # Ajouter "ne possède pas de licence Office365" en rouge et en gras
                $resultsBox.SelectionColor = [System.Drawing.Color]::Red
                $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
                $resultsBox.AppendText("ne possède pas de licence Office365")
            }

            # Revenir à la police normale et à la couleur par défaut
            $resultsBox.SelectionColor = $resultsBox.ForeColor
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
            $resultsBox.AppendText(".`n`n")

            # Afficher le résultat du script comme dans PowerShell
            $scriptResult = @"
samaccountname         : $($adUser.SamAccountName)
msDS-cloudExtensionAttribute20 : $($adUser.'msDS-cloudExtensionAttribute20')
"@
            $resultsBox.AppendText("Résultat du script :`n")
            $resultsBox.AppendText($scriptResult)
        } catch {
            # Si l'utilisateur n'existe pas, afficher un message d'erreur
            $resultsBox.Clear()
            $resultsBox.SelectionColor = [System.Drawing.Color]::Red  # Message d'erreur en rouge
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("Aucun compte AD avec cette nomination.")
        }
    }
})
$form.Controls.Add($button4)

# Bouton 5 : Comptes inactifs depuis un certain temps
$button5 = New-Object System.Windows.Forms.Button
$button5.Location = New-Object System.Drawing.Point(50, 270)
$button5.Text = "5. Comptes inactifs depuis un certain temps"
$button5.Font = $buttonStyle.Font
$button5.ForeColor = $buttonStyle.ForeColor
$button5.BackColor = $buttonStyle.BackColor
$button5.FlatStyle = $buttonStyle.FlatStyle
$button5.Size = $buttonStyle.Size
$button5.Add_Click({
    # Créer une nouvelle fenêtre pour saisir le nombre de jours, choisir le type de comptes et les OU
    $inactiveDialog = New-Object System.Windows.Forms.Form
    $inactiveDialog.Text = "Rechercher les comptes inactifs"
    $inactiveDialog.Size = New-Object System.Drawing.Size(300, 300) # Ajuster la taille pour tout afficher
    $inactiveDialog.StartPosition = "CenterScreen"
    $inactiveDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $inactiveDialog.MaximizeBox = $false
    $inactiveDialog.MinimizeBox = $false

    # Ajouter un label pour la saisie du nombre de jours
    $labelDays = New-Object System.Windows.Forms.Label
    $labelDays.Text = "Nombre de jours d'inactivité :"
    $labelDays.Location = New-Object System.Drawing.Point(10, 20)
    $labelDays.Size = New-Object System.Drawing.Size(200, 20)
    $inactiveDialog.Controls.Add($labelDays)

    # Ajouter une zone de texte pour saisir le nombre de jours
    $textBoxDays = New-Object System.Windows.Forms.TextBox
    $textBoxDays.Location = New-Object System.Drawing.Point(10, 40)
    $textBoxDays.Size = New-Object System.Drawing.Size(260, 20)
    $inactiveDialog.Controls.Add($textBoxDays)

    # Ajouter un label pour le choix du type de comptes
    $labelChoice = New-Object System.Windows.Forms.Label
    $labelChoice.Text = "Choisir le type de comptes :"
    $labelChoice.Location = New-Object System.Drawing.Point(10, 70)
    $labelChoice.Size = New-Object System.Drawing.Size(200, 20)
    $inactiveDialog.Controls.Add($labelChoice)

    # Ajouter un bouton radio pour "Tous les comptes"
    $radioAll = New-Object System.Windows.Forms.RadioButton
    $radioAll.Text = "Tous les comptes"
    $radioAll.Location = New-Object System.Drawing.Point(20, 90)
    $radioAll.Size = New-Object System.Drawing.Size(200, 20)
    $radioAll.Checked = $true  # Option sélectionnée par défaut
    $inactiveDialog.Controls.Add($radioAll)

    # Ajouter un bouton radio pour "Comptes actifs"
    $radioEnabled = New-Object System.Windows.Forms.RadioButton
    $radioEnabled.Text = "Comptes actifs"
    $radioEnabled.Location = New-Object System.Drawing.Point(20, 110)
    $radioEnabled.Size = New-Object System.Drawing.Size(200, 20)
    $inactiveDialog.Controls.Add($radioEnabled)

    # Ajouter un label pour le choix des OU
    $labelOU = New-Object System.Windows.Forms.Label
    $labelOU.Text = "Choisir les OU :"
    $labelOU.Location = New-Object System.Drawing.Point(10, 140)
    $labelOU.Size = New-Object System.Drawing.Size(200, 20)
    $inactiveDialog.Controls.Add($labelOU)

    # Ajouter une case à cocher pour "Bejaia"
    $checkBoxBejaia = New-Object System.Windows.Forms.CheckBox
    $checkBoxBejaia.Text = "Bejaia"
    $checkBoxBejaia.Location = New-Object System.Drawing.Point(20, 160)
    $checkBoxBejaia.Size = New-Object System.Drawing.Size(100, 20)
    $inactiveDialog.Controls.Add($checkBoxBejaia)

    # Ajouter une case à cocher pour "Cojek"
    $checkBoxCojek = New-Object System.Windows.Forms.CheckBox
    $checkBoxCojek.Text = "Cojek"
    $checkBoxCojek.Location = New-Object System.Drawing.Point(20, 180)
    $checkBoxCojek.Size = New-Object System.Drawing.Size(100, 20)
    $inactiveDialog.Controls.Add($checkBoxCojek)

    # Ajouter une case à cocher pour "Lalla Khedidja"
    $checkBoxLallaKhedidja = New-Object System.Windows.Forms.CheckBox
    $checkBoxLallaKhedidja.Text = "Lalla Khedidja"
    $checkBoxLallaKhedidja.Location = New-Object System.Drawing.Point(20, 200)
    $checkBoxLallaKhedidja.Size = New-Object System.Drawing.Size(120, 20)
    $inactiveDialog.Controls.Add($checkBoxLallaKhedidja)

    # Ajouter un bouton "OK" pour valider
    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Location = New-Object System.Drawing.Point(100, 230)
    $buttonOK.Size = New-Object System.Drawing.Size(75, 30)
    $buttonOK.Text = "OK"
    $buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $inactiveDialog.AcceptButton = $buttonOK
    $inactiveDialog.Controls.Add($buttonOK)

    # Afficher la boîte de dialogue et vérifier si l'utilisateur a cliqué sur OK
    if ($inactiveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $days = $textBoxDays.Text
        if ($days -match '^\d+$') {
            $When = ((Get-Date).AddDays(-$days)).Date

            # Déterminer les OU sélectionnées
            $selectedOUs = @()
            if ($checkBoxBejaia.Checked) { $selectedOUs += 'OU=Bejaia,DC=Cevital,DC=com' }
            if ($checkBoxCojek.Checked) { $selectedOUs += 'OU=Cojek,DC=Cevital,DC=com' }
            if ($checkBoxLallaKhedidja.Checked) { $selectedOUs += 'OU=Lalla Khedidja,DC=Cevital,DC=com' }

            # Filtrer les comptes en fonction du choix de l'utilisateur
            $results = @()
            foreach ($ou in $selectedOUs) {
                if ($radioAll.Checked) {
                    # Tous les comptes (actifs et désactivés)
                    $inactiveUsers = Get-ADUser -Filter { LastLogonDate -lt $When } -Properties * -SearchBase $ou | 
                                    Select-Object samaccountname, LastLogonDate, Enabled, @{Name="OU"; Expression={
                                        # Extraire le premier OU avant DC=Cevital,DC=com
                                        ($_.DistinguishedName -split ',') | Where-Object { $_ -like 'OU=*' } | Select-Object -Last 1 | ForEach-Object { $_ -replace 'OU=', '' }
                                    }}
                } else {
                    # Seulement les comptes actifs
                    $inactiveUsers = Get-ADUser -Filter { LastLogonDate -lt $When -and Enabled -eq $true } -Properties * -SearchBase $ou | 
                                    Select-Object samaccountname, LastLogonDate, Enabled, @{Name="OU"; Expression={
                                        # Extraire le premier OU avant DC=Cevital,DC=com
                                        ($_.DistinguishedName -split ',') | Where-Object { $_ -like 'OU=*' } | Select-Object -Last 1 | ForEach-Object { $_ -replace 'OU=', '' }
                                    }}
                }
                $results += $inactiveUsers
            }

            # Afficher les résultats
            if ($results.Count -gt 0) {
                # Si plusieurs OU sont sélectionnées, afficher la colonne OU
                if ($selectedOUs.Count -gt 1) {
                    $results | Sort-Object LastLogonDate | Format-Table -AutoSize | Out-String
                    Show-Result -Result ($results | Sort-Object LastLogonDate | Format-Table -AutoSize | Out-String)
                } else {
                    # Si une seule OU est sélectionnée, ne pas afficher la colonne OU
                    $results | Sort-Object LastLogonDate | Select-Object samaccountname, LastLogonDate, Enabled | Format-Table -AutoSize | Out-String
                    Show-Result -Result ($results | Sort-Object LastLogonDate | Select-Object samaccountname, LastLogonDate, Enabled | Format-Table -AutoSize | Out-String)
                }
            } else {
                Show-Result -Result "Aucun compte inactif trouvé dans les OU sélectionnées pour la période spécifiée."
            }
        } else {
            Show-Result -Result "Erreur : Veuillez entrer un nombre valide de jours."
        }
    }
})
$form.Controls.Add($button5)

# Bouton 6 : Tester le DD avec HDSentinel
$button6 = New-Object System.Windows.Forms.Button
$button6.Location = New-Object System.Drawing.Point(50, 320)
$button6.Text = "6. Tester l'état du DD avec HDSentinel"
$button6.Font = $buttonStyle.Font
$button6.ForeColor = $buttonStyle.ForeColor
$button6.BackColor = $buttonStyle.BackColor
$button6.FlatStyle = $buttonStyle.FlatStyle
$button6.Size = $buttonStyle.Size
$button6.Add_Click({
    $exePath = "\\cevnas0102\Software\Scripts\HDSentinel\HDSentinel.exe"
    if (Test-Path $exePath -PathType Leaf) {
        Start-Process -FilePath $exePath -Wait
    } else {
        Show-Result -Result "Erreur : Le fichier $exePath n'existe pas."
    }
})
$form.Controls.Add($button6)

# Bouton 7 : Informations systèmes et réseaux
$button7 = New-Object System.Windows.Forms.Button
$button7.Location = New-Object System.Drawing.Point(50, 370)
$button7.Text = "7. Informations systèmes et réseaux"
$button7.Font = $buttonStyle.Font
$button7.ForeColor = $buttonStyle.ForeColor
$button7.BackColor = $buttonStyle.BackColor
$button7.FlatStyle = $buttonStyle.FlatStyle
$button7.Size = $buttonStyle.Size
$button7.Add_Click({
    $remoteComputer = Get-UserInput -Prompt "Entrez le nom de la machine distante" -Title "Saisie machine distante"
    if ($remoteComputer) {
        $result = ""
        # Vérifier si la machine distante est accessible
        if (Test-Connection -ComputerName $remoteComputer -Count 1 -Quiet) {
            try {
                # Récupérer les informations sur les disques durs (HDD ou SSD)
                $disks = Get-WmiObject -Class MSFT_PhysicalDisk -ComputerName $remoteComputer -Namespace root\Microsoft\Windows\Storage |
                         Select-Object Model,
                                       @{
                                           name="MediaType";
                                           expression={
                                               switch ($_.MediaType)
                                               {
                                                   3 {"HDD"}
                                                   4 {"SSD"}
                                                   default {"Unknown"}
                                               }
                                           }
                                       }
                $result += "====================================`n"
                $result += "Informations sur les disques durs :`n"
                $result += "====================================`n"
                foreach ($disk in $disks) {
                    $result += "Modele du disque dur : $($disk.Model)`n"
                    $result += "Type de disque : $($disk.MediaType)`n"
                }

                # Obtenir les informations sur les disques logiques
                $logicalDisks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $remoteComputer

                $result += "`n`n===========================================`n"
                $result += "Informations sur les lecteurs de disque`n"
                $result += "===========================================`n"
                foreach ($disk in $logicalDisks) {
                    $diskSize = [math]::round($disk.Size / 1GB, 2)
                    $freeSpace = [math]::round($disk.FreeSpace / 1GB, 2)
                    $result += " `n"
                    $result += "Lecteur : $($disk.DeviceID)`n"
                    $result += "Taille de disque : $diskSize Go`n"
                    $result += "Espace libre : $freeSpace Go`n"
                }

                # Obtenir les informations sur la machine distante
                $computerSystem = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $remoteComputer
                $manufacturer = $computerSystem.Manufacturer
                $machineModel = $computerSystem.Model
                $machineName = $computerSystem.Name
                $serialNumber = $computerSystem.SerialNumber

                # Si le numéro de série est vide, essayer de récupérer à partir de Win32_BIOS
                if ([string]::IsNullOrEmpty($serialNumber)) {
                    $bios = Get-WmiObject -Class Win32_BIOS -ComputerName $remoteComputer
                    $serialNumber = $bios.SerialNumber
                }

                # Obtenir les informations sur la RAM installée
                $ramModules = Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $remoteComputer

                # Afficher les informations détaillées sur la RAM
                $result += "`n`n========`n"
                $result += "RAM`n"
                $result += "========`n"
                $result += "Nombre total de modules de RAM trouves : $($ramModules.Count)`n"
                foreach ($ram in $ramModules) {
                    $result += "Module RAM : $($ram.DeviceLocator), Capacite : $([math]::round($ram.Capacity / 1GB, 2)) Go`n"
                }

                # Filtrer et compter les modules de RAM utilisés
                $usedRamModules = $ramModules | Where-Object { $_.Capacity -gt 0 }
                $usedRamSlots = $usedRamModules.Count

                # Afficher le nombre de slots de RAM utilisés
                $result += "`nNombre de slots de RAM utilises : $usedRamSlots`n"

                # Afficher les détails des slots de RAM utilisés
                foreach ($ram in $usedRamModules) {
                    $result += "Slot utilise : $($ram.DeviceLocator), Capacite : $([math]::round($ram.Capacity / 1GB, 2)) Go`n"
                }

                # Si aucun module de RAM n'est utilisé, afficher un message approprié
                if ($ramModules.Count -eq 0) {
                    $result += "`nAucun module de RAM utilisé.`n"
                    $result += "=============================`n"
                }

                # Obtenir les informations sur le processeur
                $processor = Get-WmiObject -Class Win32_Processor -ComputerName $remoteComputer
                $cpuName = $processor.Name
                $cpuCores = $processor.NumberOfCores
                $cpuMaxSpeed = $processor.MaxClockSpeed

                # Obtenir les informations sur les adaptateurs réseau avec adresse IP activée
                $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'" -ComputerName $remoteComputer
                $networkInfo = $networkAdapters | Where-Object { $_.IPAddress -ne $null }
                $macAddress = $networkInfo.MACAddress
                $ipAddress = $networkInfo.IPAddress[0]

                # Déterminer le statut de l'IPv6
                $IPv6Status = if ($networkInfo.IPAddress -like '*:*') {
                    "Active (Carte reseau : $($networkInfo.Description))"
                } else {
                    "Desactive"
                }

                # Obtenir les informations sur le système d'exploitation
                $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $remoteComputer
                $osName = $os.Caption
                $osVersion = $os.Version
                $osBuildNumber = $os.BuildNumber
                $osReleaseId = $os.OSArchitecture

                # Obtenir la dernière mise à jour installée
                $lastUpdate = Get-HotFix -ComputerName $remoteComputer | Sort-Object InstalledOn -Descending | Select-Object -First 1

                # Afficher les informations récupérées
                $result += "`n`n==============================`n"
                $result += "Informations sur la machine :`n"
                $result += "==============================`n"
                $result += "Nom de la machine : $machineName`n"
                $result += "Fabricant de la machine : $manufacturer`n"
                $result += "Modele de la machine : $machineModel`n"
                $result += "Numero de serie : $serialNumber`n"
                # Obtenir le nom d'utilisateur de la session active sur la machine spécifiée
                $sessionUtilisateur = Get-WmiObject -ComputerName $remoteComputer -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName
                $result += "l'utilisateur actif est : $sessionUtilisateur`n"
                $result += " `n"
                $result += " `n"
                $result += "===========`n"
                $result += "Reseaux`n"
                $result += "===========`n"
                $result += "Adresse IP : $ipAddress`n"
                $result += "Adresse MAC : $macAddress`n"
                $result += "Etat IPv6 : $IPv6Status`n"
                $result += " `n"
                $result += " `n"
                $result += "============`n"
                $result += "Processeur`n"
                $result += "============`n"
                $result += "Processeur : $cpuName`n"
                $result += "Nombre de cours : $cpuCores`n"
                $result += "Vitesse maximale du processeur : $cpuMaxSpeed MHz`n"
                $result += " `n"
                $result += " `n"
                $result += "========`n"
                $result += "OS`n"
                $result += "========`n"
                $result += "Systeme d'exploitation : $osName`n"
                $result += "Version : $osVersion`n"
                $result += "Numero de build : $osBuildNumber`n"
                $result += "Architecture : $osReleaseId`n"
                if ($lastUpdate) {
                    $formattedDate = $lastUpdate.InstalledOn.ToString("dd/MM/yyyy")
                    $result += "Derniere mise a jour installee : $($lastUpdate.HotFixID) installee le $formattedDate`n"
                    $result += "Type de la mise a jour :$($lastUpdate.Description)`n"
                } else {
                    $result += "Aucune mise à jour installée trouvée.`n"
                }

            } catch {
                $result += "Erreur lors de la récupération des informations : $_`n"
                $result += " `n"
            }

        } else {
            $result += "La machine distante n'est pas accessible. Veuillez vérifier le nom et la connectivité réseau.`n"
            $result += " `n"
        }
        Show-Result -Result $result
    }
})
$form.Controls.Add($button7)

# Bouton 8 : Microsoft Deployment Toolkit (MDT)
$button8 = New-Object System.Windows.Forms.Button
$button8.Location = New-Object System.Drawing.Point(50, 420)
$button8.Text = "8. Microsoft Deployment Toolkit (MDT)"
$button8.Font = $buttonStyle.Font
$button8.ForeColor = $buttonStyle.ForeColor
$button8.BackColor = $buttonStyle.BackColor
$button8.FlatStyle = $buttonStyle.FlatStyle
$button8.Size = $buttonStyle.Size
$button8.Add_Click({
    $scriptPath = "\\cevmdt0101\deploymentshare$\Scripts\LiteTouch.vbs"
    if (Test-Path $scriptPath -PathType Leaf) {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-Command `"Start-Process -FilePath '$scriptPath'`""
    } else {
        Show-Result -Result "Erreur : Le fichier $scriptPath n'existe pas."
    }
})
$form.Controls.Add($button8)

# Bouton 9 : Les comptes désactivés qui ont toujours Office365
$button9 = New-Object System.Windows.Forms.Button
$button9.Location = New-Object System.Drawing.Point(50, 470)
$button9.Text = "9. Comptes désactivés avec Office365"
$button9.Font = $buttonStyle.Font
$button9.ForeColor = $buttonStyle.ForeColor
$button9.BackColor = $buttonStyle.BackColor
$button9.FlatStyle = $buttonStyle.FlatStyle
$button9.Size = $buttonStyle.Size
$button9.Add_Click({
    # Récupérer les utilisateurs désactivés avec Office365
    $users = Get-ADUser -Filter { msDS-cloudExtensionAttribute20 -like "office365" -and Enabled -eq $False } `
             -SearchBase "OU=Bejaia,DC=Cevital,DC=com" `
             -Properties msDS-cloudExtensionAttribute20 | 
             Select-Object Name, SamAccountName, Enabled

    # Afficher les résultats dans la zone de texte
    if ($users) {
        $result = $users | Format-Table -AutoSize | Out-String
        Show-Result -Result $result
    } else {
        Show-Result -Result "Aucun compte utilisateur désactivé trouvé avec Office365."
    }
})
$form.Controls.Add($button9)

# Bouton 10 : Exportation de membres d'un ou plusieurs groupes
$button10 = New-Object System.Windows.Forms.Button
$button10.Location = New-Object System.Drawing.Point(50, 520)
$button10.Text = "10. Exportation de membres d'un ou plusieurs groupes"
$button10.Font = $buttonStyle.Font
$button10.ForeColor = $buttonStyle.ForeColor
$button10.BackColor = $buttonStyle.BackColor
$button10.FlatStyle = $buttonStyle.FlatStyle
$button10.Size = $buttonStyle.Size
$button10.Add_Click({
    # Créer une nouvelle fenêtre pour saisir les groupes
    $groupDialog = New-Object System.Windows.Forms.Form
    $groupDialog.Text = "Saisir les groupes"
    $groupDialog.Size = New-Object System.Drawing.Size(400, 200)
    $groupDialog.StartPosition = "CenterScreen"
    $groupDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $groupDialog.MaximizeBox = $false
    $groupDialog.MinimizeBox = $false

    # Ajouter un label pour la saisie des groupes
    $labelGroup = New-Object System.Windows.Forms.Label
    $labelGroup.Text = "Noms des groupes (séparés par une virgule) :"
    $labelGroup.Location = New-Object System.Drawing.Point(10, 20)
    $labelGroup.Size = New-Object System.Drawing.Size(300, 20)
    $groupDialog.Controls.Add($labelGroup)

    # Ajouter une zone de texte pour saisir les groupes
    $textBoxGroup = New-Object System.Windows.Forms.TextBox
    $textBoxGroup.Location = New-Object System.Drawing.Point(10, 50)
    $textBoxGroup.Size = New-Object System.Drawing.Size(360, 20)
    $groupDialog.Controls.Add($textBoxGroup)

    # Ajouter un bouton "OK" pour valider et afficher les résultats
    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Location = New-Object System.Drawing.Point(100, 100)
    $buttonOK.Size = New-Object System.Drawing.Size(75, 30)
    $buttonOK.Text = "OK"
    $buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $groupDialog.AcceptButton = $buttonOK
    $groupDialog.Controls.Add($buttonOK)

    # Afficher la boîte de dialogue et vérifier si l'utilisateur a cliqué sur OK
    if ($groupDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        # Récupérer les groupes saisis et les diviser en tableau
        $groups = $textBoxGroup.Text -split ',' | ForEach-Object { $_.Trim() }

        if ($groups.Count -gt 0) {
            # Récupérer les membres des groupes
            $results = foreach ($group in $groups) {
                try {
                    $groupMembers = Get-ADGroupMember -Identity $group -ErrorAction Stop
                    foreach ($member in $groupMembers) {
                        [PSCustomObject]@{
                            samaccountname = $member.samaccountname
                            GroupName      = $group
                        }
                    }
                } catch {
                    # En cas d'erreur (groupe non trouvé), ajouter un message d'erreur
                    [PSCustomObject]@{
                        samaccountname = "Erreur"
                        GroupName      = "Groupe non trouvé : $group"
                    }
                }
            }

            # Afficher les résultats dans la zone de texte
            if ($results) {
                $resultText = $results | Format-Table -AutoSize | Out-String
                Show-Result -Result $resultText
            } else {
                Show-Result -Result "Aucun membre trouvé pour les groupes spécifiés."
            }
        } else {
            Show-Result -Result "Aucun groupe n'a été saisi."
        }
    }
})
$form.Controls.Add($button10)

# Bouton 11 : Les comptes ayant des privilèges administratifs sur un serveur
$button11 = New-Object System.Windows.Forms.Button
$button11.Location = New-Object System.Drawing.Point(50, 570)  # Position ajustée pour être aligné sous les autres boutons
$button11.Text = "11. Les comptes ayant des privilèges administratifs sur un serveur"
$button11.Font = $buttonStyle.Font
$button11.ForeColor = $buttonStyle.ForeColor
$button11.BackColor = $buttonStyle.BackColor
$button11.FlatStyle = $buttonStyle.FlatStyle
$button11.Size = $buttonStyle.Size
$button11.Add_Click({
    # Demander le nom du serveur distant ou importer un fichier texte
    $choice = [System.Windows.Forms.MessageBox]::Show("Voulez-vous importer un fichier texte contenant une liste de serveurs ?", "Choix", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel)
    
    if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
        # Ouvrir une boîte de dialogue pour sélectionner un fichier texte
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "Fichiers texte (*.txt)|*.txt"
        $openFileDialog.Title = "Sélectionnez un fichier texte contenant la liste des serveurs"
        
        if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $servers = Get-Content -Path $openFileDialog.FileName
            $resultsBox.Clear()
            
            foreach ($remoteServer in $servers) {
                if ($remoteServer) {
                    # Vérifier si le serveur est accessible
                    if (Test-Connection -ComputerName $remoteServer -Count 1 -Quiet) {
                        try {
                            # Initialiser une liste pour stocker les comptes uniques
                            $adminAccounts = @()

                            # Vérifier le groupe "Administrateurs" (version française)
                            $queryFrench = "SELECT * FROM Win32_GroupUser WHERE GroupComponent='Win32_Group.Domain=""$remoteServer"",Name=""Administrateurs""'"
                            $adminAccounts += Get-WmiObject -ComputerName $remoteServer -Query $queryFrench | ForEach-Object {
                                if ($_.PartComponent -match 'Name="([^"]+)"') {
                                    $matches[1]
                                }
                            }

                            # Vérifier le groupe "Administrators" (version anglaise)
                            $queryEnglish = "SELECT * FROM Win32_GroupUser WHERE GroupComponent='Win32_Group.Domain=""$remoteServer"",Name=""Administrators""'"
                            $adminAccounts += Get-WmiObject -ComputerName $remoteServer -Query $queryEnglish | ForEach-Object {
                                if ($_.PartComponent -match 'Name="([^"]+)"') {
                                    $matches[1]
                                }
                            }

                            # Supprimer les doublons
                            $adminAccounts = $adminAccounts | Sort-Object -Unique

                            # Afficher les résultats dans la RichTextBox
                            $resultsBox.AppendText("Les comptes suivants ont un ")

                            # Ajouter "accès administrateur" en bleu
                            $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                            $resultsBox.AppendText("accès administrateur")

                            # Revenir à la couleur par défaut
                            $resultsBox.SelectionColor = $resultsBox.ForeColor
                            $resultsBox.AppendText(" sur le serveur ")

                            # Ajouter le nom du serveur en bleu
                            $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                            $resultsBox.AppendText("$remoteServer")

                            # Revenir à la couleur par défaut
                            $resultsBox.SelectionColor = $resultsBox.ForeColor
                            $resultsBox.AppendText(" :`n")

                            # Ajouter les comptes en bleu
                            if ($adminAccounts) {
                                $adminAccounts | ForEach-Object {
                                    $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                                    $resultsBox.AppendText("- $_`n")
                                }
                            } else {
                                $resultsBox.AppendText("Aucun compte administrateur trouvé sur le serveur $remoteServer.`n")
                            }
                        } catch {
                            $resultsBox.AppendText("Erreur lors de la récupération des comptes administrateurs pour le serveur $remoteServer : $_`n")
                            $resultsBox.AppendText("Vérifiez que WMI est accessible et que vous avez les permissions nécessaires.`n")
                        }
                    } else {
                        $resultsBox.AppendText("Le serveur $remoteServer n'est pas accessible. Vérifiez le nom et la connectivité réseau.`n")
                    }
                }
            }
        }
    } elseif ($choice -eq [System.Windows.Forms.DialogResult]::No) {
        # Demander le nom du serveur distant
        $remoteServer = Get-UserInput -Prompt "Entrez le nom du serveur distant" -Title "Saisie serveur distant"

        if ($remoteServer) {
            # Vérifier si le serveur est accessible
            if (Test-Connection -ComputerName $remoteServer -Count 1 -Quiet) {
                try {
                    # Initialiser une liste pour stocker les comptes uniques
                    $adminAccounts = @()

                    # Vérifier le groupe "Administrateurs" (version française)
                    $queryFrench = "SELECT * FROM Win32_GroupUser WHERE GroupComponent='Win32_Group.Domain=""$remoteServer"",Name=""Administrateurs""'"
                    $adminAccounts += Get-WmiObject -ComputerName $remoteServer -Query $queryFrench | ForEach-Object {
                        if ($_.PartComponent -match 'Name="([^"]+)"') {
                            $matches[1]
                        }
                    }

                    # Vérifier le groupe "Administrators" (version anglaise)
                    $queryEnglish = "SELECT * FROM Win32_GroupUser WHERE GroupComponent='Win32_Group.Domain=""$remoteServer"",Name=""Administrators""'"
                    $adminAccounts += Get-WmiObject -ComputerName $remoteServer -Query $queryEnglish | ForEach-Object {
                        if ($_.PartComponent -match 'Name="([^"]+)"') {
                            $matches[1]
                        }
                    }

                    # Supprimer les doublons
                    $adminAccounts = $adminAccounts | Sort-Object -Unique

                    # Afficher les résultats dans la RichTextBox
                    $resultsBox.Clear()

                    # Ajouter le texte normal
                    $resultsBox.AppendText("Les comptes suivants ont un ")

                    # Ajouter "accès administrateur" en bleu
                    $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                    $resultsBox.AppendText("accès administrateur")

                    # Revenir à la couleur par défaut
                    $resultsBox.SelectionColor = $resultsBox.ForeColor
                    $resultsBox.AppendText(" sur le serveur ")

                    # Ajouter le nom du serveur en bleu
                    $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                    $resultsBox.AppendText("$remoteServer")

                    # Revenir à la couleur par défaut
                    $resultsBox.SelectionColor = $resultsBox.ForeColor
                    $resultsBox.AppendText(" :`n")

                    # Ajouter les comptes en bleu
                    if ($adminAccounts) {
                        $adminAccounts | ForEach-Object {
                            $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                            $resultsBox.AppendText("- $_`n")
                        }
                    } else {
                        $resultsBox.AppendText("Aucun compte administrateur trouvé sur le serveur $remoteServer.`n")
                    }
                } catch {
                    $resultsBox.Clear()
                    $resultsBox.AppendText("Erreur lors de la récupération des comptes administrateurs : $_`n")
                    $resultsBox.AppendText("Vérifiez que WMI est accessible et que vous avez les permissions nécessaires.`n")
                }
            } else {
                $resultsBox.Clear()
                $resultsBox.AppendText("Le serveur $remoteServer n'est pas accessible. Vérifiez le nom et la connectivité réseau.`n")
            }
        }
    }
})
$form.Controls.Add($button11)

# Bouton 12 : Chercher le nom du groupe via des mots-clés obligatoires
$button12 = New-Object System.Windows.Forms.Button
$button12.Location = New-Object System.Drawing.Point(50, 620)  # Position ajustée pour être sous le bouton 11
$button12.Text = "12. Chercher le nom du groupe via des mots-clés obligatoires"
$button12.Font = $buttonStyle.Font
$button12.ForeColor = $buttonStyle.ForeColor
$button12.BackColor = $buttonStyle.BackColor
$button12.FlatStyle = $buttonStyle.FlatStyle
$button12.Size = $buttonStyle.Size
$button12.Add_Click({
    # Créer une nouvelle fenêtre pour saisir les mots-clés
    $keywordDialog = New-Object System.Windows.Forms.Form
    $keywordDialog.Text = "Saisir des mots-clés obligatoires pour rechercher des groupes"
    $keywordDialog.Size = New-Object System.Drawing.Size(400, 250)
    $keywordDialog.StartPosition = "CenterScreen"
    $keywordDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $keywordDialog.MaximizeBox = $false
    $keywordDialog.MinimizeBox = $false

    # Ajouter un label pour la saisie des mots-clés
    $labelKeyword = New-Object System.Windows.Forms.Label
    $labelKeyword.Text = "Saisir des mots-clés obligatoires (un par case) :"
    $labelKeyword.Location = New-Object System.Drawing.Point(10, 20)
    $labelKeyword.Size = New-Object System.Drawing.Size(300, 20)
    $keywordDialog.Controls.Add($labelKeyword)

    # Ajouter une zone de texte pour le premier mot-clé
    $textBoxKeyword1 = New-Object System.Windows.Forms.TextBox
    $textBoxKeyword1.Location = New-Object System.Drawing.Point(10, 50)
    $textBoxKeyword1.Size = New-Object System.Drawing.Size(360, 20)
    $keywordDialog.Controls.Add($textBoxKeyword1)

    # Ajouter une zone de texte pour le deuxième mot-clé
    $textBoxKeyword2 = New-Object System.Windows.Forms.TextBox
    $textBoxKeyword2.Location = New-Object System.Drawing.Point(10, 80)
    $textBoxKeyword2.Size = New-Object System.Drawing.Size(360, 20)
    $keywordDialog.Controls.Add($textBoxKeyword2)

    # Ajouter une zone de texte pour le troisième mot-clé
    $textBoxKeyword3 = New-Object System.Windows.Forms.TextBox
    $textBoxKeyword3.Location = New-Object System.Drawing.Point(10, 110)
    $textBoxKeyword3.Size = New-Object System.Drawing.Size(360, 20)
    $keywordDialog.Controls.Add($textBoxKeyword3)

    # Ajouter un bouton "OK" pour valider et afficher les résultats
    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Location = New-Object System.Drawing.Point(100, 150)
    $buttonOK.Size = New-Object System.Drawing.Size(75, 30)
    $buttonOK.Text = "OK"
    $buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $keywordDialog.AcceptButton = $buttonOK
    $keywordDialog.Controls.Add($buttonOK)

    # Afficher la boîte de dialogue et vérifier si l'utilisateur a cliqué sur OK
    if ($keywordDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        # Récupérer les mots-clés saisis
        $keywords = @(
            $textBoxKeyword1.Text.Trim(),
            $textBoxKeyword2.Text.Trim(),
            $textBoxKeyword3.Text.Trim()
        ) | Where-Object { -not [string]::IsNullOrEmpty($_) }  # Ignorer les champs vides

        if ($keywords.Count -gt 0) {
            # Rechercher les groupes dont le nom contient tous les mots-clés
            $groups = Get-ADGroup -Filter * | Where-Object {
                $groupName = $_.Name
                # Vérifier que tous les mots-clés sont présents dans le nom du groupe
                ($keywords | ForEach-Object { $groupName -like "*$_*" }) -notcontains $false
            } | Select-Object -ExpandProperty SamAccountName

            # Afficher les résultats dans la RichTextBox
            $resultsBox.Clear()

            # Ajouter le texte normal
            $resultsBox.AppendText("Les groupes suivants contiennent tous les mots-clés : ")

            # Ajouter les mots-clés en bleu
            $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
            $resultsBox.AppendText("$($keywords -join ', ')")

            # Revenir à la couleur par défaut
            $resultsBox.SelectionColor = $resultsBox.ForeColor
            $resultsBox.AppendText(" :`n")

            # Ajouter les groupes en bleu
            if ($groups) {
                $groups | ForEach-Object {
                    $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                    $resultsBox.AppendText("- $_`n")
                }
            } else {
                $resultsBox.AppendText("Aucun groupe trouvé contenant tous les mots-clés.`n")
            }
        } else {
            $resultsBox.Clear()
            $resultsBox.AppendText("Veuillez saisir au moins un mot-clé pour effectuer la recherche.`n")
        }
    }
})
$form.Controls.Add($button12)

# Bouton 13 : Liste des ordinateurs inactifs depuis un nombre de jours spécifié
$button13 = New-Object System.Windows.Forms.Button
$button13.Location = New-Object System.Drawing.Point(1000, 70)  # Position à droite de la zone de résultats
$button13.Text = "13. Ordinateurs inactifs depuis X jours"
$button13.Font = $buttonStyle.Font
$button13.ForeColor = $buttonStyle.ForeColor
$button13.BackColor = $buttonStyle.BackColor
$button13.FlatStyle = $buttonStyle.FlatStyle
$button13.Size = $buttonStyle.Size  # Même taille que les autres boutons (300x40)
$button13.Add_Click({
    # Créer une nouvelle boîte de dialogue pour saisir le nombre de jours et sélectionner les OU
    $inputDialog = New-Object System.Windows.Forms.Form
    $inputDialog.Text = "Saisir le nombre de jours et sélectionner les OU"
    $inputDialog.Size = New-Object System.Drawing.Size(350, 300)  # Ajuster la taille pour tout afficher
    $inputDialog.StartPosition = "CenterScreen"
    $inputDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $inputDialog.MaximizeBox = $false
    $inputDialog.MinimizeBox = $false

    # Ajouter un champ pour saisir le nombre de jours
    $labelDays = New-Object System.Windows.Forms.Label
    $labelDays.Text = "Nombre de jours :"
    $labelDays.Location = New-Object System.Drawing.Point(10, 20)
    $labelDays.Size = New-Object System.Drawing.Size(100, 20)
    $inputDialog.Controls.Add($labelDays)

    $textBoxDays = New-Object System.Windows.Forms.TextBox
    $textBoxDays.Location = New-Object System.Drawing.Point(120, 20)
    $textBoxDays.Size = New-Object System.Drawing.Size(100, 20)
    $inputDialog.Controls.Add($textBoxDays)

    # Ajouter un label "Sélectionner les OU :"
    $labelOU = New-Object System.Windows.Forms.Label
    $labelOU.Text = "Sélectionner les OU :"
    $labelOU.Location = New-Object System.Drawing.Point(10, 60)
    $labelOU.Size = New-Object System.Drawing.Size(150, 20)
    $inputDialog.Controls.Add($labelOU)

    # Case à cocher pour Bejaia (alignée sous le label)
    $checkBoxBejaia = New-Object System.Windows.Forms.CheckBox
    $checkBoxBejaia.Text = "Bejaia"
    $checkBoxBejaia.Location = New-Object System.Drawing.Point(10, 90)
    $checkBoxBejaia.Size = New-Object System.Drawing.Size(100, 20)
    $inputDialog.Controls.Add($checkBoxBejaia)

    # Case à cocher pour Cojek (alignée sous Bejaia)
    $checkBoxCojek = New-Object System.Windows.Forms.CheckBox
    $checkBoxCojek.Text = "Cojek"
    $checkBoxCojek.Location = New-Object System.Drawing.Point(10, 120)
    $checkBoxCojek.Size = New-Object System.Drawing.Size(100, 20)
    $inputDialog.Controls.Add($checkBoxCojek)

    # Case à cocher pour Lalla Khedidja (alignée sous Cojek)
    $checkBoxLallaKhedidja = New-Object System.Windows.Forms.CheckBox
    $checkBoxLallaKhedidja.Text = "Lalla Khedidja"
    $checkBoxLallaKhedidja.Location = New-Object System.Drawing.Point(10, 150)
    $checkBoxLallaKhedidja.Size = New-Object System.Drawing.Size(120, 20)
    $inputDialog.Controls.Add($checkBoxLallaKhedidja)

    # Ajouter un bouton "OK" pour valider les saisies
    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Location = New-Object System.Drawing.Point(100, 190)
    $buttonOK.Size = New-Object System.Drawing.Size(75, 30)
    $buttonOK.Text = "OK"
    $buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $inputDialog.AcceptButton = $buttonOK
    $inputDialog.Controls.Add($buttonOK)

    # Afficher la boîte de dialogue et vérifier si l'utilisateur a cliqué sur OK
    if ($inputDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        # Récupérer le nombre de jours saisi
        $daysInput = $textBoxDays.Text
        $days = 0
        if ([int]::TryParse($daysInput, [ref]$days)) {
            # Conversion réussie, $days contient la valeur entière
        } else {
            # Si la conversion échoue, définir $days à 0
            $days = 0
        }

        # Liste des OU sélectionnées
        $selectedOUs = @()
        if ($checkBoxBejaia.Checked) { $selectedOUs += 'OU=bejaia,DC=cevital,DC=com' }
        if ($checkBoxCojek.Checked) { $selectedOUs += 'OU=Cojek,DC=cevital,DC=com' }
        if ($checkBoxLallaKhedidja.Checked) { $selectedOUs += 'OU=Lalla Khedidja,DC=cevital,DC=com' }

        # Vérifier que le nombre de jours et au moins une OU sont valides
        if ($days -gt 0 -and $selectedOUs.Count -gt 0) {
            # Définir la période d'inactivité (nombre de jours avant la date actuelle)
            $inactivePeriod = (Get-Date).AddDays(-$days)

            # Rechercher les ordinateurs inactifs dans les OU sélectionnées
            $results = @()
            foreach ($ou in $selectedOUs) {
                $computers = Get-ADComputer -Filter { LastLogonTimestamp -lt $inactivePeriod } `
                           -SearchBase $ou `
                           -Properties LastLogonTimestamp, Name, DistinguishedName | `
                           Select-Object Name, @{Name="LastLogonDate"; Expression={[datetime]::FromFileTime($_.LastLogonTimestamp)}}, @{Name="OU"; Expression={
                               ($_.DistinguishedName -split ',') | Where-Object { $_ -like 'OU=*' } | Select-Object -Last 1 | ForEach-Object { $_ -replace 'OU=', '' }
                           }}
                $results += $computers
            }

            # Effacer le contenu actuel de la RichTextBox
            $resultsBox.Clear()

            # Vérifier si des ordinateurs inactifs ont été trouvés
            if ($results.Count -gt 0) {
                # Ajouter un en-tête de tableau
                $resultsBox.AppendText("Nom de la machine          Dernière utilisation           OU`n")
                $resultsBox.AppendText("-----------------          -------------------           --`n")

                # Parcourir chaque ordinateur inactif
                foreach ($computer in $results) {
                    # Ajouter les informations dans la RichTextBox
                    $resultsBox.AppendText(("{0,-25} {1,-25} {2}" -f $computer.Name, $computer.LastLogonDate, $computer.OU) + "`n")
                }
            } else {
                # Afficher un message si aucun ordinateur inactif n'est trouvé
                $resultsBox.SelectionColor = [System.Drawing.Color]::Red  # Message d'erreur en rouge
                $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
                $resultsBox.AppendText("Aucun ordinateur inactif trouvé dans les OU sélectionnées depuis $days jours.")
            }
        } else {
            # Afficher un message d'erreur si les saisies sont invalides
            $resultsBox.Clear()
            $resultsBox.SelectionColor = [System.Drawing.Color]::Red  # Message d'erreur en rouge
            $resultsBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("Erreur : Veuillez saisir un nombre de jours valide et sélectionner au moins une OU.")
        }
    }
})
$form.Controls.Add($button13)

# Bouton 14 : Lister les laptops manquants de CEVLAP1000 à CEVLAP1999
$button14 = New-Object System.Windows.Forms.Button
$button14.Location = New-Object System.Drawing.Point(1000, 120)  # Position à droite de la zone de résultats
$button14.Text = "14. Laptops manquants (CEVLAP1000 à CEVLAP1999)"
$button14.Font = $buttonStyle.Font
$button14.ForeColor = $buttonStyle.ForeColor
$button14.BackColor = $buttonStyle.BackColor
$button14.FlatStyle = $buttonStyle.FlatStyle
$button14.Size = $buttonStyle.Size  # Même taille que les autres boutons (300x40)
$button14.Add_Click({
    # Plage de noms de laptops à vérifier
    $startNumber = 1000
    $endNumber = 1999
    $missingLaptops = @()

    # Parcourir chaque numéro dans la plage
    for ($i = $startNumber; $i -le $endNumber; $i++) {
        $laptopName = "CEVLAP$i"  # Construire le nom du laptop

        # Vérifier si le laptop existe dans Active Directory
        try {
            $laptopExists = Get-ADComputer -Identity $laptopName -ErrorAction Stop
        } catch {
            # Si le laptop n'existe pas, l'ajouter à la liste des manquants
            $missingLaptops += $laptopName
        }
    }

    # Effacer le contenu actuel de la RichTextBox
    $resultsBox.Clear()

    # Afficher les résultats
    if ($missingLaptops.Count -gt 0) {
        # Ajouter un en-tête de tableau
        $resultsBox.AppendText("Laptops manquants de CEVLAP1000 à CEVLAP1999 :`n")
        $resultsBox.AppendText("---------------------------------------------`n")

        # Ajouter chaque laptop manquant dans la RichTextBox
        foreach ($laptop in $missingLaptops) {
            $resultsBox.AppendText("$laptop`n")
        }
    } else {
        # Aucun laptop manquant trouvé
        $resultsBox.AppendText("Aucun laptop manquant trouvé dans la plage CEVLAP1000 à CEVLAP1999.")
    }
})
$form.Controls.Add($button14)

# Bouton 15 : Qui a redémarré le serveur (Event ID 1074)
$button15 = New-Object System.Windows.Forms.Button
$button15.Location = New-Object System.Drawing.Point(1000, 170)  # Position juste en dessous du bouton 14 (120 + 40 + 10)
$button15.Text = "15. Qui a redémarré le serveur"
$button15.Font = $buttonStyle.Font
$button15.ForeColor = $buttonStyle.ForeColor
$button15.BackColor = $buttonStyle.BackColor
$button15.FlatStyle = $buttonStyle.FlatStyle
$button15.Size = $buttonStyle.Size  # Même taille que les autres boutons (300x40)
$button15.Add_Click({
    # Demander le nom du serveur distant
    $remoteServer = Get-UserInput -Prompt "Entrez le nom du serveur distant" -Title "Saisie serveur distant"

    if ($remoteServer) {
        # Vérifier si le serveur est accessible
        if (Test-Connection -ComputerName $remoteServer -Count 1 -Quiet) {
            try {
                # Récupérer les événements ID 1074 depuis le journal système
                $events = Get-WinEvent -ComputerName $remoteServer -LogName "System" -FilterXPath "*[System[(EventID=1074)]]" -ErrorAction Stop | 
                    ForEach-Object {
                        [PSCustomObject]@{
                            Date        = $_.TimeCreated.ToString("dd/MM/yyyy HH:mm:ss")  # Format jour/mois/année
                            Utilisateur = $_.Properties[6].Value  # Le compte ou processus responsable
                            Message     = $_.Message              # Détails de l'événement
                        }
                    }

                # Afficher les résultats dans la RichTextBox
                $resultsBox.Clear()

                # Ajouter le texte d'introduction
                $resultsBox.AppendText("Voici les informations sur qui a redémarré le serveur ")

                # Ajouter le nom du serveur en bleu
                $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                $resultsBox.AppendText("$remoteServer")

                # Revenir à la couleur par défaut
                $resultsBox.SelectionColor = $resultsBox.ForeColor
                $resultsBox.AppendText(" :`n`n")

                # Afficher chaque événement
                if ($events) {
                    $events | ForEach-Object {
                        $resultsBox.AppendText("Date : ")
                        $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                        $resultsBox.AppendText("$($_.Date)`n")
                        $resultsBox.SelectionColor = $resultsBox.ForeColor
                        $resultsBox.AppendText("Utilisateur/Processus : ")
                        $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                        $resultsBox.AppendText("$($_.Utilisateur)`n")
                        $resultsBox.SelectionColor = $resultsBox.ForeColor
                        $resultsBox.AppendText("Détails : $($_.Message)`n")
                        $resultsBox.AppendText("------------------------`n")
                    }
                } else {
                    $resultsBox.AppendText("Aucun événement ID 1074 trouvé sur le serveur $remoteServer.`n")
                }
            } catch {
                $resultsBox.Clear()
                $resultsBox.AppendText("Erreur lors de la récupération des événements : $_`n")
                $resultsBox.AppendText("Vérifiez les permissions, WinRM ou l'accès au journal système.`n")
            }
        } else {
            $resultsBox.Clear()
            $resultsBox.AppendText("Le serveur $remoteServer n'est pas accessible. Vérifiez le nom ou la connectivité réseau.`n")
        }
    }
})
$form.Controls.Add($button15)

# Bouton 16 : Lister les ACL du dossier parent et de ses sous-dossiers avec détails des droits d'accès
$button16 = New-Object System.Windows.Forms.Button
$button16.Location = New-Object System.Drawing.Point(1000, 210)  # Position juste en dessous du bouton 15 (170 + 40 + 10)
$button16.Text = "16. Lister les ACL d'un dossier"
$button16.Font = $buttonStyle.Font
$button16.ForeColor = $buttonStyle.ForeColor
$button16.BackColor = $buttonStyle.BackColor
$button16.FlatStyle = $buttonStyle.FlatStyle
$button16.Size = $buttonStyle.Size  # Même taille que les autres boutons (300x40)
$button16.Add_Click({
    # Demander le chemin du dossier
    $folderPath = Get-UserInput -Prompt "Entrez le chemin du dossier (ex: \\serveur\partage ou C:\Dossier)" -Title "Saisie chemin dossier"

    if ($folderPath) {
        # Vérifier si le dossier existe et est accessible
        if (Test-Path -Path $folderPath) {
            try {
                # Initialiser une liste pour stocker les ACL
                $aclList = @()

                # Traiter le dossier parent
                $acl = Get-Acl -Path $folderPath
                $acl.Access | ForEach-Object {
                    # Convertir les droits d'accès en une liste détaillée
                    $rights = $_.FileSystemRights.ToString().Split(', ') | ForEach-Object { $_.Trim() }
                    $rightsDetails = ($rights -join ', ')

                    $aclList += [PSCustomObject]@{
                        Chemin         = $folderPath  # Chemin du dossier parent
                        Utilisateur    = $_.IdentityReference.ToString()
                        TypeAcces      = $rightsDetails  # Droits d'accès détaillés
                        HeritageActive = (-not $acl.AreAccessRulesProtected)  # Héritage du dossier parent
                    }
                }

                # Traiter les sous-dossiers
                $subfolders = Get-ChildItem -Path $folderPath -Recurse -Directory -ErrorAction Stop
                foreach ($subfolder in $subfolders) {
                    $currentFolder = $subfolder.FullName  # Chemin complet du sous-dossier
                    $acl = Get-Acl -Path $currentFolder
                    $acl.Access | ForEach-Object {
                        # Convertir les droits d'accès en une liste détaillée
                        $rights = $_.FileSystemRights.ToString().Split(', ') | ForEach-Object { $_.Trim() }
                        $rightsDetails = ($rights -join ', ')

                        $aclList += [PSCustomObject]@{
                            Chemin         = $currentFolder  # Chemin du sous-dossier
                            Utilisateur    = $_.IdentityReference.ToString()
                            TypeAcces      = $rightsDetails  # Droits d'accès détaillés
                            HeritageActive = (-not $acl.AreAccessRulesProtected)  # Héritage du sous-dossier
                        }
                    }
                }

                # Afficher les résultats dans la RichTextBox
                $resultsBox.Clear()

                # Ajouter le texte d'introduction
                $resultsBox.AppendText("Liste des ACL pour le dossier ")
                $resultsBox.SelectionColor = [System.Drawing.Color]::Blue
                $resultsBox.AppendText("$folderPath")
                $resultsBox.SelectionColor = $resultsBox.ForeColor
                $resultsBox.AppendText(" et ses sous-dossiers :`n`n")

                # Ajouter les en-têtes de colonnes
                $resultsBox.AppendText("Chemin; Utilisateur; Type d'accès; Héritage`n")

                # Afficher chaque entrée avec séparation par points-virgules
                if ($aclList) {
                    foreach ($acl in $aclList) {
                        $resultsBox.AppendText("$($acl.Chemin); $($acl.Utilisateur); $($acl.TypeAcces); $($acl.HeritageActive)`n")
                    }
                } else {
                    $resultsBox.AppendText("Aucune ACL trouvée pour le dossier $folderPath.`n")
                }
            } catch {
                $resultsBox.Clear()
                $resultsBox.AppendText("Erreur lors de la récupération des ACL : $_`n")
                $resultsBox.AppendText("Vérifiez les permissions ou le chemin spécifié.`n")
            }
        } else {
            $resultsBox.Clear()
            $resultsBox.AppendText("Le dossier $folderPath n'existe pas ou n'est pas accessible.`n")
        }
    }
})
$form.Controls.Add($button16)

# Bouton 17 : Lister les serveurs avec le système d'exploitation installé (version améliorée)
$button17 = New-Object System.Windows.Forms.Button
$button17.Location = New-Object System.Drawing.Point(1000, 260)  # Position juste en dessous du bouton 16 (210 + 40 + 10)
$button17.Text = "17. Lister les serveurs avec OS"
$button17.Font = $buttonStyle.Font
$button17.ForeColor = $buttonStyle.ForeColor
$button17.BackColor = $buttonStyle.BackColor
$button17.FlatStyle = $buttonStyle.FlatStyle
$button17.Size = $buttonStyle.Size  # Même taille que les autres boutons (300x40)
$button17.Add_Click({
    # Vider la RichTextBox
    $resultsBox.Clear()

    # Demander à l'utilisateur s'il souhaite importer un fichier
    $importFile = [System.Windows.Forms.MessageBox]::Show(
        "Voulez-vous importer un fichier texte ou CSV contenant la liste des serveurs ?", 
        "Importer un fichier", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo, 
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($importFile -eq "Yes") {
        # Ouvrir une boîte de dialogue pour sélectionner un fichier
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "Fichiers texte (*.txt)|*.txt|Fichiers CSV (*.csv)|*.csv"
        $fileDialog.Title = "Sélectionnez un fichier contenant la liste des serveurs"
        if ($fileDialog.ShowDialog() -eq "OK") {
            $filePath = $fileDialog.FileName
            try {
                # Lire le fichier et récupérer la liste des serveurs
                if ($filePath.EndsWith(".csv")) {
                    $servers = Import-Csv -Path $filePath | ForEach-Object { $_.ServerName }  # Supposons que la colonne s'appelle "ServerName"
                } else {
                    $servers = Get-Content -Path $filePath
                }

                if ($servers) {
                    # Afficher les en-têtes de colonnes
                    $resultsBox.AppendText("Serveur; Système d'exploitation`n")

                    # Afficher la liste des serveurs avec leur système d'exploitation
                    foreach ($server in $servers) {
                        try {
                            $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $server -ErrorAction Stop | Select-Object -ExpandProperty Caption
                            $resultsBox.AppendText("$server; $os`n")
                        } catch {
                            $resultsBox.AppendText("$server; Erreur: Serveur inaccessible ou OS non disponible`n")
                        }
                    }
                } else {
                    $resultsBox.AppendText("Aucun serveur trouvé dans le fichier.`n")
                }
            } catch {
                $resultsBox.AppendText("Erreur lors de la lecture du fichier : $_`n")
            }
        }
    } else {
        # Ajouter un champ de recherche manuelle
        $searchBox = New-Object System.Windows.Forms.TextBox
        $searchBox.Location = New-Object System.Drawing.Point(1000, 310)  # Position en dessous du bouton 17
        $searchBox.Size = New-Object System.Drawing.Size(300, 20)  # Taille du champ de recherche
        $searchBox.Font = New-Object System.Drawing.Font("Arial", 10)
        $searchBox.ForeColor = [System.Drawing.Color]::Black
        $searchBox.BackColor = [System.Drawing.Color]::White
        $searchBox.PlaceholderText = "Entrez le nom du serveur..."
        $form.Controls.Add($searchBox)

        # Ajouter un bouton pour lancer la recherche
        $searchButton = New-Object System.Windows.Forms.Button
        $searchButton.Location = New-Object System.Drawing.Point(1310, 310)  # À côté du champ de recherche
        $searchButton.Size = New-Object System.Drawing.Size(100, 20)  # Taille du bouton
        $searchButton.Text = "Rechercher"
        $searchButton.Font = New-Object System.Drawing.Font("Arial", 10)
        $searchButton.ForeColor = [System.Drawing.Color]::White
        $searchButton.BackColor = [System.Drawing.Color]::Blue
        $searchButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $searchButton.Add_Click({
            $serverName = $searchBox.Text.Trim()
            if ($serverName) {
                # Afficher les en-têtes de colonnes
                $resultsBox.AppendText("Serveur; Système d'exploitation`n")
                $resultsBox.AppendText("-------------------------------`n")

                try {
                    $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $serverName -ErrorAction Stop | Select-Object -ExpandProperty Caption
                    $resultsBox.AppendText("$serverName; $os`n")
                } catch {
                    $resultsBox.AppendText("$serverName; Erreur: Serveur inaccessible ou OS non disponible`n")
                }
            } else {
                $resultsBox.AppendText("Veuillez entrer un nom de serveur.`n")
            }
        })
        $form.Controls.Add($searchButton)
    }
})
$form.Controls.Add($button17)

# Afficher le formulaire
$form.ShowDialog()