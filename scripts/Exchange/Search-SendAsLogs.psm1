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


# Scripts\Exchange\Search-SendAsLogs.psm1
Function Get-Form {
    Add-Type -AssemblyName System.Windows.Forms
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Size = New-Object System.Drawing.Size(780, 580)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Recherche des logs SendAs"
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10, 10)
    $panel.Controls.Add($label)
    $button = New-Object System.Windows.Forms.Button
    $button.Text = "Lancer Recherche"
    $button.Size = New-Object System.Drawing.Size(120, 25)
    $button.Location = New-Object System.Drawing.Point(10, 40)
    $button.Add_Click({
        # Insère ici la logique de recherche des logs
        [System.Windows.Forms.MessageBox]::Show("Recherche des logs SendAs lancée !")
    })
    $panel.Controls.Add($button)
    return $panel
}

# Créer le formulaire principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Gestion des Logs d'Audit et des Délégations"
$form.Size = New-Object System.Drawing.Size(1200, 800)  # Taille augmentée pour plus d'espace
$form.StartPosition = "CenterScreen"

# Créer un panneau pour la configuration
$panelConfig = New-Object System.Windows.Forms.Panel
$panelConfig.Location = New-Object System.Drawing.Point(10, 10)
$panelConfig.Size = New-Object System.Drawing.Size(300, 150)
$panelConfig.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($panelConfig)

# Champ de saisie pour l'adresse de la boîte aux lettres partagée
$labelMailbox = New-Object System.Windows.Forms.Label
$labelMailbox.Text = "Adresse de la boîte aux lettres partagée :"
$labelMailbox.Location = New-Object System.Drawing.Point(10, 20)
$labelMailbox.AutoSize = $true
$panelConfig.Controls.Add($labelMailbox)

$textBoxMailbox = New-Object System.Windows.Forms.TextBox
$textBoxMailbox.Location = New-Object System.Drawing.Point(10, 50)
$textBoxMailbox.Size = New-Object System.Drawing.Size(280, 20)
$panelConfig.Controls.Add($textBoxMailbox)

# Bouton pour vérifier la configuration de la journalisation
$buttonCheckConfig = New-Object System.Windows.Forms.Button
$buttonCheckConfig.Text = "Vérifier la Config"
$buttonCheckConfig.Location = New-Object System.Drawing.Point(10, 80)
$buttonCheckConfig.Size = New-Object System.Drawing.Size(130, 30)
$buttonCheckConfig.Add_Click({
    $sharedMailbox = $textBoxMailbox.Text.Trim()
    if (-not [string]::IsNullOrEmpty($sharedMailbox)) {
        try {
            # Vérifier si la journalisation est activée
            $mailboxConfig = Get-Mailbox -Identity $sharedMailbox | Select-Object AuditEnabled, AuditLogAgeLimit
            if ($mailboxConfig.AuditEnabled) {
                [System.Windows.Forms.MessageBox]::Show("La journalisation est activée pour la boîte aux lettres.`nDurée de rétention : $($mailboxConfig.AuditLogAgeLimit) jours.", "Journalisation Activée", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                $response = [System.Windows.Forms.MessageBox]::Show("La journalisation est désactivée pour la boîte aux lettres. Souhaitez-vous l'activer ?", "Journalisation Désactivée", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                if ($response -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Set-Mailbox -Identity $sharedMailbox -AuditEnabled $true
                    [System.Windows.Forms.MessageBox]::Show("La journalisation a été activée avec succès.", "Journalisation Activée", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur lors de la vérification de la configuration : $_", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Veuillez saisir une adresse de boîte aux lettres valide.", "Champ manquant", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$panelConfig.Controls.Add($buttonCheckConfig)

# Bouton pour configurer la durée de rétention des logs
$buttonSetRetention = New-Object System.Windows.Forms.Button
$buttonSetRetention.Text = "Modifier la Rétention"
$buttonSetRetention.Location = New-Object System.Drawing.Point(150, 80)
$buttonSetRetention.Size = New-Object System.Drawing.Size(130, 30)
$buttonSetRetention.Add_Click({
    $sharedMailbox = $textBoxMailbox.Text.Trim()
    if (-not [string]::IsNullOrEmpty($sharedMailbox)) {
        try {
            # Vérifier la durée de rétention actuelle
            $mailboxConfig = Get-Mailbox -Identity $sharedMailbox | Select-Object AuditLogAgeLimit
            $currentRetention = $mailboxConfig.AuditLogAgeLimit

            # Afficher un avertissement avant de modifier la durée de rétention
            $response = [System.Windows.Forms.MessageBox]::Show("Vous êtes sur le point de modifier la durée de rétention des logs.`nDurée actuelle : $currentRetention jours.`nVoulez-vous continuer ?", "Avertissement", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($response -eq [System.Windows.Forms.DialogResult]::Yes) {
                # Demander à l'utilisateur de saisir une nouvelle durée de rétention
                $newRetention = [System.Windows.Forms.InputBox]::Show("Entrez la nouvelle durée de rétention (en jours) :", "Configurer la Rétention", $currentRetention)
                if (-not [string]::IsNullOrEmpty($newRetention)) {
                    Set-Mailbox -Identity $sharedMailbox -AuditLogAgeLimit $newRetention
                    [System.Windows.Forms.MessageBox]::Show("La durée de rétention a été configurée avec succès.", "Rétention Configurée", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur lors de la configuration de la rétention : $_", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Veuillez saisir une adresse de boîte aux lettres valide.", "Champ manquant", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$panelConfig.Controls.Add($buttonSetRetention)

# Bouton pour désactiver la journalisation
$buttonDisableAudit = New-Object System.Windows.Forms.Button
$buttonDisableAudit.Text = "Désactiver la Journalisation"
$buttonDisableAudit.Location = New-Object System.Drawing.Point(10, 120)
$buttonDisableAudit.Size = New-Object System.Drawing.Size(270, 30)
$buttonDisableAudit.Add_Click({
    $sharedMailbox = $textBoxMailbox.Text.Trim()
    if (-not [string]::IsNullOrEmpty($sharedMailbox)) {
        # Afficher un avertissement avant de désactiver la journalisation
        $response = [System.Windows.Forms.MessageBox]::Show("Vous êtes sur le point de désactiver la journalisation pour cette boîte aux lettres.`nCette action empêchera l'enregistrement des logs.`nVoulez-vous continuer ?", "Avertissement", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($response -eq [System.Windows.Forms.DialogResult]::Yes) {
            Set-Mailbox -Identity $sharedMailbox -AuditEnabled $false
            [System.Windows.Forms.MessageBox]::Show("La journalisation a été désactivée avec succès.", "Journalisation Désactivée", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Veuillez saisir une adresse de boîte aux lettres valide.", "Champ manquant", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$panelConfig.Controls.Add($buttonDisableAudit)

# Créer un panneau pour les résultats des logs
$panelLogs = New-Object System.Windows.Forms.Panel
$panelLogs.Location = New-Object System.Drawing.Point(320, 10)
$panelLogs.Size = New-Object System.Drawing.Size(850, 330)  # Largeur augmentée
$panelLogs.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($panelLogs)

# DataGridView pour afficher les logs
$dataGridViewLogs = New-Object System.Windows.Forms.DataGridView
$dataGridViewLogs.Location = New-Object System.Drawing.Point(10, 10)
$dataGridViewLogs.Size = New-Object System.Drawing.Size(830, 310)  # Taille ajustée
$dataGridViewLogs.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$dataGridViewLogs.ReadOnly = $true
$dataGridViewLogs.AllowUserToAddRows = $false
$panelLogs.Controls.Add($dataGridViewLogs)

# Ajouter des sélecteurs de date pour la période de recherche
$labelStartDate = New-Object System.Windows.Forms.Label
$labelStartDate.Text = "Date de début :"
$labelStartDate.Location = New-Object System.Drawing.Point(10, 350)
$labelStartDate.AutoSize = $true
$form.Controls.Add($labelStartDate)

$dateTimePickerStart = New-Object System.Windows.Forms.DateTimePicker
$dateTimePickerStart.Location = New-Object System.Drawing.Point(100, 350)
$dateTimePickerStart.Size = New-Object System.Drawing.Size(150, 20)
$dateTimePickerStart.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
$form.Controls.Add($dateTimePickerStart)

$labelEndDate = New-Object System.Windows.Forms.Label
$labelEndDate.Text = "Date de fin :"
$labelEndDate.Location = New-Object System.Drawing.Point(260, 350)
$labelEndDate.AutoSize = $true
$form.Controls.Add($labelEndDate)

$dateTimePickerEnd = New-Object System.Windows.Forms.DateTimePicker
$dateTimePickerEnd.Location = New-Object System.Drawing.Point(330, 350)
$dateTimePickerEnd.Size = New-Object System.Drawing.Size(150, 20)
$dateTimePickerEnd.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
$form.Controls.Add($dateTimePickerEnd)

# Bouton pour lancer la recherche des logs
$buttonSearch = New-Object System.Windows.Forms.Button
$buttonSearch.Text = "Rechercher les Logs"
$buttonSearch.Location = New-Object System.Drawing.Point(500, 350)
$buttonSearch.Size = New-Object System.Drawing.Size(150, 30)
$buttonSearch.Add_Click({
    $sharedMailbox = $textBoxMailbox.Text.Trim()
    $startDate = $dateTimePickerStart.Value
    $endDate = $dateTimePickerEnd.Value

    if (-not [string]::IsNullOrEmpty($sharedMailbox)) {
        try {
            # Rechercher les logs SendAs avec Search-MailboxAuditLog
            $logs = Search-MailboxAuditLog -Identity $sharedMailbox -LogonTypes Delegate -ShowDetails -StartDate $startDate -EndDate $endDate

            if ($logs) {
                # Préparer les données pour le DataGridView
                $dataTable = New-Object System.Data.DataTable
                $dataTable.Columns.Add("Date et Heure", [string])
                $dataTable.Columns.Add("Utilisateur", [string])
                $dataTable.Columns.Add("Action", [string])
                $dataTable.Columns.Add("Résultat", [string])
                $dataTable.Columns.Add("Objet du message", [string])
                $dataTable.Columns.Add("Adresse IP", [string])
                $dataTable.Columns.Add("Machine cliente", [string])
                $dataTable.Columns.Add("Processus client", [string])
                $dataTable.Columns.Add("Version du client", [string])
                $dataTable.Columns.Add("Serveur d'origine", [string])

                foreach ($log in $logs) {
                    $dataTable.Rows.Add(
                        $log.LastAccessed,
                        $log.MailboxOwnerUPN,
                        $log.Operation,
                        $log.OperationResult,
                        $log.ItemSubject,
                        $log.ClientIPAddress,
                        $log.ClientMachineName,
                        $log.ClientProcessName,
                        $log.ClientVersion,
                        $log.OriginatingServer
                    )
                }

                # Afficher les données dans le DataGridView
                $dataGridViewLogs.DataSource = $dataTable
            } else {
                [System.Windows.Forms.MessageBox]::Show("Aucun log trouvé pour la période spécifiée.", "Aucun log trouvé", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur lors de la recherche des logs : $_", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Veuillez saisir une adresse de boîte aux lettres valide.", "Champ manquant", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$form.Controls.Add($buttonSearch)

# Bouton pour exporter les logs
$buttonExport = New-Object System.Windows.Forms.Button
$buttonExport.Text = "Exporter les Logs"
$buttonExport.Location = New-Object System.Drawing.Point(660, 350)
$buttonExport.Size = New-Object System.Drawing.Size(150, 30)
$buttonExport.Add_Click({
    $sharedMailbox = $textBoxMailbox.Text.Trim()
    $startDate = $dateTimePickerStart.Value
    $endDate = $dateTimePickerEnd.Value

    if (-not [string]::IsNullOrEmpty($sharedMailbox)) {
        # Ouvrir une boîte de dialogue pour choisir l'emplacement de sauvegarde
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Sélectionnez un dossier pour enregistrer les logs"
        $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer

        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $saveLocation = $folderBrowser.SelectedPath
            $outputFile = Join-Path -Path $saveLocation -ChildPath "AuditLogs_$($sharedMailbox)_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

            # Exporter les logs d'audit
            try {
                $logs = Search-MailboxAuditLog -Identity $sharedMailbox -LogonTypes Delegate -ShowDetails -StartDate $startDate -EndDate $endDate
                if ($logs) {
                    $logs | Export-Csv -Path $outputFile -NoTypeInformation
                    [System.Windows.Forms.MessageBox]::Show("Les logs ont été exportés avec succès vers :`n$outputFile", "Exportation réussie", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                } else {
                    [System.Windows.Forms.MessageBox]::Show("Aucun log trouvé pour la période spécifiée.", "Aucun log trouvé", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                }
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Erreur lors de l'exportation des logs : $_", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Veuillez saisir une adresse de boîte aux lettres valide.", "Champ manquant", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$form.Controls.Add($buttonExport)

# Créer un panneau pour les délégations
$panelDelegations = New-Object System.Windows.Forms.Panel
$panelDelegations.Location = New-Object System.Drawing.Point(10, 400)  # Déplacé sous les boutons
$panelDelegations.Size = New-Object System.Drawing.Size(1160, 350)  # Largeur maximale
$panelDelegations.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($panelDelegations)

# DataGridView pour afficher les délégations
$dataGridViewDelegations = New-Object System.Windows.Forms.DataGridView
$dataGridViewDelegations.Location = New-Object System.Drawing.Point(10, 50)
$dataGridViewDelegations.Size = New-Object System.Drawing.Size(1140, 290)  # Largeur maximale
$dataGridViewDelegations.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$dataGridViewDelegations.ReadOnly = $true
$dataGridViewDelegations.AllowUserToAddRows = $false
$panelDelegations.Controls.Add($dataGridViewDelegations)

# Bouton pour vérifier les délégations
$buttonCheckDelegations = New-Object System.Windows.Forms.Button
$buttonCheckDelegations.Text = "Vérifier les Délégations"
$buttonCheckDelegations.Location = New-Object System.Drawing.Point(10, 10)
$buttonCheckDelegations.Size = New-Object System.Drawing.Size(200, 30)  # Largeur maximale
$buttonCheckDelegations.Add_Click({
    $sharedMailbox = $textBoxMailbox.Text.Trim()
    if (-not [string]::IsNullOrEmpty($sharedMailbox)) {
        try {
            # Vérifier les délégations
            $delegations = Get-MailboxPermission -Identity $sharedMailbox | Where-Object { $_.AccessRights -like "*FullAccess*" -or $_.AccessRights -like "*SendAs*" }

            # Préparer les données pour le DataGridView
            $dataTable = New-Object System.Data.DataTable
            $dataTable.Columns.Add("Utilisateur", [string])
            $dataTable.Columns.Add("Droits", [string])

            if ($delegations) {
                foreach ($delegation in $delegations) {
                    $dataTable.Rows.Add($delegation.User, $delegation.AccessRights)
                }
            }

            # Afficher les données dans le DataGridView
            $dataGridViewDelegations.DataSource = $dataTable
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erreur lors de la vérification des délégations : $_", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Veuillez saisir une adresse de boîte aux lettres valide.", "Champ manquant", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$panelDelegations.Controls.Add($buttonCheckDelegations)

# Afficher le formulaire
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()