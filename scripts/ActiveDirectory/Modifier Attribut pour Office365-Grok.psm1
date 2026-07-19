#requires -Version 5.1
#requires -Module ActiveDirectory

# Script PowerShell pour modifier l'attribut msDS-cloudExtensionAttribute20 des utilisateurs AD
# Auteur: Grok
# Date: 13/08/2025
# Description: Interface graphique WPF pour importer une liste d'utilisateurs depuis un .txt, vérifier et modifier l'attribut, afficher les résultats et exporter en CSV.

# Charger les assemblies nécessaires pour WPF
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms  # Pour les dialogs de fichier

# Définir l'XAML pour l'interface graphique
$XAML = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Modificateur d'Attribut AD - msDS-cloudExtensionAttribute20"
        Height="600" Width="800" ResizeMode="CanResizeWithGrip"
        WindowStartupLocation="CenterScreen"
        Background="#F0F0F0">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Titre et instructions -->
        <TextBlock Grid.Row="0" Text="Outil pour modifier l'attribut msDS-cloudExtensionAttribute20 vers 'office365'" FontSize="16" FontWeight="Bold" Margin="0,0,0,10"/>

        <!-- Boutons pour charger et lancer -->
        <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,10">
            <Button x:Name="BtnLoadFile" Content="Charger le fichier .txt" Width="150" Height="30" Margin="0,0,10,0" Background="#0078D7" Foreground="White"/>
            <Button x:Name="BtnProcess" Content="Lancer le traitement" Width="150" Height="30" Margin="0,0,10,0" Background="#0078D7" Foreground="White" IsEnabled="False"/>
            <Button x:Name="BtnExport" Content="Exporter en CSV" Width="150" Height="30" Background="#0078D7" Foreground="White" IsEnabled="False"/>
        </StackPanel>

        <!-- DataGrid pour afficher les résultats -->
        <DataGrid x:Name="ResultsGrid" Grid.Row="2" AutoGenerateColumns="False" IsReadOnly="True" AlternatingRowBackground="#E0E0E0" Margin="0,0,0,10">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Utilisateur fourni" Binding="{Binding UserProvided}" Width="150"/>
                <DataGridTextColumn Header="Compte utilisateur" Binding="{Binding SamAccountName}" Width="150"/>
                <DataGridTextColumn Header="Old Value" Binding="{Binding OldValue}" Width="150"/>
                <DataGridTextColumn Header="New Value" Binding="{Binding NewValue}" Width="150"/>
                <DataGridTextColumn Header="Résultat" Binding="{Binding Result}" Width="*"/>
            </DataGrid.Columns>
        </DataGrid>

        <!-- Zone pour messages d'erreur ou statut -->
        <TextBox x:Name="StatusBox" Grid.Row="3" Height="100" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Margin="0,0,0,10" Background="#FFFFFF" BorderBrush="#CCCCCC"/>

        <!-- Barre de progression -->
        <ProgressBar x:Name="ProgressBar" Grid.Row="4" Height="20" Visibility="Hidden"/>
    </Grid>
</Window>
'@

# Charger l'XAML
$Reader = New-Object System.Xml.XmlNodeReader ([xml]$XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Récupérer les contrôles par nom
$BtnLoadFile = $Window.FindName('BtnLoadFile')
$BtnProcess = $Window.FindName('BtnProcess')
$BtnExport = $Window.FindName('BtnExport')
$ResultsGrid = $Window.FindName('ResultsGrid')
$StatusBox = $Window.FindName('StatusBox')
$ProgressBar = $Window.FindName('ProgressBar')

# Variables globales
$script:UsersList = @()
$script:Results = @()

# Fonction pour ajouter un message de statut
function Add-StatusMessage {
    param([string]$Message)
    $StatusBox.AppendText("$Message`n")
    $StatusBox.ScrollToEnd()
}

# Événement pour charger le fichier .txt
$BtnLoadFile.Add_Click({
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "Fichiers texte (*.txt)|*.txt"
    $OpenFileDialog.Title = "Sélectionner le fichier contenant les SamAccountNames"

    if ($OpenFileDialog.ShowDialog() -eq 'OK') {
        try {
            $script:UsersList = Get-Content -Path $OpenFileDialog.FileName -ErrorAction Stop | Where-Object { $_ -match '\S' }
            Add-StatusMessage "Fichier chargé : $($script:UsersList.Count) utilisateurs trouvés."
            $BtnProcess.IsEnabled = $true
        } catch {
            Add-StatusMessage "Erreur lors du chargement du fichier : $($_.Exception.Message)"
        }
    }
})

# Événement pour lancer le traitement
$BtnProcess.Add_Click({
    $script:Results = @()
    $ResultsGrid.ItemsSource = $null
    $BtnExport.IsEnabled = $false
    $ProgressBar.Visibility = 'Visible'
    $ProgressBar.Value = 0
    $ProgressBar.Maximum = $script:UsersList.Count

    foreach ($UserProvided in $script:UsersList) {
        $ResultObj = [PSCustomObject]@{
            UserProvided   = $UserProvided
            SamAccountName = $null
            OldValue       = $null
            NewValue       = $null
            Result         = $null
        }

        try {
            # Récupérer les propriétés AD sans conserver l'objet désérialisé
            $ADUser = Get-ADUser -Identity $UserProvided -Properties SamAccountName, msDS-cloudExtensionAttribute20 -ErrorAction Stop
            $ResultObj.SamAccountName = $ADUser.SamAccountName
            $OldValue = $ADUser.'msDS-cloudExtensionAttribute20'

            $ResultObj.OldValue = if ($null -eq $OldValue) { "Vide" } else { $OldValue }

            if ($OldValue -eq "office365") {
                $ResultObj.Result = "Déjà défini sur office365"
            } else {
                # Modifier l'attribut en utilisant directement l'identité
                Set-ADUser -Identity $UserProvided -Replace @{'msDS-cloudExtensionAttribute20' = "office365"} -ErrorAction Stop
                $ResultObj.NewValue = "office365"
                $ResultObj.Result = "Modifié"
            }
        } catch {
            $ResultObj.Result = "Erreur: $($_.Exception.Message)"
            Add-StatusMessage "Erreur pour $UserProvided : $($_.Exception.Message)"
        }

        $script:Results += $ResultObj
        $ProgressBar.Value += 1
        $ResultsGrid.ItemsSource = $script:Results
        $ResultsGrid.Items.Refresh()
    }

    $ProgressBar.Visibility = 'Hidden'
    Add-StatusMessage "Traitement terminé. $($script:Results.Count) utilisateurs traités."
    $BtnExport.IsEnabled = $true
})

# Événement pour exporter en CSV
$BtnExport.Add_Click({
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.Filter = "Fichiers CSV (*.csv)|*.csv"
    $SaveFileDialog.Title = "Enregistrer les résultats en CSV"
    $SaveFileDialog.FileName = "Resultats_AD_Modification.csv"

    if ($SaveFileDialog.ShowDialog() -eq 'OK') {
        try {
            $script:Results | Export-Csv -Path $SaveFileDialog.FileName -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
            Add-StatusMessage "Résultats exportés vers : $($SaveFileDialog.FileName)"
        } catch {
            Add-StatusMessage "Erreur lors de l'export : $($_.Exception.Message)"
        }
    }
})

# Afficher la fenêtre
$Window.ShowDialog() | Out-Null