# Requires: PowerShell 7.x
# VERSION PRO+ - Gestion robuste des sessions RDP avec protections avancées

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Gestion PRO+ des sessions RDP"
$form.Size = New-Object System.Drawing.Size(1150,650)
$form.StartPosition = "CenterScreen"

# Champs serveurs
$labelServer = New-Object System.Windows.Forms.Label
$labelServer.Text = "Serveurs :"
$labelServer.Location = "10,15"
$form.Controls.Add($labelServer)

$textServer = New-Object System.Windows.Forms.TextBox
$textServer.Location = "100,10"
$textServer.Size = "400,20"
$textServer.Text = "localhost"
$form.Controls.Add($textServer)

# Filtre utilisateur
$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = "520,10"
$txtSearch.Size = "200,20"
$txtSearch.PlaceholderText = "Filtrer..."
$form.Controls.Add($txtSearch)

# Bouton refresh
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Actualiser"
$btnRefresh.Location = "740,8"
$form.Controls.Add($btnRefresh)

# Tableau
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = "10,40"
$listView.Size = "1110,450"
$listView.View = "Details"
$listView.FullRowSelect = $true
$listView.MultiSelect = $true

$listView.Columns.Add("Serveur",120)
$listView.Columns.Add("Session",150)
$listView.Columns.Add("Utilisateur",150)
$listView.Columns.Add("ID",60)
$listView.Columns.Add("Etat",100)
$listView.Columns.Add("Idle",100)

$form.Controls.Add($listView)

# Boutons
$btnLogoff = New-Object System.Windows.Forms.Button
$btnLogoff.Text = "Déconnecter sécurisé"
$btnLogoff.Location = "10,510"
$form.Controls.Add($btnLogoff)

$btnClean = New-Object System.Windows.Forms.Button
$btnClean.Text = "Nettoyer sessions fantômes"
$btnClean.Location = "180,510"
$form.Controls.Add($btnClean)

$btnMsg = New-Object System.Windows.Forms.Button
$btnMsg.Text = "Envoyer message"
$btnMsg.Location = "380,510"
$form.Controls.Add($btnMsg)

# Message personnalisé
$txtMessage = New-Object System.Windows.Forms.TextBox
$txtMessage.Location = "550,510"
$txtMessage.Size = "400,40"
$txtMessage.Multiline = $true
$txtMessage.Text = "Message admin..."
$form.Controls.Add($txtMessage)

# Fonction récupération sessions
function Get-Sessions {
    param($server)
    try { return cmd /c "query session /server:$server" 2>$null } catch { return @() }
}

# Parser
function Parse-Sessions {
    $listView.Items.Clear()
    $servers = $textServer.Text -split ","

    foreach ($srv in $servers) {
        $srv = $srv.Trim()
        if ($srv -eq "") { continue }

        $lines = Get-Sessions $srv
        if ($lines.Count -lt 2) { continue }

        foreach ($line in $lines[1..($lines.Count-1)]) {
            $line = $line -replace "^\s+",""
            $parts = $line -split "\s+"

            if ($parts.Count -ge 4) {
                $session = $parts[0]
                $user = $parts[1]
                $id = $parts[2]
                $state = $parts[3]
                $idle = if ($parts.Count -ge 5) { $parts[4] } else { "" }

                if ($txtSearch.Text -and ($user -notlike "*$($txtSearch.Text)*")) { continue }

                $item = New-Object System.Windows.Forms.ListViewItem($srv)
                $item.SubItems.Add($session) | Out-Null
                $item.SubItems.Add($user) | Out-Null
                $item.SubItems.Add($id) | Out-Null
                $item.SubItems.Add($state) | Out-Null
                $item.SubItems.Add($idle) | Out-Null

                $listView.Items.Add($item) | Out-Null
            }
        }
    }
}

# Déconnexion sécurisée (avec délai + vérification)
$btnLogoff.Add_Click({
    foreach ($item in $listView.SelectedItems) {
        $srv = $item.SubItems[0].Text
        $id = $item.SubItems[3].Text

        cmd /c "logoff $id /server:$srv"
        Start-Sleep -Seconds 2

        # Vérification si session existe encore
        $check = (cmd /c "query session /server:$srv") -match "\s$id\s"
        if ($check) {
            cmd /c "rwinsta $id /server:$srv"
        }
    }
    Parse-Sessions
})

# Nettoyage sessions fantômes
$btnClean.Add_Click({
    foreach ($item in $listView.Items) {
        if ($item.SubItems[4].Text -eq "Disc") {
            $srv = $item.SubItems[0].Text
            $id = $item.SubItems[3].Text
            cmd /c "rwinsta $id /server:$srv"
            Start-Sleep -Milliseconds 800
        }
    }
    Parse-Sessions
})

# Message personnalisé
$btnMsg.Add_Click({
    $msg = $txtMessage.Text
    foreach ($item in $listView.SelectedItems) {
        $srv = $item.SubItems[0].Text
        $user = $item.SubItems[2].Text
        cmd /c "msg $user /server:$srv $msg"
    }
})

# Refresh + filtre
$btnRefresh.Add_Click({ Parse-Sessions })
$txtSearch.Add_TextChanged({ Parse-Sessions })

$form.Add_Shown({$form.Activate(); Parse-Sessions})
[void]$form.ShowDialog()
