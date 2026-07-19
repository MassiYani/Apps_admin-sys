# ===============================
# Script WPF Scan Comptes Admin
# ===============================

Add-Type -AssemblyName PresentationFramework

# ===============================
# Définition de l’interface XAML
# ===============================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Scan des comptes Admin" Height="600" Width="900" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Ligne 1 : Options -->
        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
            <Label Content="Ordinateur :" VerticalAlignment="Center"/>
            <TextBox x:Name="txtComputer" Width="200" Margin="5,0"/>
            <CheckBox x:Name="chkFilter" Content="Filtrer par compte/nom" Margin="15,0"/>
            <TextBox x:Name="txtFilterInput" Width="150" Margin="5,0" IsEnabled="False"/>
            <Button x:Name="btnScan" Content="Démarrer" Margin="15,0"/>
            <Button x:Name="btnStop" Content="Arrêter" Margin="5,0" IsEnabled="False"/>
            <Button x:Name="btnClear" Content="Effacer" Margin="5,0"/>
            <Button x:Name="btnExport" Content="Exporter CSV" Margin="5,0"/>
            <Button x:Name="btnClose" Content="Fermer" Margin="5,0"/>
        </StackPanel>

        <!-- Ligne 2 : Résultats -->
        <DataGrid x:Name="dgResults" Grid.Row="1" AutoGenerateColumns="True" IsReadOnly="True" Margin="0,0,0,10"/>

        <!-- Ligne 3 : Statut -->
        <StackPanel Grid.Row="2" Orientation="Horizontal">
            <Label x:Name="lblStatus" Content="Prêt." VerticalAlignment="Center"/>
            <ProgressBar x:Name="pb" Width="200" Height="15" Margin="20,0" Minimum="0" Maximum="100"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Charger le XAML en WPF
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# ===============================
# Associer les contrôles
# ===============================
$ns = New-Object System.Xml.XmlNamespaceManager($xaml.NameTable)
$ns.AddNamespace("x", "http://schemas.microsoft.com/winfx/2006/xaml")

$controls = $xaml.SelectNodes("//*[@x:Name]", $ns)
foreach ($c in $controls) {
    Set-Variable -Name $c.Name -Value $Window.FindName($c.Name) -Scope Global
}

# ===============================
# Variables globales
# ===============================
$global:Results = @()

function Add-Result {
    param($Category,$Name,$Account,$Computer,$Extra)
    $obj = [PSCustomObject]@{
        Category = $Category
        Name     = $Name
        Account  = $Account
        Computer = $Computer
        Extra    = $Extra
    }
    $global:Results += $obj
    $dgResults.ItemsSource = $null
    $dgResults.ItemsSource = $global:Results
}

function Clear-Results {
    $global:Results = @()
    $dgResults.ItemsSource = $null
}

# ===============================
# Logique du scan
# ===============================
function Start-Scan {
    param($Computer,$Filter)

    Clear-Results
    $lblStatus.Content = "Scan en cours sur $Computer..."
    $pb.Value = 20

    try {
        # Services
        $services = Get-CimInstance Win32_Service -ComputerName $Computer -ErrorAction SilentlyContinue
        if ($Filter) {
            $services = $services | Where-Object { $_.Name -like "*$Filter*" -or $_.StartName -like "*$Filter*" }
        }
        foreach ($s in $services) {
            Add-Result -Category "Service" -Name $s.Name -Account $s.StartName -Computer $Computer -Extra $s.State
        }
        $pb.Value = 40

        # Tâches planifiées
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue
        if ($Filter) {
            $tasks = $tasks | Where-Object { $_.TaskName -like "*$Filter*" -or $_.Principal.UserId -like "*$Filter*" }
        }
        foreach ($t in $tasks) {
            Add-Result -Category "Tâche" -Name $t.TaskName -Account $t.Principal.UserId -Computer $Computer -Extra $t.State
        }
        $pb.Value = 60

        # Credentials stockés
        $creds = cmdkey.exe /list 2>$null
        foreach ($line in $creds) {
            if ($line -match "Cible\s*:\s*(.+)") {
                $target = $matches[1]
                if (-not $Filter -or $target -like "*$Filter*") {
                    Add-Result -Category "Credential" -Name $target -Account "" -Computer $Computer -Extra "Stocké"
                }
            }
        }
        $pb.Value = 80

        # Pools IIS (si module dispo)
        if (Get-Module -ListAvailable -Name WebAdministration) {
            Import-Module WebAdministration
            $pools = Get-ChildItem IIS:\AppPools
            if ($Filter) {
                $pools = $pools | Where-Object { $_.Name -like "*$Filter*" -or $_.processModel.userName -like "*$Filter*" }
            }
            foreach ($p in $pools) {
                Add-Result -Category "IIS Pool" -Name $p.Name -Account $p.processModel.userName -Computer $Computer -Extra $p.state
            }
        }

        $lblStatus.Content = "Scan terminé : $($global:Results.Count) éléments trouvés."
        $pb.Value = 100
    }
    catch {
        $lblStatus.Content = "Erreur : $_"
    }
    finally {
        $btnScan.IsEnabled = $true
        $btnStop.IsEnabled = $false
    }
}

# ===============================
# Gestion des événements
# ===============================
$chkFilter.Add_Checked({ $txtFilterInput.IsEnabled = $true })
$chkFilter.Add_Unchecked({ $txtFilterInput.IsEnabled = $false })

$btnScan.Add_Click({
    $target = $txtComputer.Text.Trim()
    if (-not $target) {
        [System.Windows.MessageBox]::Show("Veuillez entrer un nom/IP d'ordinateur.","Erreur",
            [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning)
        return
    }
    $filter = if ($chkFilter.IsChecked) { $txtFilterInput.Text.Trim() } else { "" }

    $btnScan.IsEnabled = $false
    $btnStop.IsEnabled = $true
    $pb.Value = 10

    Start-Scan -Computer $target -Filter $filter
})

$btnStop.Add_Click({
    $btnScan.IsEnabled = $true
    $btnStop.IsEnabled = $false
    $lblStatus.Content = "Scan interrompu par l'utilisateur."
})

$btnClear.Add_Click({ Clear-Results; $lblStatus.Content = "Résultats effacés." })

$btnExport.Add_Click({
    if ($global:Results.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Aucun résultat à exporter.","Info",
            [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information)
        return
    }
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = "CSV Files|*.csv"
    $dlg.FileName = "scan-result-$(Get-Date -Format yyyyMMdd-HHmmss).csv"
    if ($dlg.ShowDialog() -eq $true) {
        $global:Results | Export-Csv -Path $dlg.FileName -NoTypeInformation -Encoding UTF8
        [System.Windows.MessageBox]::Show("Exporté vers $($dlg.FileName)","Export",
            [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information)
    }
})

$btnClose.Add_Click({ $Window.Close() })

# ===============================
# Lancer l'interface
# ===============================
$Window.ShowDialog() | Out-Null
