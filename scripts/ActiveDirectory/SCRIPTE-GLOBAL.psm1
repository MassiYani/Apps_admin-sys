Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Scripts\NAS\Acces-User-GRP_NAS-GROK.psm1
Function Get-Form {
    Add-Type -AssemblyName System.Windows.Forms
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Size = New-Object System.Drawing.Size(780, 580)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Gestion des accès NAS"
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10, 10)
    $panel.Controls.Add($label)
    $button = New-Object System.Windows.Forms.Button
    $button.Text = "Vérifier Accès"
    $button.Size = New-Object System.Drawing.Size(120, 25)
    $button.Location = New-Object System.Drawing.Point(10, 40)
    $button.Add_Click({
        # Insère ici la logique de gestion des accès
        [System.Windows.Forms.MessageBox]::Show("Vérification des accès NAS !")
    })
    $panel.Controls.Add($button)
    return $panel
}


# Fonction pour créer une fenêtre principale avec des boutons
function Show-MainWindow {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Scripts PowerShell"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"

    # Ajouter un grand titre avec encadrement
    $labelTitle = New-Object System.Windows.Forms.Label
    $labelTitle.Text = "Interface de Gestion des Scripts PowerShell"
    $labelTitle.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $labelTitle.AutoSize = $true
    $labelTitle.Location = New-Object System.Drawing.Point(50, 20)
    $form.Controls.Add($labelTitle)

    # Encadrement du titre
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Location = New-Object System.Drawing.Point(40, 10)
    $groupBox.Size = New-Object System.Drawing.Size(700, 50)
    $groupBox.Text = ""
    $form.Controls.Add($groupBox)

    # Bouton pour le script 1
    $buttonScript1 = New-Object System.Windows.Forms.Button
    $buttonScript1.Text = "When Password Expired"
    $buttonScript1.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $buttonScript1.AutoSize = $true
    $buttonScript1.Location = New-Object System.Drawing.Point(50, 80)
    $buttonScript1.Add_Click({ Show-Script1Window })
    $form.Controls.Add($buttonScript1)

    # Bouton pour le script 2
    $buttonScript2 = New-Object System.Windows.Forms.Button
    $buttonScript2.Text = "Cloner les groupes d'user pour un autre"
    $buttonScript2.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $buttonScript2.AutoSize = $true
    $buttonScript2.Location = New-Object System.Drawing.Point(50, 130)
    $buttonScript2.Add_Click({ Show-Script2Window })
    $form.Controls.Add($buttonScript2)

    # Bouton pour le script 3
    $buttonScript3 = New-Object System.Windows.Forms.Button
    $buttonScript3.Text = "Copier les membres d'un groupe vers un autre groupe"
    $buttonScript3.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $buttonScript3.AutoSize = $true
    $buttonScript3.Location = New-Object System.Drawing.Point(50, 180)
    $buttonScript3.Add_Click({ Show-Script3Window })
    $form.Controls.Add($buttonScript3)

    # Bouton pour le script 4
    $buttonScript4 = New-Object System.Windows.Forms.Button
    $buttonScript4.Text = "Les comptes créés pour une période donnée"
    $buttonScript4.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $buttonScript4.AutoSize = $true
    $buttonScript4.Location = New-Object System.Drawing.Point(50, 230)
    $buttonScript4.Add_Click({ Show-Script4Window })
    $form.Controls.Add($buttonScript4)

    # Bouton pour le script 5
    $buttonScript5 = New-Object System.Windows.Forms.Button
    $buttonScript5.Text = "Comptes avec msDS-cloudExtensionAttribute20 = office365"
    $buttonScript5.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $buttonScript5.AutoSize = $true
    $buttonScript5.Location = New-Object System.Drawing.Point(50, 280)
    $buttonScript5.Add_Click({ Show-Script5Window })
    $form.Controls.Add($buttonScript5)

    # Bouton pour le script 6
    $buttonScript6 = New-Object System.Windows.Forms.Button
    $buttonScript6.Text = "Comptes inactifs depuis une période donnée"
    $buttonScript6.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $buttonScript6.AutoSize = $true
    $buttonScript6.Location = New-Object System.Drawing.Point(50, 330)
    $buttonScript6.Add_Click({ Show-Script6Window })
    $form.Controls.Add($buttonScript6)

    # Bouton pour le script 7
$buttonScript7 = New-Object System.Windows.Forms.Button
$buttonScript7.Text = "Rechercher les membres d'un groupe"
$buttonScript7.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$buttonScript7.AutoSize = $true
$buttonScript7.Location = New-Object System.Drawing.Point(50, 380)  # Ajustez la position selon vos besoins
$buttonScript7.Add_Click({ Show-Script7Window })
$form.Controls.Add($buttonScript7)

# Bouton pour le script 8
$buttonScript8 = New-Object System.Windows.Forms.Button
$buttonScript8.Text = "Informations de l'ordinateur"
$buttonScript8.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$buttonScript8.AutoSize = $true
$buttonScript8.Location = New-Object System.Drawing.Point(50, 430)  # Ajustez la position selon vos besoins
$buttonScript8.Add_Click({ Show-Script8Window })
$form.Controls.Add($buttonScript8)

    # Afficher la fenêtre principale
    $form.ShowDialog()
}

# Fonction pour afficher la fenêtre du script 1
function Show-Script1Window {
    $script1Form = New-Object System.Windows.Forms.Form
    $script1Form.Text = "When Password Expired"
    $script1Form.Size = New-Object System.Drawing.Size(800, 600)
    $script1Form.StartPosition = "CenterScreen"

    $labelUser = New-Object System.Windows.Forms.Label
    $labelUser.Text = "Utilisateur:"
    $labelUser.Location = New-Object System.Drawing.Point(20, 20)
    $labelUser.Size = New-Object System.Drawing.Size(100, 20)
    $script1Form.Controls.Add($labelUser)

    $textBoxUser = New-Object System.Windows.Forms.TextBox
    $textBoxUser.Location = New-Object System.Drawing.Point(120, 20)
    $textBoxUser.Size = New-Object System.Drawing.Size(200, 20)
    $script1Form.Controls.Add($textBoxUser)

    $buttonCheck = New-Object System.Windows.Forms.Button
    $buttonCheck.Text = "Afficher la date d'expiration et la dernière réinitialisation"
    $buttonCheck.Location = New-Object System.Drawing.Point(20, 60)  # Reculé vers la gauche
    $buttonCheck.Size = New-Object System.Drawing.Size(300, 30)
    $buttonCheck.Add_Click({
        $user = $textBoxUser.Text
        $userInfo = Get-ADUser -Identity $user -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed", "pwdLastSet"
        if ($userInfo) {
            $expiryDate = [datetime]::FromFileTime($userInfo."msDS-UserPasswordExpiryTimeComputed")
            $lastResetDate = [datetime]::FromFileTime($userInfo."pwdLastSet")
            $richTextBoxResults.Text = @"
Utilisateur: $($userInfo.DisplayName)
Date d'expiration du mot de passe: $expiryDate
Date de la dernière réinitialisation du mot de passe: $lastResetDate
"@
        } else {
            $richTextBoxResults.Text = "Utilisateur non trouvé."
        }
    })
    $script1Form.Controls.Add($buttonCheck)

    # Zone de texte pour afficher les résultats
    $richTextBoxResults = New-Object System.Windows.Forms.RichTextBox
    $richTextBoxResults.Location = New-Object System.Drawing.Point(400, 20)
    $richTextBoxResults.Size = New-Object System.Drawing.Size(350, 500)
    $richTextBoxResults.ReadOnly = $true
    $script1Form.Controls.Add($richTextBoxResults)

    $script1Form.ShowDialog()
}

# Fonction pour afficher la fenêtre du script 2
function Show-Script2Window {
    $script2Form = New-Object System.Windows.Forms.Form
    $script2Form.Text = "Cloner les groupes d'user pour un autre"
    $script2Form.Size = New-Object System.Drawing.Size(800, 600)
    $script2Form.StartPosition = "CenterScreen"

    $labelUserPrincipal = New-Object System.Windows.Forms.Label
    $labelUserPrincipal.Text = "Utilisateur Principal:"
    $labelUserPrincipal.Location = New-Object System.Drawing.Point(20, 20)
    $labelUserPrincipal.Size = New-Object System.Drawing.Size(150, 20)
    $script2Form.Controls.Add($labelUserPrincipal)

    $textBoxUserPrincipal = New-Object System.Windows.Forms.TextBox
    $textBoxUserPrincipal.Location = New-Object System.Drawing.Point(180, 20)
    $textBoxUserPrincipal.Size = New-Object System.Drawing.Size(150, 20)
    $script2Form.Controls.Add($textBoxUserPrincipal)

    $labelUserToAdd = New-Object System.Windows.Forms.Label
    $labelUserToAdd.Text = "Utilisateur à Ajouter:"
    $labelUserToAdd.Location = New-Object System.Drawing.Point(20, 60)
    $labelUserToAdd.Size = New-Object System.Drawing.Size(150, 20)
    $script2Form.Controls.Add($labelUserToAdd)

    $textBoxUserToAdd = New-Object System.Windows.Forms.TextBox
    $textBoxUserToAdd.Location = New-Object System.Drawing.Point(180, 60)
    $textBoxUserToAdd.Size = New-Object System.Drawing.Size(150, 20)
    $script2Form.Controls.Add($textBoxUserToAdd)

    $buttonClone = New-Object System.Windows.Forms.Button
    $buttonClone.Text = "Cloner les groupes"
    $buttonClone.Location = New-Object System.Drawing.Point(120, 100)
    $buttonClone.Size = New-Object System.Drawing.Size(150, 30)
    $buttonClone.Add_Click({
        $utilisateurPrincipal = $textBoxUserPrincipal.Text
        $utilisateurAAjouter = $textBoxUserToAdd.Text
        $utilisateur = Get-ADUser -Identity $utilisateurPrincipal -Properties memberof
        if ($utilisateur) {
            $groupes = $utilisateur.memberof
            $richTextBoxResults.Clear()
            foreach ($groupe in $groupes) {
                Add-ADGroupMember -Identity $groupe -Members $utilisateurAAjouter
                $richTextBoxResults.AppendText("L'utilisateur $utilisateurAAjouter a été ajouté au groupe $groupe.`n")
            }
        } else {
            $richTextBoxResults.Text = "L'utilisateur principal $utilisateurPrincipal n'a pas été trouvé dans Active Directory."
        }
    })
    $script2Form.Controls.Add($buttonClone)

    # Zone de texte pour afficher les résultats
    $richTextBoxResults = New-Object System.Windows.Forms.RichTextBox
    $richTextBoxResults.Location = New-Object System.Drawing.Point(400, 20)
    $richTextBoxResults.Size = New-Object System.Drawing.Size(350, 500)
    $richTextBoxResults.ReadOnly = $true
    $script2Form.Controls.Add($richTextBoxResults)

    $script2Form.ShowDialog()
}

# Fonction pour afficher la fenêtre du script 3
function Show-Script3Window {
    $script3Form = New-Object System.Windows.Forms.Form
    $script3Form.Text = "Copier les membres d'un groupe vers un autre groupe"
    $script3Form.Size = New-Object System.Drawing.Size(800, 600)
    $script3Form.StartPosition = "CenterScreen"

    $labelSourceGroup = New-Object System.Windows.Forms.Label
    $labelSourceGroup.Text = "Groupe Source:"
    $labelSourceGroup.Location = New-Object System.Drawing.Point(20, 20)
    $labelSourceGroup.Size = New-Object System.Drawing.Size(150, 20)
    $script3Form.Controls.Add($labelSourceGroup)

    $textBoxSourceGroup = New-Object System.Windows.Forms.TextBox
    $textBoxSourceGroup.Location = New-Object System.Drawing.Point(180, 20)
    $textBoxSourceGroup.Size = New-Object System.Drawing.Size(150, 20)
    $script3Form.Controls.Add($textBoxSourceGroup)

    $labelTargetGroup = New-Object System.Windows.Forms.Label
    $labelTargetGroup.Text = "Groupe Cible:"
    $labelTargetGroup.Location = New-Object System.Drawing.Point(20, 60)
    $labelTargetGroup.Size = New-Object System.Drawing.Size(150, 20)
    $script3Form.Controls.Add($labelTargetGroup)

    $textBoxTargetGroup = New-Object System.Windows.Forms.TextBox
    $textBoxTargetGroup.Location = New-Object System.Drawing.Point(180, 60)
    $textBoxTargetGroup.Size = New-Object System.Drawing.Size(150, 20)
    $script3Form.Controls.Add($textBoxTargetGroup)

    $buttonCopy = New-Object System.Windows.Forms.Button
    $buttonCopy.Text = "Copier les membres"
    $buttonCopy.Location = New-Object System.Drawing.Point(120, 100)
    $buttonCopy.Size = New-Object System.Drawing.Size(150, 30)
    $buttonCopy.Add_Click({
        $sourceGroup = $textBoxSourceGroup.Text
        $targetGroup = $textBoxTargetGroup.Text

        # Récupérer les membres du groupe source
        $members = Get-ADGroupMember -Identity $sourceGroup -Recursive

        # Ajouter les membres au groupe cible en utilisant leur SamAccountName
        if ($members) {
            $richTextBoxResults.Clear()
            $richTextBoxResults.AppendText("$($members.Count) membres copiés du groupe $sourceGroup vers le groupe $targetGroup.`n")
            foreach ($member in $members) {
                try {
                    # Utiliser le SamAccountName pour ajouter le membre au groupe cible
                    Add-ADGroupMember -Identity $targetGroup -Members $member.SamAccountName
                    $richTextBoxResults.AppendText("$($member.SamAccountName) ajouté avec succès.`n")
                } catch {
                    $richTextBoxResults.AppendText("Erreur lors de l'ajout de $($member.SamAccountName): $_`n")
                }
            }
        } else {
            $richTextBoxResults.Text = "Aucun membre trouvé dans le groupe source."
        }
    })
    $script3Form.Controls.Add($buttonCopy)

    # Zone de texte pour afficher les résultats
    $richTextBoxResults = New-Object System.Windows.Forms.RichTextBox
    $richTextBoxResults.Location = New-Object System.Drawing.Point(400, 20)
    $richTextBoxResults.Size = New-Object System.Drawing.Size(350, 500)
    $richTextBoxResults.ReadOnly = $true
    $script3Form.Controls.Add($richTextBoxResults)

    $script3Form.ShowDialog()
}
# Fonction pour afficher la fenêtre du script 4
function Show-Script4Window {
    $script4Form = New-Object System.Windows.Forms.Form
    $script4Form.Text = "Les comptes créés pour une période donnée"
    $script4Form.Size = New-Object System.Drawing.Size(800, 600)
    $script4Form.StartPosition = "CenterScreen"

    $labelStartDate = New-Object System.Windows.Forms.Label
    $labelStartDate.Text = "Date de début:"
    $labelStartDate.Location = New-Object System.Drawing.Point(20, 20)
    $labelStartDate.Size = New-Object System.Drawing.Size(150, 20)
    $script4Form.Controls.Add($labelStartDate)

    $dateTimePickerStart = New-Object System.Windows.Forms.DateTimePicker
    $dateTimePickerStart.Location = New-Object System.Drawing.Point(180, 20)
    $dateTimePickerStart.Size = New-Object System.Drawing.Size(150, 20)
    $script4Form.Controls.Add($dateTimePickerStart)

    $labelEndDate = New-Object System.Windows.Forms.Label
    $labelEndDate.Text = "Date de fin:"
    $labelEndDate.Location = New-Object System.Drawing.Point(20, 60)
    $labelEndDate.Size = New-Object System.Drawing.Size(150, 20)
    $script4Form.Controls.Add($labelEndDate)

    $dateTimePickerEnd = New-Object System.Windows.Forms.DateTimePicker
    $dateTimePickerEnd.Location = New-Object System.Drawing.Point(180, 60)
    $dateTimePickerEnd.Size = New-Object System.Drawing.Size(150, 20)
    $script4Form.Controls.Add($dateTimePickerEnd)

    # Cases à cocher pour les OUs
    $checkBoxOU1 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU1.Text = "OU=Bejaia,DC=Cevital,DC=com"
    $checkBoxOU1.Location = New-Object System.Drawing.Point(20, 100)
    $checkBoxOU1.AutoSize = $true
    $script4Form.Controls.Add($checkBoxOU1)

    $checkBoxOU2 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU2.Text = "OU=Cojek,DC=Cevital,DC=com"
    $checkBoxOU2.Location = New-Object System.Drawing.Point(20, 130)
    $checkBoxOU2.AutoSize = $true
    $script4Form.Controls.Add($checkBoxOU2)

    $checkBoxOU3 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU3.Text = "OU=Lalla Khedidja,DC=Cevital,DC=com"
    $checkBoxOU3.Location = New-Object System.Drawing.Point(20, 160)
    $checkBoxOU3.AutoSize = $true
    $script4Form.Controls.Add($checkBoxOU3)

    $buttonList = New-Object System.Windows.Forms.Button
    $buttonList.Text = "Lister les comptes"
    $buttonList.Location = New-Object System.Drawing.Point(20, 200)
    $buttonList.Size = New-Object System.Drawing.Size(150, 30)
    $buttonList.Add_Click({
        # Récupérer les dates sélectionnées
        $startDate = $dateTimePickerStart.Value
        $endDate = $dateTimePickerEnd.Value

        # Convertir les dates en format compatible avec le filtre LDAP
        $startDateString = $startDate.ToString('yyyy-MM-dd')
        $endDateString = $endDate.ToString('yyyy-MM-dd')

        # Récupérer les OUs sélectionnées
        $selectedOU = @()
        if ($checkBoxOU1.Checked) { $selectedOU += $checkBoxOU1.Text }
        if ($checkBoxOU2.Checked) { $selectedOU += $checkBoxOU2.Text }
        if ($checkBoxOU3.Checked) { $selectedOU += $checkBoxOU3.Text }

        if ($selectedOU.Count -eq 0) {
            $richTextBoxResults.Text = "Veuillez sélectionner au moins une OU."
            return
        }

        # Construire le filtre LDAP manuellement
        $filter = "Created -ge '$startDateString' -and Created -le '$endDateString'"

        # Exécuter la commande Get-ADUser avec le filtre et les OUs sélectionnées
        $results = @()
        foreach ($ou in $selectedOU) {
            $users = Get-ADUser -Filter $filter -Properties Created -SearchBase $ou
            if ($users) {
                $results += "OU: $ou"
                foreach ($user in $users) {
                    $results += "$($user.SamAccountName) - $($user.Created)"
                }
                $results += "-----------------------------"
            }
        }

        # Afficher les résultats
        $richTextBoxResults.Clear()
        if ($results.Count -gt 0) {
            $richTextBoxResults.Text = $results -join "`n"
        } else {
            $richTextBoxResults.Text = "Aucun compte trouvé pour la période spécifiée dans les OUs sélectionnées."
        }
    })
    $script4Form.Controls.Add($buttonList)

    # Zone de texte pour afficher les résultats
    $richTextBoxResults = New-Object System.Windows.Forms.RichTextBox
    $richTextBoxResults.Location = New-Object System.Drawing.Point(400, 20)
    $richTextBoxResults.Size = New-Object System.Drawing.Size(350, 500)
    $richTextBoxResults.ReadOnly = $true
    $script4Form.Controls.Add($richTextBoxResults)

    $script4Form.ShowDialog()
}

# Fonction pour afficher la fenêtre du script 5
function Show-Script5Window {
    $script5Form = New-Object System.Windows.Forms.Form
    $script5Form.Text = "Comptes avec msDS-cloudExtensionAttribute20 = office365"
    $script5Form.Size = New-Object System.Drawing.Size(800, 600)
    $script5Form.StartPosition = "CenterScreen"

    # Cases à cocher pour les OUs
    $checkBoxOU1 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU1.Text = "OU=Bejaia,DC=Cevital,DC=com"
    $checkBoxOU1.Location = New-Object System.Drawing.Point(20, 20)
    $checkBoxOU1.AutoSize = $true
    $script5Form.Controls.Add($checkBoxOU1)

    $checkBoxOU2 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU2.Text = "OU=Cojek,DC=Cevital,DC=com"
    $checkBoxOU2.Location = New-Object System.Drawing.Point(20, 50)
    $checkBoxOU2.AutoSize = $true
    $script5Form.Controls.Add($checkBoxOU2)

    $checkBoxOU3 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU3.Text = "OU=Lalla Khedidja,DC=Cevital,DC=com"
    $checkBoxOU3.Location = New-Object System.Drawing.Point(20, 80)
    $checkBoxOU3.AutoSize = $true
    $script5Form.Controls.Add($checkBoxOU3)

    $buttonSearch = New-Object System.Windows.Forms.Button
    $buttonSearch.Text = "Rechercher"
    $buttonSearch.Location = New-Object System.Drawing.Point(20, 120)
    $buttonSearch.Size = New-Object System.Drawing.Size(150, 30)
    $buttonSearch.Add_Click({
        # Récupérer les OUs sélectionnées
        $selectedOU = @()
        if ($checkBoxOU1.Checked) { $selectedOU += $checkBoxOU1.Text }
        if ($checkBoxOU2.Checked) { $selectedOU += $checkBoxOU2.Text }
        if ($checkBoxOU3.Checked) { $selectedOU += $checkBoxOU3.Text }

        if ($selectedOU.Count -eq 0) {
            $richTextBoxResults.Text = "Veuillez sélectionner au moins une OU."
            return
        }

        # Construire le filtre LDAP pour msDS-cloudExtensionAttribute20 = "office365"
        $filter = 'msDS-cloudExtensionAttribute20 -eq "office365"'

        # Exécuter la commande Get-ADUser avec le filtre et les OUs sélectionnées
        $results = @()
        foreach ($ou in $selectedOU) {
            $users = Get-ADUser -Filter $filter -Properties msDS-cloudExtensionAttribute20, Enabled -SearchBase $ou
            if ($users) {
                # Filtrer les comptes désactivés et activés
                $disabledUsers = $users | Where-Object { $_.Enabled -eq $false }
                $enabledUsers = $users | Where-Object { $_.Enabled -eq $true }

                $results += "OU: $ou"
                $results += "Nombre de comptes désactivés: $($disabledUsers.Count)"
                $results += "Nombre de comptes activés: $($enabledUsers.Count)"
                $results += "-----------------------------"

                # Ajouter les comptes désactivés
                if ($disabledUsers.Count -gt 0) {
                    $results += "Comptes désactivés:"
                    foreach ($user in $disabledUsers) {
                        $results += "$($user.SamAccountName)"
                    }
                    $results += "-----------------------------"
                }

                # Ajouter les comptes activés
                if ($enabledUsers.Count -gt 0) {
                    $results += "Comptes activés:"
                    foreach ($user in $enabledUsers) {
                        $results += "$($user.SamAccountName)"
                    }
                    $results += "-----------------------------"
                }
            }
        }

        # Afficher les résultats
        $richTextBoxResults.Clear()
        if ($results.Count -gt 0) {
            $richTextBoxResults.Text = $results -join "`n"
        } else {
            $richTextBoxResults.Text = "Aucun compte trouvé avec msDS-cloudExtensionAttribute20 = office365 dans les OUs sélectionnées."
        }
    })
    $script5Form.Controls.Add($buttonSearch)

    # Zone de texte pour afficher les résultats
    $richTextBoxResults = New-Object System.Windows.Forms.RichTextBox
    $richTextBoxResults.Location = New-Object System.Drawing.Point(400, 20)
    $richTextBoxResults.Size = New-Object System.Drawing.Size(350, 500)
    $richTextBoxResults.ReadOnly = $true
    $script5Form.Controls.Add($richTextBoxResults)

    $script5Form.ShowDialog()
}

# Fonction pour afficher la fenêtre du script 6

function Show-Script6Window {
    $script6Form = New-Object System.Windows.Forms.Form
    $script6Form.Text = "Comptes inactifs depuis une période donnée"
    $script6Form.Size = New-Object System.Drawing.Size(800, 600)
    $script6Form.StartPosition = "CenterScreen"

    $labelInactiveDays = New-Object System.Windows.Forms.Label
    $labelInactiveDays.Text = "Nombre de jours d'inactivité:"
    $labelInactiveDays.Location = New-Object System.Drawing.Point(20, 20)
    $labelInactiveDays.Size = New-Object System.Drawing.Size(150, 20)
    $script6Form.Controls.Add($labelInactiveDays)

    $textBoxInactiveDays = New-Object System.Windows.Forms.TextBox
    $textBoxInactiveDays.Location = New-Object System.Drawing.Point(180, 20)
    $textBoxInactiveDays.Size = New-Object System.Drawing.Size(100, 20)
    $script6Form.Controls.Add($textBoxInactiveDays)

    # Cases à cocher pour les OUs
    $checkBoxOU1 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU1.Text = "OU=Bejaia,DC=Cevital,DC=com"
    $checkBoxOU1.Location = New-Object System.Drawing.Point(20, 60)
    $checkBoxOU1.AutoSize = $true
    $script6Form.Controls.Add($checkBoxOU1)

    $checkBoxOU2 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU2.Text = "OU=Cojek,DC=Cevital,DC=com"
    $checkBoxOU2.Location = New-Object System.Drawing.Point(20, 90)
    $checkBoxOU2.AutoSize = $true
    $script6Form.Controls.Add($checkBoxOU2)

    $checkBoxOU3 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU3.Text = "OU=Lalla Khedidja,DC=Cevital,DC=com"
    $checkBoxOU3.Location = New-Object System.Drawing.Point(20, 120)
    $checkBoxOU3.AutoSize = $true
    $script6Form.Controls.Add($checkBoxOU3)

    $buttonSearch = New-Object System.Windows.Forms.Button
    $buttonSearch.Text = "Rechercher"
    $buttonSearch.Location = New-Object System.Drawing.Point(20, 160)
    $buttonSearch.Size = New-Object System.Drawing.Size(150, 30)
    $buttonSearch.Add_Click({
        # Récupérer le nombre de jours d'inactivité
        $inactiveDays = $textBoxInactiveDays.Text
        if (-not $inactiveDays -or $inactiveDays -notmatch '^\d+$') {
            $richTextBoxResults.Text = "Veuillez entrer un nombre valide de jours d'inactivité."
            return
        }

        # Récupérer les OUs sélectionnées
        $selectedOU = @()
        if ($checkBoxOU1.Checked) { $selectedOU += $checkBoxOU1.Text }
        if ($checkBoxOU2.Checked) { $selectedOU += $checkBoxOU2.Text }
        if ($checkBoxOU3.Checked) { $selectedOU += $checkBoxOU3.Text }

        if ($selectedOU.Count -eq 0) {
            $richTextBoxResults.Text = "Veuillez sélectionner au moins une OU."
            return
        }

        # Construire le filtre LDAP pour les comptes inactifs
        $filter = "LastLogonTimestamp -le $((Get-Date).AddDays(-$inactiveDays).ToFileTime())"

        # Exécuter la commande Get-ADUser avec le filtre et les OUs sélectionnées
        $results = @()
        foreach ($ou in $selectedOU) {
            $users = Get-ADUser -Filter $filter -Properties LastLogonTimestamp, Enabled -SearchBase $ou
            if ($users) {
                # Filtrer manuellement les comptes activés
                $activeUsers = $users | Where-Object { $_.Enabled -eq $true }
                if ($activeUsers) {
                    $results += "OU: $ou"
                    $results += "Nombre de comptes activés mais inactifs: $($activeUsers.Count)"
                    foreach ($user in $activeUsers) {
                        $results += "$($user.SamAccountName) - Dernière connexion: $([datetime]::FromFileTime($user.LastLogonTimestamp))"
                    }
                    $results += "-----------------------------"
                }
            }
        }

        # Afficher les résultats
        $richTextBoxResults.Clear()
        if ($results.Count -gt 0) {
            $richTextBoxResults.Text = $results -join "`n"
        } else {
            $richTextBoxResults.Text = "Aucun compte activé mais inactif trouvé dans les OUs sélectionnées."
        }
    })
    $script6Form.Controls.Add($buttonSearch)

    # Zone de texte pour afficher les résultats
    $richTextBoxResults = New-Object System.Windows.Forms.RichTextBox
    $richTextBoxResults.Location = New-Object System.Drawing.Point(400, 20)
    $richTextBoxResults.Size = New-Object System.Drawing.Size(350, 500)
    $richTextBoxResults.ReadOnly = $true
    $script6Form.Controls.Add($richTextBoxResults)

    $script6Form.ShowDialog()
}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Fonction pour afficher la fenêtre du script 7
function Show-Script7Window {
    $script7Form = New-Object System.Windows.Forms.Form
    $script7Form.Text = "Rechercher les membres d'un groupe donné"
    $script7Form.Size = New-Object System.Drawing.Size(1000, 600)  # Taille augmentée pour le tableau
    $script7Form.StartPosition = "CenterScreen"

    # Champ pour saisir le nom du groupe
    $labelGroup = New-Object System.Windows.Forms.Label
    $labelGroup.Text = "Groupe:"
    $labelGroup.Location = New-Object System.Drawing.Point(20, 20)
    $labelGroup.Size = New-Object System.Drawing.Size(150, 20)
    $script7Form.Controls.Add($labelGroup)

    $textBoxGroup = New-Object System.Windows.Forms.TextBox
    $textBoxGroup.Location = New-Object System.Drawing.Point(180, 20)
    $textBoxGroup.Size = New-Object System.Drawing.Size(200, 20)
    $script7Form.Controls.Add($textBoxGroup)

    # Cases à cocher pour les OUs
    $checkBoxOU1 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU1.Text = "OU=Bejaia,DC=Cevital,DC=com"
    $checkBoxOU1.Location = New-Object System.Drawing.Point(20, 60)
    $checkBoxOU1.AutoSize = $true
    $script7Form.Controls.Add($checkBoxOU1)

    $checkBoxOU2 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU2.Text = "OU=Cojek,DC=Cevital,DC=com"
    $checkBoxOU2.Location = New-Object System.Drawing.Point(20, 90)
    $checkBoxOU2.AutoSize = $true
    $script7Form.Controls.Add($checkBoxOU2)

    $checkBoxOU3 = New-Object System.Windows.Forms.CheckBox
    $checkBoxOU3.Text = "OU=Lalla Khedidja,DC=Cevital,DC=com"
    $checkBoxOU3.Location = New-Object System.Drawing.Point(20, 120)
    $checkBoxOU3.AutoSize = $true
    $script7Form.Controls.Add($checkBoxOU3)

    # Boutons radio pour le choix d'affichage
    $radioButtonCountOnly = New-Object System.Windows.Forms.RadioButton
    $radioButtonCountOnly.Text = "Afficher seulement le nombre de membres"
    $radioButtonCountOnly.Location = New-Object System.Drawing.Point(20, 160)
    $radioButtonCountOnly.AutoSize = $true
    $radioButtonCountOnly.Checked = $true  # Par défaut, afficher seulement le nombre
    $script7Form.Controls.Add($radioButtonCountOnly)

    $radioButtonCountAndMembers = New-Object System.Windows.Forms.RadioButton
    $radioButtonCountAndMembers.Text = "Afficher les membres et le nombre"
    $radioButtonCountAndMembers.Location = New-Object System.Drawing.Point(20, 190)
    $radioButtonCountAndMembers.AutoSize = $true
    $script7Form.Controls.Add($radioButtonCountAndMembers)

    # Bouton de recherche
    $buttonSearch = New-Object System.Windows.Forms.Button
    $buttonSearch.Text = "Rechercher les membres"
    $buttonSearch.Location = New-Object System.Drawing.Point(20, 230)
    $buttonSearch.Size = New-Object System.Drawing.Size(150, 30)
    $buttonSearch.Add_Click({
        $groupName = $textBoxGroup.Text

        # Récupérer les OUs sélectionnées
        $selectedOU = @()
        if ($checkBoxOU1.Checked) { $selectedOU += $checkBoxOU1.Text }
        if ($checkBoxOU2.Checked) { $selectedOU += $checkBoxOU2.Text }
        if ($checkBoxOU3.Checked) { $selectedOU += $checkBoxOU3.Text }

        if ($selectedOU.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Veuillez sélectionner au moins une OU.", "Erreur")
            return
        }

        # Déterminer le choix d'affichage
        $showMembers = $radioButtonCountAndMembers.Checked

        # Effacer le tableau avant de remplir les nouveaux résultats
        $dataGridViewResults.Rows.Clear()

        # Variable pour stocker le total des membres
        $totalMembers = 0

        # Rechercher les membres du groupe dans les OUs sélectionnées
        foreach ($ou in $selectedOU) {
            # Construire le filtre LDAP pour le groupe
            $filter = "Name -eq '$groupName'"

            # Rechercher le groupe dans l'OU spécifiée
            $group = Get-ADGroup -Filter $filter -SearchBase $ou
            if ($group) {
                # Utiliser le DistinguishedName du groupe pour Get-ADGroupMember
                $members = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive
                if ($members) {
                    # Ajouter une ligne pour l'OU avec le nombre de membres
                    $rowIndex = $dataGridViewResults.Rows.Add()
                    $ouName = ($ou -split ',')[0]
                    $dn = $ou
                    $dataGridViewResults.Rows[$rowIndex].Cells[0].Value = "$ouName`n$dn"
                    $dataGridViewResults.Rows[$rowIndex].Cells[0].Style.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
                    $dataGridViewResults.Rows[$rowIndex].Cells[0].Style.ForeColor = [System.Drawing.Color]::Blue
                    $dataGridViewResults.Rows[$rowIndex].Cells[1].Value = $members.Count
                    $dataGridViewResults.Rows[$rowIndex].Cells[1].Style.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)

                    # Ajouter les membres si demandé
                    if ($showMembers) {
                        foreach ($member in $members) {
                            $rowIndex = $dataGridViewResults.Rows.Add()
                            $dataGridViewResults.Rows[$rowIndex].Cells[0].Value = $member.SamAccountName
                        }
                    }

                    # Ajouter au total des membres
                    $totalMembers += $members.Count
                } else {
                    # Aucun membre trouvé
                    $rowIndex = $dataGridViewResults.Rows.Add()
                    $ouName = ($ou -split ',')[0]
                    $dn = $ou
                    $dataGridViewResults.Rows[$rowIndex].Cells[0].Value = "$ouName`n$dn"
                    $dataGridViewResults.Rows[$rowIndex].Cells[0].Style.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
                    $dataGridViewResults.Rows[$rowIndex].Cells[0].Style.ForeColor = [System.Drawing.Color]::Blue
                    $dataGridViewResults.Rows[$rowIndex].Cells[1].Value = "Aucun membre trouvé"
                }
            } else {
                # Groupe non trouvé
                $rowIndex = $dataGridViewResults.Rows.Add()
                $ouName = ($ou -split ',')[0]
                $dn = $ou
                $dataGridViewResults.Rows[$rowIndex].Cells[0].Value = "$ouName`n$dn"
                $dataGridViewResults.Rows[$rowIndex].Cells[0].Style.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
                $dataGridViewResults.Rows[$rowIndex].Cells[0].Style.ForeColor = [System.Drawing.Color]::Blue
                $dataGridViewResults.Rows[$rowIndex].Cells[1].Value = "Groupe non trouvé"
            }
        }

        # Ajouter le total des membres au début du tableau
        $rowIndex = $dataGridViewResults.Rows.Insert(0)
        $dataGridViewResults.Rows[$rowIndex].Cells[0].Value = "Total des membres du groupe"
        $dataGridViewResults.Rows[$rowIndex].Cells[0].Style.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $dataGridViewResults.Rows[$rowIndex].Cells[1].Value = $totalMembers
        $dataGridViewResults.Rows[$rowIndex].Cells[1].Style.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)

        # Fusionner les cellules juste en dessous du résultat du nombre dans la colonne "Nombre"
        $dataGridViewResults.Rows[1].Cells[1].Merge = $true
    })
    $script7Form.Controls.Add($buttonSearch)

    # Tableau pour afficher les résultats
    $dataGridViewResults = New-Object System.Windows.Forms.DataGridView
    $dataGridViewResults.Location = New-Object System.Drawing.Point(400, 20)
    $dataGridViewResults.Size = New-Object System.Drawing.Size(550, 500)
    $dataGridViewResults.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $dataGridViewResults.ColumnCount = 2
    $dataGridViewResults.Columns[0].Name = "Détails"
    $dataGridViewResults.Columns[1].Name = "Nombre"
    $dataGridViewResults.Columns[1].Width = 100  # Largeur fixe pour la colonne du nombre
    $dataGridViewResults.ReadOnly = $true
    $dataGridViewResults.AllowUserToAddRows = $false
    $script7Form.Controls.Add($dataGridViewResults)

    # Bouton pour quitter
    $buttonQuit = New-Object System.Windows.Forms.Button
    $buttonQuit.Text = "Quitter"
    $buttonQuit.Location = New-Object System.Drawing.Point(20, 270)
    $buttonQuit.Size = New-Object System.Drawing.Size(100, 30)
    $buttonQuit.Add_Click({
        $script7Form.Close()
    })
    $script7Form.Controls.Add($buttonQuit)

    # Afficher le formulaire
    $script7Form.ShowDialog()
}

# Exemple d'appel de la fonction
$buttonScript7 = New-Object System.Windows.Forms.Button
$buttonScript7.Add_Click({ Show-Script7Window })


# Fonction pour afficher la fenêtre du Scripte 8

# Importer les modules nécessaires
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Fonction pour afficher la fenêtre du Scripte 8
function Show-Script8Window {
    # Créer le formulaire
    $script8Form = New-Object System.Windows.Forms.Form
    $script8Form.Text = "Informations de l'ordinateur"
    $script8Form.Size = New-Object System.Drawing.Size(800, 600)  # Taille augmentée pour le RichTextBox
    $script8Form.StartPosition = "CenterScreen"

    # Champ pour saisir le nom de domaine ou le nom de l'ordinateur
    $labelDomain = New-Object System.Windows.Forms.Label
    $labelDomain.Text = "Nom de domaine ou nom de l'ordinateur :"
    $labelDomain.Location = New-Object System.Drawing.Point(20, 20)
    $labelDomain.Size = New-Object System.Drawing.Size(250, 20)
    $script8Form.Controls.Add($labelDomain)

    $textBoxDomain = New-Object System.Windows.Forms.TextBox
    $textBoxDomain.Location = New-Object System.Drawing.Point(280, 20)
    $textBoxDomain.Size = New-Object System.Drawing.Size(200, 20)
    $script8Form.Controls.Add($textBoxDomain)

    # Créer une RichTextBox pour afficher les informations
    $richTextBoxInfo = New-Object System.Windows.Forms.RichTextBox
    $richTextBoxInfo.Location = New-Object System.Drawing.Point(20, 60)
    $richTextBoxInfo.Size = New-Object System.Drawing.Size(740, 450)
    $richTextBoxInfo.Font = New-Object System.Drawing.Font("Arial", 10)
    $richTextBoxInfo.ReadOnly = $true  # Empêche la modification du texte
    $richTextBoxInfo.Multiline = $true  # Permet plusieurs lignes
    $richTextBoxInfo.ScrollBars = "Vertical"  # Ajoute une barre de défilement
    $script8Form.Controls.Add($richTextBoxInfo)

    # Bouton pour récupérer les informations
    $buttonGetInfo = New-Object System.Windows.Forms.Button
    $buttonGetInfo.Text = "Récupérer les informations"
    $buttonGetInfo.Location = New-Object System.Drawing.Point(20, 530)
    $buttonGetInfo.Size = New-Object System.Drawing.Size(200, 30)
    $buttonGetInfo.Add_Click({
        $domainOrComputerName = $textBoxDomain.Text
        if (-not [string]::IsNullOrEmpty($domainOrComputerName)) {
            try {
                $info = Get-ComputerInfo -ComputerName $domainOrComputerName
                $richTextBoxInfo.Text = $info
            } catch {
                $richTextBoxInfo.Text = "Erreur : Impossible de récupérer les informations pour '$domainOrComputerName'. Vérifiez le nom et les permissions."
            }
        } else {
            $richTextBoxInfo.Text = "Veuillez saisir un nom de domaine ou un nom d'ordinateur."
        }
    })
    $script8Form.Controls.Add($buttonGetInfo)

    # Bouton pour copier les informations
    $buttonCopy = New-Object System.Windows.Forms.Button
    $buttonCopy.Text = "Copier les informations"
    $buttonCopy.Location = New-Object System.Drawing.Point(250, 530)
    $buttonCopy.Size = New-Object System.Drawing.Size(200, 30)
    $buttonCopy.Add_Click({
        # Copier le contenu de la RichTextBox dans le presse-papiers
        $richTextBoxInfo.SelectAll()
        $richTextBoxInfo.Copy()
        [System.Windows.Forms.MessageBox]::Show("Les informations ont été copiées dans le presse-papiers.", "Copié")
    })
    $script8Form.Controls.Add($buttonCopy)

    # Bouton pour quitter
    $buttonQuit = New-Object System.Windows.Forms.Button
    $buttonQuit.Text = "Quitter"
    $buttonQuit.Location = New-Object System.Drawing.Point(480, 530)
    $buttonQuit.Size = New-Object System.Drawing.Size(100, 30)
    $buttonQuit.Add_Click({
        $script8Form.Close()
    })
    $script8Form.Controls.Add($buttonQuit)

    # Afficher le formulaire
    $script8Form.ShowDialog()
}

# Fonction pour récupérer les informations de l'ordinateur
function Get-ComputerInfo {
    param (
        [string]$ComputerName = $env:COMPUTERNAME  # Par défaut, l'ordinateur local
    )

    try {
        # Récupérer le nom de l'ordinateur
        $computerName = $ComputerName

        # Récupérer le numéro de série et le modèle de l'ordinateur
        $systemInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName -ErrorAction Stop
        $model = $systemInfo.Model
        $serialNumber = (Get-WmiObject -Class Win32_BIOS -ComputerName $ComputerName -ErrorAction Stop).SerialNumber

        # Récupérer les informations du système d'exploitation
        $osInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
        $osDescription = $osInfo.Description  # Description du système d'exploitation
        $osCaption = $osInfo.Caption  # Nom du système d'exploitation (ex: "Microsoft Windows 10 Pro")
        $osVersion = $osInfo.Version  # Version du système d'exploitation (ex: "10.0.19041")
        $osArchitecture = $osInfo.OSArchitecture  # Architecture (ex: "64-bit")

        # Récupérer l'adresse IP v4 et l'adresse MAC
        $networkInfo = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName -ErrorAction Stop | Where-Object { $_.IPEnabled -eq $true }
        $ipv4Address = ($networkInfo.IPAddress | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' }) -join ", "
        $macAddress = $networkInfo.MACAddress

        # Récupérer la liste des mises à jour Windows Update installées
        $updates = Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $ComputerName -ErrorAction Stop | Sort-Object InstalledOn -Descending
        $updateList = @()
        foreach ($update in $updates) {
            $updateList += "ID : $($update.HotFixID), Description : $($update.Description), Installé le : $($update.InstalledOn)"
        }

        # Récupérer la session active (uniquement les utilisateurs humains)
        $loggedOnUsers = Get-WmiObject -Class Win32_LoggedOnUser -ComputerName $ComputerName -ErrorAction Stop
        $activeSessions = @()
        foreach ($user in $loggedOnUsers) {
            $username = $user.Antecedent.Split('=')[2].Replace('"', '')  # Extraire le nom d'utilisateur
            # Exclure les comptes système
            if ($username -notmatch "ANONYMOUS LOGON|DWM-\d+|SERVICE LOCAL|SERVICE RÉSEAU|Système|UMFD-\d+") {
                $activeSessions += $username
            }
        }
        $activeSessions = $activeSessions | Sort-Object -Unique  # Supprimer les doublons

        # Formater les informations
        $info = @"
Nom de l'ordinateur : $computerName
Numéro de série : $serialNumber
Modèle de l'ordinateur : $model
Description de l'ordinateur : $osDescription
Système d'exploitation : $osCaption
Version du système : $osVersion
Architecture : $osArchitecture
Adresse IP v4 : $ipv4Address
Adresse MAC : $macAddress

Mises à jour Windows Update installées :
$($updateList -join "`n")

Sessions actives :
$($activeSessions -join "`n")
"@

        return $info
    } catch {
        throw "Erreur lors de la récupération des informations pour '$ComputerName'. Assurez-vous que l'ordinateur est accessible et que vous avez les permissions nécessaires."
    }
}


# Afficher la fenêtre principale
Show-MainWindow