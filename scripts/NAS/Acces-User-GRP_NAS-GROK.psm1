Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms


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


# Fonction pour obtenir les détails d'accès récursivement
function Obtenir-DetailsAccesRecursif {
    param (
        [string]$cheminRepertoire,
        [string]$identite,
        [bool]$estGroupe,
        [System.Windows.Controls.TextBox]$logWindowTextBox,
        [ref]$cancelFlag,
        [int]$depth = 0,
        [int]$maxDepth = 10
    )

    if ($depth -gt $maxDepth) {
        $logWindowTextBox.AppendText("Profondeur maximale atteinte: $($cheminRepertoire)`r`n")
        return @()
    }

    if ($cancelFlag.Value) {
        $logWindowTextBox.AppendText("Analyse annulée par l'utilisateur.`r`n")
        return @()
    }

    $resultats = @()
    try {
        $logWindowTextBox.AppendText("Traitement du dossier: $($cheminRepertoire)`r`n")
        $acl = Get-Acl -Path $cheminRepertoire -ErrorAction Stop
        foreach ($droit in $acl.Access) {
            if ($droit -is [System.Security.AccessControl.FileSystemAccessRule]) {
                if ($estGroupe) {
                    try {
                        $groupeSid = (New-Object System.Security.Principal.NTAccount($identite)).Translate([System.Security.Principal.SecurityIdentifier]).Value
                        if ($droit.IdentityReference.Value -eq $groupeSid) {
                            $resultats += [PSCustomObject]@{
                                Timestamp = Get-Date
                                CheminPartage = $cheminRepertoire
                                Identité = $droit.IdentityReference
                                TypeAcces = $droit.FileSystemRights
                                TypeHeritage = $droit.InheritanceFlags
                                TypePropagation = $droit.PropagationFlags
                                EstHérité = $droit.IsInherited
                            }
                            $logWindowTextBox.AppendText("Accès trouvé (groupe): $($droit.IdentityReference) - Hérité: $($droit.IsInherited)`r`n")
                        }
                    } catch {
                        $logWindowTextBox.AppendText("Erreur SID groupe '$identite': $($_.Exception.Message)`r`n")
                    }
                } else {
                    if ($droit.IdentityReference -like "*\$identite") {
                        $resultats += [PSCustomObject]@{
                            Timestamp = Get-Date
                            CheminPartage = $cheminRepertoire
                            Identité = $droit.IdentityReference
                            TypeAcces = $droit.FileSystemRights
                            TypeHeritage = $droit.InheritanceFlags
                            TypePropagation = $droit.PropagationFlags
                            EstHérité = $droit.IsInherited
                        }
                        $logWindowTextBox.AppendText("Accès trouvé (utilisateur): $($droit.IdentityReference) - Hérité: $($droit.IsInherited)`r`n")
                    }
                }
            }
        }

        $sousDossiers = Get-ChildItem -Path $cheminRepertoire -Directory -ErrorAction SilentlyContinue
        foreach ($sousDossier in $sousDossiers) {
            if ($cancelFlag.Value) { break }
            $resultats += Obtenir-DetailsAccesRecursif -cheminRepertoire $sousDossier.FullName `
                -identite $identite -estGroupe $estGroupe -logWindowTextBox $logWindowTextBox `
                -cancelFlag $cancelFlag -depth ($depth + 1)
        }
    } catch {
        $errorDetails = [PSCustomObject]@{
            Timestamp = Get-Date
            Path = $cheminRepertoire
            Error = $_.Exception.Message
            StackTrace = $_.ScriptStackTrace
        }
        $logWindowTextBox.AppendText("Erreur: $($errorDetails | Format-List | Out-String)`r`n")
    }
    return $resultats
}

# Interface principale
$xamlMain = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Détails d'accès aux partages" Height="700" Width="900">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Orientation="Horizontal" Margin="5">
            <Label Content="Identité:" ToolTip="Nom d'utilisateur ou groupe"/>
            <TextBox x:Name="txtIdentite" Width="150" Margin="0,0,5,0"/>
            <Label Content="Répertoire:" ToolTip="Chemin du dossier à analyser"/>
            <TextBox x:Name="txtRepertoire" Width="300" Margin="0,0,5,0"/>
            <Button x:Name="btnParcourir" Content="..." Width="30" Margin="0,0,5,0"/>
            <CheckBox x:Name="chkGroupe" Content="Groupe" Margin="0,0,5,0"/>
            <Button x:Name="BtnObtenirAcces" Content="Analyser" Margin="0,0,5,0"/>
            <Button x:Name="BtnAnnuler" Content="Annuler" Margin="0,0,5,0" IsEnabled="False"/>
        </StackPanel>
        <ProgressBar x:Name="progressBar" Grid.Row="1" Height="20" Margin="5" Visibility="Hidden"/>
        <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="5">
            <Label Content="Filtrer par type d'accès:"/>
            <ComboBox x:Name="cbFilter" Width="150" Margin="5,0,0,0">
                <ComboBoxItem Content="Tous" IsSelected="True"/>
                <ComboBoxItem Content="Lecture et écriture"/>
                <ComboBoxItem Content="Lecture seule"/>
            </ComboBox>
        </StackPanel>
        <Grid Grid.Row="3">
            <DataGrid x:Name="dgResultats" AutoGenerateColumns="True" IsReadOnly="True" CanUserSortColumns="True"/>
        </Grid>
        <StatusBar Grid.Row="4">
            <StatusBarItem>
                <TextBlock x:Name="statusText" Text="Prêt"/>
            </StatusBarItem>
            <StatusBarItem HorizontalAlignment="Right">
                <Button x:Name="BtnExporterCSV" Content="Exporter"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

# Interface de log
$xamlLog = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Traitement en temps réel" Height="400" Width="600">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBox x:Name="txtLog" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Margin="5"/>
        <Button x:Name="btnFermer" Content="Fermer" Grid.Row="1" HorizontalAlignment="Right" Margin="5" IsEnabled="False"/>
    </Grid>
</Window>
"@

# Chargement des fenêtres
$readerMain = [System.Xml.XmlReader]::Create([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($xamlMain)))
$windowMain = [Windows.Markup.XamlReader]::Load($readerMain)

# Variables globales
$datagrid = $windowMain.FindName("dgResultats")
$script:cancelFlag = $false
$script:logWindow = $null
$script:fullResults = @()

# Bouton Parcourir
$windowMain.FindName("btnParcourir").Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $windowMain.FindName("txtRepertoire").Text = $folderBrowser.SelectedPath
    }
})

# Filtre dans la grille (avec message si aucun résultat)
$windowMain.FindName("cbFilter").Add_SelectionChanged({
    $filter = $windowMain.FindName("cbFilter").SelectedItem.Content
    $statusText = $windowMain.FindName("statusText")
    $identite = $windowMain.FindName("txtIdentite").Text
    $repertoire = $windowMain.FindName("txtRepertoire").Text

    if ($script:fullResults) {
        if ($filter -eq "Tous") {
            $datagrid.ItemsSource = $script:fullResults
            if ($script:fullResults.Count -gt 0) {
                $statusText.Text = "Analyse terminée - $($script:fullResults.Count) éléments trouvés"
            } else {
                $statusText.Text = "Pas d'accès pour l'utilisateur '$identite' sur le dossier '$repertoire' et ses sous-dossiers."
            }
        } elseif ($filter -eq "Lecture et écriture") {
            $filteredResults = $script:fullResults | Where-Object { 
                $_.TypeAcces -match "Write" -or $_.TypeAcces -match "Modify" -or $_.TypeAcces -match "FullControl"
            }
            $datagrid.ItemsSource = $filteredResults
            if ($filteredResults.Count -eq 0) {
                $statusText.Text = "L'utilisateur '$identite' n'a aucun accès de type 'Lecture et écriture' dans le dossier '$repertoire' et ses sous-dossiers."
            } else {
                $statusText.Text = "Analyse terminée - $($filteredResults.Count) éléments trouvés (Lecture et écriture)"
            }
        } elseif ($filter -eq "Lecture seule") {
            $filteredResults = $script:fullResults | Where-Object { 
                ($_.TypeAcces -match "Read" -or $_.TypeAcces -match "ReadAndExecute") `
                -and $_.TypeAcces -notmatch "Write" `
                -and $_.TypeAcces -notmatch "Modify" `
                -and $_.TypeAcces -notmatch "FullControl"
            }
            $datagrid.ItemsSource = $filteredResults
            if ($filteredResults.Count -eq 0) {
                $statusText.Text = "L'utilisateur '$identite' n'a aucun accès de type 'Lecture seule' dans le dossier '$repertoire' et ses sous-dossiers."
            } else {
                $statusText.Text = "Analyse terminée - $($filteredResults.Count) éléments trouvés (Lecture seule)"
            }
        }
    }
})

# Bouton Analyser
$windowMain.FindName("BtnObtenirAcces").Add_Click({
    $identite = $windowMain.FindName("txtIdentite").Text
    $repertoire = $windowMain.FindName("txtRepertoire").Text
    $estGroupe = $windowMain.FindName("chkGroupe").IsChecked
    $progressBar = $windowMain.FindName("progressBar")
    $statusText = $windowMain.FindName("statusText")

    # Validation
    if (-not $identite -or -not $repertoire -or -not (Test-Path $repertoire)) {
        [System.Windows.MessageBox]::Show("Veuillez spécifier une identité et un répertoire valide.", "Erreur", "OK", "Error")
        return
    }

    # Nettoyage
    $datagrid.ItemsSource = $null
    $script:fullResults = @()
    $script:cancelFlag = $false
    $progressBar.Visibility = "Visible"
    $statusText.Text = "Analyse en cours..."
    $windowMain.FindName("BtnObtenirAcces").IsEnabled = $false
    $windowMain.FindName("BtnAnnuler").IsEnabled = $true

    # Nouvelle fenêtre de log
    $readerLog = [System.Xml.XmlReader]::Create([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($xamlLog)))
    $script:logWindow = [Windows.Markup.XamlReader]::Load($readerLog)
    $logWindowTextBox = $script:logWindow.FindName("txtLog")
    $script:logWindow.Show()

    # Exécution synchrone
    try {
        $script:fullResults = Obtenir-DetailsAccesRecursif -cheminRepertoire $repertoire -identite $identite `
            -estGroupe $estGroupe -logWindowTextBox $logWindowTextBox -cancelFlag ([ref]$script:cancelFlag)

        if (-not $script:cancelFlag) {
            $datagrid.ItemsSource = $script:fullResults
            if ($script:fullResults.Count -gt 0) {
                $statusText.Text = "Analyse terminée - $($script:fullResults.Count) éléments trouvés"
            } else {
                $statusText.Text = "Pas d'accès pour l'utilisateur '$identite' sur le dossier '$repertoire' et ses sous-dossiers."
            }
            $logWindowTextBox.AppendText("Opération terminée.`r`n")
        } else {
            $statusText.Text = "Analyse annulée"
            $logWindowTextBox.AppendText("Opération annulée.`r`n")
        }
    } catch {
        $statusText.Text = "Erreur lors de l'analyse: $($_.Exception.Message)"
        $logWindowTextBox.AppendText("Erreur: $($_.Exception.Message)`r`n")
    }

    $progressBar.Visibility = "Hidden"
    $windowMain.FindName("BtnObtenirAcces").IsEnabled = $true
    $windowMain.FindName("BtnAnnuler").IsEnabled = $false
    $script:logWindow.FindName("btnFermer").IsEnabled = $true

    # Bouton Fermer
    $script:logWindow.FindName("btnFermer").Add_Click({
        if ($script:logWindow -ne $null) {
            $script:logWindow.Close()
            $script:logWindow = $null
        }
    })
})

# Bouton Annuler
$windowMain.FindName("BtnAnnuler").Add_Click({
    $script:cancelFlag = $true
})

# Bouton Exporter
$windowMain.FindName("BtnExporterCSV").Add_Click({
    $saveFileDialog = New-Object Microsoft.Win32.SaveFileDialog
    $saveFileDialog.Filter = "Fichiers CSV (*.csv)|*.csv|JSON (*.json)|*.json|Tous les fichiers (*.*)|*.*"
    $saveFileDialog.FileName = "Acces_$($windowMain.FindName('txtIdentite').Text)_$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
    
    if ($saveFileDialog.ShowDialog() -eq $true) {
        $cheminFichier = $saveFileDialog.FileName
        $resultats = $datagrid.ItemsSource
        
        if ($resultats -and $resultats.Count -gt 0) {
            switch ([IO.Path]::GetExtension($cheminFichier)) {
                ".csv" { $resultats | Export-Csv -Path $cheminFichier -NoTypeInformation -Encoding UTF8 }
                ".json" { $resultats | ConvertTo-Json -Depth 5 | Out-File -FilePath $cheminFichier -Encoding UTF8 }
            }
            $windowMain.FindName("statusText").Text = "Exporté vers $cheminFichier"
        } else {
            "Aucun résultat à exporter" | Out-File -FilePath $cheminFichier -Encoding UTF8
            $windowMain.FindName("statusText").Text = "Aucun résultat - fichier vide créé"
        }
    }
})

# Afficher la fenêtre principale
$windowMain.ShowDialog() | Out-Null