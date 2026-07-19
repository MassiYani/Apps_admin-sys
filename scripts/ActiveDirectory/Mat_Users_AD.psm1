# Get-ADUsers-GUI.ps1 — version améliorée avec statut du compte (activé/désactivé)
# Compatible PowerShell 7.4.6 / RSAT Active Directory
# Auteur : Massi + GPT-5 ✨

Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# --- XAML Interface ---
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Export AD Users — sAMAccountName / mail / employeeID / statut" Height="540" Width="950" WindowStartupLocation="CenterScreen">
  <Grid Margin="8">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto" />
      <RowDefinition Height="*" />
      <RowDefinition Height="Auto" />
    </Grid.RowDefinitions>

    <!-- Barre d'options -->
    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
      <TextBlock VerticalAlignment="Center" Margin="0,0,8,0">OU cible :</TextBlock>
      <ComboBox Name="cbOu" Width="340" IsEditable="False" SelectedIndex="0">
        <ComboBoxItem Tag="OU=Bejaia,DC=Cevital,DC=com">OU=Bejaia,DC=Cevital,DC=com</ComboBoxItem>
        <ComboBoxItem Tag="OU=Cojek,DC=Cevital,DC=com">OU=Cojek,DC=Cevital,DC=com</ComboBoxItem>
        <ComboBoxItem Tag="OU=Lalla Khedidja,DC=Cevital,DC=com">OU=Lalla Khedidja,DC=Cevital,DC=com</ComboBoxItem>
        <ComboBoxItem Tag="ALL">Toute l'Active Directory</ComboBoxItem>
      </ComboBox>

      <Button Name="btnSearch" Width="110" Margin="12,0,0,0">Rechercher</Button>
      <Button Name="btnClear" Width="90" Margin="8,0,0,0">Effacer</Button>
      <Button Name="btnExport" Width="120" Margin="12,0,0,0">Exporter CSV...</Button>

      <TextBox Name="txtFilter" Width="220" Margin="12,0,0,0" VerticalAlignment="Center" 
               ToolTip="Filtrer (ex: startswith(Name,'A')) ou laisser vide" />
      <TextBlock VerticalAlignment="Center" Margin="8,0,0,0">Filtre LDAP/AD - Optionnel</TextBlock>
    </StackPanel>

    <!-- Tableau des résultats -->
    <DataGrid Name="dgResults" Grid.Row="1" AutoGenerateColumns="False" CanUserSortColumns="True" IsReadOnly="True" AlternatingRowBackground="#FFEFEFEF">
      <DataGrid.Columns>
        <DataGridTextColumn Header="Nom (displayName)" Binding="{Binding Name}" Width="200"/>
        <DataGridTextColumn Header="sAMAccountName" Binding="{Binding sAMAccountName}" Width="180"/>
        <DataGridTextColumn Header="Adresse mail" Binding="{Binding mail}" Width="200"/>
        <DataGridTextColumn Header="employeeID" Binding="{Binding employeeID}" Width="100"/>
        <DataGridTextColumn Header="Statut du compte" Binding="{Binding AccountStatus}" Width="120"/>
        <DataGridTextColumn Header="DistinguishedName" Binding="{Binding DistinguishedName}" Width="*"/>
      </DataGrid.Columns>
    </DataGrid>

    <!-- Barre d'état -->
    <StatusBar Grid.Row="2" Margin="0,6,0,0">
      <StatusBarItem>
        <TextBlock Name="txtStatus">Prêt.</TextBlock>
      </StatusBarItem>
    </StatusBar>
  </Grid>
</Window>
"@

# --- Chargement du XAML ---
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# --- Raccourcis pour les contrôles ---
function Get-Control([string]$name){ return $window.FindName($name) }
$cbOu = Get-Control 'cbOu'
$btnSearch = Get-Control 'btnSearch'
$btnExport = Get-Control 'btnExport'
$btnClear = Get-Control 'btnClear'
$dgResults = Get-Control 'dgResults'
$txtStatus = Get-Control 'txtStatus'
$txtFilter = Get-Control 'txtFilter'

$global:results = @()

# --- Fonction principale ---
function Query-ADUsers {
    param(
        [string]$SearchBase,
        [string]$FilterLDAP
    )

    try {
        Import-Module ActiveDirectory -UseWindowsPowerShell -ErrorAction Stop

        # Propriétés à récupérer
        $props = 'Name','sAMAccountName','mail','employeeID','DistinguishedName','Enabled'

        # Choix de la base et du filtre
        if ($SearchBase -eq 'ALL'){
            if ([string]::IsNullOrWhiteSpace($FilterLDAP)){
                $users = Get-ADUser -Filter * -Properties $props
            } else {
                try {
                    $users = Get-ADUser -LDAPFilter $FilterLDAP -Properties $props
                } catch {
                    $users = Get-ADUser -Filter $FilterLDAP -Properties $props
                }
            }
        } else {
            if ([string]::IsNullOrWhiteSpace($FilterLDAP)){
                $users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $props
            } else {
                try {
                    $users = Get-ADUser -LDAPFilter $FilterLDAP -SearchBase $SearchBase -Properties $props
                } catch {
                    $users = Get-ADUser -Filter $FilterLDAP -SearchBase $SearchBase -Properties $props
                }
            }
        }

        # Mapping des résultats
        $arr = $users | Sort-Object Name | Select-Object `
            @{n='Name';e={$_.Name}},
            sAMAccountName,
            mail,
            employeeID,
            @{n='AccountStatus';e={ if ($_.Enabled) {'✅ Actif'} else {'❌ Désactivé'} }},
            DistinguishedName

        return $arr

    } catch {
        throw $_
    }
}

# --- Événements ---
$btnSearch.Add_Click({
    try {
        $txtStatus.Text = 'Recherche en cours...'
        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        Start-Sleep -Milliseconds 100

        $sel = $cbOu.SelectedItem
        $searchBase = if ($sel -and $sel.Tag){ $sel.Tag } else { 'ALL' }
        $ldapFilter = $txtFilter.Text.Trim()

        $global:results = Query-ADUsers -SearchBase $searchBase -FilterLDAP $ldapFilter
        $dgResults.ItemsSource = $global:results
        $txtStatus.Text = "${($global:results).Count} comptes récupérés."
    } catch {
        [System.Windows.MessageBox]::Show("Erreur : $($_.Exception.Message)", 'Erreur', 'OK', 'Error') | Out-Null
        $txtStatus.Text = 'Erreur pendant la recherche.'
    } finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})

$btnClear.Add_Click({
    $global:results = @()
    $dgResults.ItemsSource = $null
    $txtStatus.Text = 'Table effacée.'
})

$btnExport.Add_Click({
    try {
        if (-not $global:results -or $global:results.Count -eq 0){
            [System.Windows.MessageBox]::Show('Aucune donnée à exporter.','Info','OK','Information') | Out-Null
            return
        }

        $saveDlg = New-Object System.Windows.Forms.SaveFileDialog
        $saveDlg.Filter = 'CSV files (*.csv)|*.csv|All files (*.*)|*.*'
        $saveDlg.FileName = 'AD-Users-export.csv'
        $res = $saveDlg.ShowDialog()
        if ($res -ne [System.Windows.Forms.DialogResult]::OK){ return }

        $path = $saveDlg.FileName
        $global:results | Select-Object Name,sAMAccountName,mail,employeeID,AccountStatus,DistinguishedName |
            Export-Csv -Path $path -NoTypeInformation -Encoding UTF8

        [System.Windows.MessageBox]::Show("Export terminé : `n$path", 'Succès', 'OK', 'Information') | Out-Null
        $txtStatus.Text = "Exporté : $path"
    } catch {
        [System.Windows.MessageBox]::Show("Erreur export : $($_.Exception.Message)", 'Erreur', 'OK', 'Error') | Out-Null
        $txtStatus.Text = 'Erreur pendant l''export.'
    }
})

# Double-clic = copie du sAMAccountName
$dgResults.Add_MouseDoubleClick({
    $item = $dgResults.SelectedItem
    if ($item -ne $null){
        [System.Windows.Clipboard]::SetText($item.sAMAccountName)
        $txtStatus.Text = "sAMAccountName copié : $($item.sAMAccountName)"
    }
})

# Touche Entrée = lancer la recherche
$txtFilter.Add_KeyDown({
    param($s,$e)
    if ($e.Key -eq 'Enter'){ 
        $btnSearch.RaiseEvent([System.Windows.RoutedEventArgs]::new(
            [System.Windows.Controls.Primitives.ButtonBase]::ClickEvent
        )) 
    }
})

# --- Affichage de la fenêtre ---
$window.ShowDialog() | Out-Null
