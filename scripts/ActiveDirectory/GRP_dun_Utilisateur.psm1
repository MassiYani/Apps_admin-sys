Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Windows.Forms

# Vérifie si module AD dispo
$UseADModule = $false
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    $UseADModule = $true
}

# =======================
# UI XAML (ne pas caster en [xml] !!!)
# =======================
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Groupes d'un utilisateur AD" Height="400" Width="700" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,8">
            <Label Content="Utilisateur (sAMAccountName ou UPN) :" VerticalAlignment="Center"/>
            <TextBox x:Name="txtUser" Width="250" Margin="5,0,5,0"/>
            <Button x:Name="btnCheck" Content="Lister Groupes" Width="120" Margin="0,0,5,0"/>
            <Button x:Name="btnExport" Content="Exporter CSV" Width="120" IsEnabled="False"/>
        </StackPanel>

        <DataGrid x:Name="dgGroups" Grid.Row="1" AutoGenerateColumns="True" CanUserSortColumns="True" IsReadOnly="True"/>

        <Label x:Name="lblStatus" Grid.Row="2" Content="Prêt" HorizontalAlignment="Left" VerticalAlignment="Center"/>
    </Grid>
</Window>
"@

# Charger le XAML correctement
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Récupération des contrôles
$txtUser   = $Window.FindName("txtUser")
$btnCheck  = $Window.FindName("btnCheck")
$btnExport = $Window.FindName("btnExport")
$dgGroups  = $Window.FindName("dgGroups")
$lblStatus = $Window.FindName("lblStatus")

# =======================
# Fonctions
# =======================
function Get-UserGroups {
    param([string]$User)

    if ($UseADModule) {
        try {
            $u = Get-ADUser -Identity $User -ErrorAction Stop
            $groups = Get-ADPrincipalGroupMembership -Identity $u | 
                      Select-Object -Property Name, SamAccountName, DistinguishedName
            return $groups
        } catch {
            [System.Windows.MessageBox]::Show("Utilisateur introuvable ou erreur AD : $_","Erreur","OK","Error") | Out-Null
            return @()
        }
    } else {
        try {
            $searcher = New-Object DirectoryServices.DirectorySearcher
            $searcher.Filter = "(&(objectCategory=person)(|(sAMAccountName=$User)(userPrincipalName=$User)))"
            $searcher.PropertiesToLoad.Add("memberOf") | Out-Null
            $result = $searcher.FindOne()
            if (-not $result) { return @() }

            $groups = @()
            foreach ($dn in $result.Properties["memberOf"]) {
                $cn = ($dn -split ",")[0] -replace "^CN="
                $groups += [PSCustomObject]@{
                    Name              = $cn
                    SamAccountName    = $cn
                    DistinguishedName = $dn
                }
            }
            return $groups
        } catch {
            [System.Windows.MessageBox]::Show("Erreur LDAP : $_","Erreur","OK","Error") | Out-Null
            return @()
        }
    }
}

# =======================
# Événements UI
# =======================
$btnCheck.Add_Click({
    $user = $txtUser.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($user)) {
        [System.Windows.MessageBox]::Show("Veuillez entrer un identifiant utilisateur.","Erreur","OK","Error") | Out-Null
        return
    }

    $lblStatus.Content = "Recherche..."
    $groups = Get-UserGroups -User $user

    if ($groups.Count -eq 0) {
        $lblStatus.Content = "Aucun groupe trouvé"
        $btnExport.IsEnabled = $false
    } else {
        $dgGroups.ItemsSource = $null
        $dgGroups.ItemsSource = $groups
        $lblStatus.Content = "$($groups.Count) groupes trouvés"
        $btnExport.IsEnabled = $true
    }
})

$btnExport.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "CSV UTF-8|*.csv"
    if ($sfd.ShowDialog() -eq "OK") {
        $dgGroups.ItemsSource | Export-Csv -Path $sfd.FileName -NoTypeInformation -Encoding UTF8 -Delimiter ";"
        [System.Windows.MessageBox]::Show("Export effectué : $($sfd.FileName)","Export","OK","Information") | Out-Null
    }
})

# =======================
# Lancer UI
# =======================
$Window.ShowDialog() | Out-Null
