Add-Type -AssemblyName PresentationFramework

function Get-AuthFailures {
    param(
        [string]$AccountName,
        [int]$Hours = 24
    )

    $startTime = (Get-Date).AddHours(-$Hours)

    try {
        # Charger uniquement les 4625 récents
        $filter = @{
            LogName   = 'Security'
            Id        = 4625
            StartTime = $startTime
        }
        $events = Get-WinEvent -FilterHashtable $filter -ErrorAction Stop
    }
    catch {
        [System.Windows.MessageBox]::Show("Impossible de lire le journal Security.`nExécute en Administrateur.", "Erreur", "OK", "Error")
        return @()
    }

    $out = foreach ($evt in $events) {
        $xml = [xml]$evt.ToXml()
        $data = $xml.Event.EventData.Data

        $targetAccount = ($data | Where-Object { $_.Name -eq "TargetUserName" }).'#text'
        $clientAddress = ($data | Where-Object { $_.Name -eq "IpAddress" }).'#text'
        $clientPort    = ($data | Where-Object { $_.Name -eq "IpPort" }).'#text'
        $logonType     = ($data | Where-Object { $_.Name -eq "LogonType" }).'#text'
        $failureReason = ($data | Where-Object { $_.Name -eq "FailureReason" }).'#text'

        if ($targetAccount -and $targetAccount -match $AccountName) {
            [PSCustomObject]@{
                TimeCreated = $evt.TimeCreated
                Account     = $targetAccount
                Source      = $clientAddress
                SourcePort  = $clientPort
                LogonType   = $logonType
                Failure     = $failureReason
                Computer    = $evt.MachineName
            }
        }
    }
    return $out
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Analyse des échecs d’authentification" Height="550" Width="950"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResize">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,10">
            <TextBlock Text="Compte :" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <TextBox x:Name="txtAccount" Width="200" Margin="0,0,10,0"/>
            <TextBlock Text="Heures :" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <TextBox x:Name="txtHours" Width="50" Text="24" Margin="0,0,10,0"/>
            <Button x:Name="btnAnalyze" Content="Analyser" Width="120" Height="30"/>
        </StackPanel>

        <DataGrid x:Name="dgResults" Grid.Row="1" AutoGenerateColumns="True" IsReadOnly="True"
                  CanUserSortColumns="True" CanUserReorderColumns="True" Margin="0,0,0,10"
                  AlternatingRowBackground="LightGray" GridLinesVisibility="All"/>

        <TextBlock Grid.Row="2" Text="Astuce : entrez un compte (ex: bxs_admin) et ajustez la plage d'heures."
                   Foreground="Gray" FontStyle="Italic"/>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

function Find-Control($root, $name) {
    return [System.Windows.LogicalTreeHelper]::FindLogicalNode($root, $name)
}

$txtAccount = Find-Control $Window "txtAccount"
$txtHours   = Find-Control $Window "txtHours"
$btnAnalyze = Find-Control $Window "btnAnalyze"
$dgResults  = Find-Control $Window "dgResults"

$btnAnalyze.Add_Click({
    $acct = $txtAccount.Text.Trim()
    $hours = [int]$txtHours.Text

    if (-not $acct) {
        [System.Windows.MessageBox]::Show("Veuillez entrer un compte.", "Info", "OK", "Information")
        return
    }

    $results = Get-AuthFailures -AccountName $acct -Hours $hours

    if ($results.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Aucun échec trouvé pour $acct dans les $hours dernières heures.", "Résultat", "OK", "Information")
    }
    else {
        $dgResults.ItemsSource = $results
    }
})

$Window.ShowDialog() | Out-Null
