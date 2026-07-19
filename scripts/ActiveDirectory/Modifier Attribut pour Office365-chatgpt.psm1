<# 
.SYNOPSIS
  Outil WPF pour charger une liste de SamAccountName depuis un .txt,
  contrôler/modifier l’attribut AD "msDS-cloudExtensionAttribute20",
  afficher les résultats et les exporter en CSV.
  → Tri par colonnes + recherche rapide ajoutés.

.COMPATIBILITÉ
  - Windows PowerShell 5.1 : OK (RSAT/Module ActiveDirectory requis)
  - PowerShell 7+ (Windows) : OK via WindowsCompatibility + RSAT AD.
#>

#region Pré-requis & Helpers
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Host 'Relance du script en STA…'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = (Get-Process -Id $PID).Path
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.UseShellExecute = $true
    $psi.Verb = 'runas'
    [Diagnostics.Process]::Start($psi) | Out-Null
    exit
}

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase

$IsPS7 = $PSVersionTable.PSVersion.Major -ge 7

function Import-ADModule {
    try {
        if ($IsPS7) {
            Import-Module ActiveDirectory -UseWindowsPowerShell -ErrorAction Stop
        } else {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        return $true
    } catch {
        return $false
    }
}

class ResultRow {
    [string]$SamAccountName
    [string]$ProvidedUser
    [string]$OldValue
    [string]$NewValue
    [string]$Result
    ResultRow([string]$sam,[string]$prov,[string]$old,[string]$new,[string]$res){
        $this.SamAccountName = $sam
        $this.ProvidedUser   = $prov
        $this.OldValue       = $old
        $this.NewValue       = $new
        $this.Result         = $res
    }
}
#endregion

#region XAML UI
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Gestion msDS-cloudExtensionAttribute20 - Office365"
        Height="680" Width="1000"
        WindowStartupLocation="CenterScreen"
        Background="#0B0F1A">
  <Window.Resources>
    <Style TargetType="Button">
      <Setter Property="Margin" Value="6"/>
      <Setter Property="Padding" Value="10,6"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="Background" Value="#1F3A8A"/>
      <Setter Property="BorderBrush" Value="#93C5FD"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
    <Style TargetType="TextBlock">
      <Setter Property="Foreground" Value="#E5E7EB"/>
    </Style>
    <Style TargetType="DataGrid">
      <Setter Property="Margin" Value="8"/>
      <Setter Property="AutoGenerateColumns" Value="False"/>
      <Setter Property="IsReadOnly" Value="True"/>
      <Setter Property="CanUserAddRows" Value="False"/>
      <Setter Property="AlternatingRowBackground" Value="#111827"/>
      <Setter Property="RowBackground" Value="#0F172A"/>
      <Setter Property="Foreground" Value="#E5E7EB"/>
      <Setter Property="GridLinesVisibility" Value="All"/>
      <Setter Property="BorderBrush" Value="#374151"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="ColumnHeaderHeight" Value="36"/>
      <Setter Property="CanUserSortColumns" Value="True"/>
    </Style>
    <Style TargetType="DataGridColumnHeader">
      <Setter Property="Background" Value="#1E293B"/>
      <Setter Property="Foreground" Value="#F3F4F6"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="HorizontalContentAlignment" Value="Center"/>
    </Style>
  </Window.Resources>

  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Bandeau -->
    <DockPanel Grid.Row="0" LastChildFill="True" Margin="0,0,0,8">
      <TextBlock Text="Attribut : msDS-cloudExtensionAttribute20  |  Valeur cible : &quot;office365&quot;"
                 FontSize="16" FontWeight="Bold" Foreground="#93C5FD" />
    </DockPanel>

    <!-- Boutons -->
    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Left">
      <Button x:Name="BtnLoad" Content="Charger le fichier (.txt)"/>
      <Button x:Name="BtnRun"  Content="Lancer le traitement" IsEnabled="False"/>
      <Button x:Name="BtnExport" Content="Exporter les résultats (CSV)" IsEnabled="False"/>
      <CheckBox x:Name="ChkDryRun" Margin="12,6,0,6" VerticalAlignment="Center">
        <TextBlock Text="Mode simulation (ne pas modifier l’AD)" />
      </CheckBox>
    </StackPanel>

    <!-- Barre de recherche -->
    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="8,4,8,4">
      <TextBlock Text="🔍 Rechercher :" VerticalAlignment="Center" Margin="0,0,6,0"/>
      <TextBox x:Name="TxtSearch" Width="300" Height="24" Background="#1E293B" Foreground="White" BorderBrush="#93C5FD"/>
    </StackPanel>

    <!-- Tableau -->
    <DataGrid x:Name="GridResults" Grid.Row="3">
      <DataGrid.Columns>
        <DataGridTextColumn Header="Compte utilisateur (AD)" Binding="{Binding SamAccountName}" Width="*" SortMemberPath="SamAccountName"/>
        <DataGridTextColumn Header="Utilisateur fourni" Binding="{Binding ProvidedUser}" Width="*" SortMemberPath="ProvidedUser"/>
        <DataGridTextColumn Header="Old Value" Binding="{Binding OldValue}" Width="*" SortMemberPath="OldValue"/>
        <DataGridTextColumn Header="New Value" Binding="{Binding NewValue}" Width="*" SortMemberPath="NewValue"/>
        <DataGridTextColumn Header="Résultat" Binding="{Binding Result}" Width="*" SortMemberPath="Result"/>
      </DataGrid.Columns>
    </DataGrid>

    <!-- Barre d’état -->
    <Border Grid.Row="4" Padding="8" Margin="0,8,0,0" BorderBrush="#374151" BorderThickness="1" Background="#0F172A">
      <DockPanel>
        <TextBlock Text="État :" FontWeight="Bold" Margin="0,0,6,0"/>
        <TextBlock x:Name="TxtStatus" Text="En attente du fichier…" />
      </DockPanel>
    </Border>
  </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$BtnLoad   = $window.FindName("BtnLoad")
$BtnRun    = $window.FindName("BtnRun")
$BtnExport = $window.FindName("BtnExport")
$Grid      = $window.FindName("GridResults")
$TxtStatus = $window.FindName("TxtStatus")
$ChkDryRun = $window.FindName("ChkDryRun")
$TxtSearch = $window.FindName("TxtSearch")
#endregion

#region État global
$global:ProvidedUsers = @()
$Results = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$Grid.ItemsSource = $Results
$TargetValue = 'office365'
#endregion

#region Fonctions
function Set-StatusText {
    param([string]$text)
    $TxtStatus.Text = $text
}

function Read-UserListFromFile {
    param([string]$path)
    $raw = Get-Content -Path $path -ErrorAction Stop
    $clean = $raw | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne '' } | Select-Object -Unique
    return $clean
}

function Ensure-ADModuleOrWarn {
    if (-not (Get-Module -Name ActiveDirectory)) {
        if (-not (Import-ADModule)) {
            Set-StatusText "⚠️ Module ActiveDirectory introuvable."
            return $false
        }
    }
    return $true
}

function Process-Users {
    param([string[]]$Users, [switch]$WhatIfMode)
    if (-not (Ensure-ADModuleOrWarn)) { return }

    $Results.Clear()
    foreach ($u in $Users) {
        try {
            $adUser = Get-ADUser -Filter "SamAccountName -eq '$u'" -Properties msDS-cloudExtensionAttribute20 -ErrorAction Stop
            $old = $adUser.'msDS-cloudExtensionAttribute20'
            if ([string]::IsNullOrWhiteSpace($old)) { $old = '(vide)' }
            $new = ''
            if ($old -eq $TargetValue) {
                $res = "Déjà défini sur $TargetValue"
            } else {
                if ($WhatIfMode) {
                    $new = $TargetValue
                    $res = "Simulation : serait modifié"
                } else {
                    try {
                        Set-ADUser -Identity $adUser.DistinguishedName -Replace @{ 'msDS-cloudExtensionAttribute20' = $TargetValue }
                        $new = $TargetValue
                        $res = "Modifié"
                    } catch {
                        $res = "Erreur: $($_.Exception.Message)"
                    }
                }
            }
            $Results.Add([ResultRow]::new($adUser.SamAccountName, $u, $old, $new, $res))
        } catch {
            $Results.Add([ResultRow]::new('', $u, '(inconnu)', '', "Introuvable ou erreur"))
        }
    }
    $BtnExport.IsEnabled = $true
    Set-StatusText "Traitement terminé."
}

function Filter-Results {
    param([string]$searchText)
    if ([string]::IsNullOrWhiteSpace($searchText)) {
        $Grid.ItemsSource = $Results
    } else {
        $lower = $searchText.ToLower()
        $filtered = $Results | Where-Object {
            $_.SamAccountName.ToLower().Contains($lower) -or
            $_.ProvidedUser.ToLower().Contains($lower) -or
            $_.OldValue.ToLower().Contains($lower) -or
            $_.NewValue.ToLower().Contains($lower) -or
            $_.Result.ToLower().Contains($lower)
        }
        $Grid.ItemsSource = $filtered
    }
}
#endregion

#region Événements
$BtnLoad.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Fichiers texte (*.txt)|*.txt|Tous les fichiers (*.*)|*.*"
    $ofd.Title  = "Sélectionner la liste d'utilisateurs (SamAccountName)"
    $null = [System.Windows.Forms.Application]::EnableVisualStyles()
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $global:ProvidedUsers = Read-UserListFromFile -path $ofd.FileName
        if ($global:ProvidedUsers.Count -gt 0) {
            Set-StatusText "$($global:ProvidedUsers.Count) utilisateur(s) à traiter."
            $BtnRun.IsEnabled = $true
            $BtnExport.IsEnabled = $false
            $Results.Clear()
        } else {
            Set-StatusText "Le fichier est vide."
            $BtnRun.IsEnabled = $false
        }
    }
})

$BtnRun.Add_Click({
    if (-not $global:ProvidedUsers) {
        Set-StatusText "Veuillez charger un fichier."
        return
    }
    Process-Users -Users $global:ProvidedUsers -WhatIfMode:$ChkDryRun.IsChecked
})

$BtnExport.Add_Click({
    if ($Results.Count -eq 0) {
        Set-StatusText "Aucun résultat à exporter."
        return
    }
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "CSV (*.csv)|*.csv"
    $sfd.FileName = "Resultats-msDS-cloudExtensionAttribute20.csv"
    $null = [System.Windows.Forms.Application]::EnableVisualStyles()
    if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $Results | Export-Csv -Path $sfd.FileName -NoTypeInformation -Encoding UTF8
        Set-StatusText "Exporté vers : $($sfd.FileName)"
    }
})

$TxtSearch.Add_TextChanged({
    Filter-Results -searchText $TxtSearch.Text
})
#endregion

#region Lancement
if (-not (Get-Module -Name ActiveDirectory)) { [void](Import-ADModule) }
$window.ShowDialog() | Out-Null
#endregion
