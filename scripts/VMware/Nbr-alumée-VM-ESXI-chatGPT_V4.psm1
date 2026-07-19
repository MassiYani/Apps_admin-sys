# Changer la variable $host → $esxiHost pour éviter le conflit
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Update-Output {
    param([string]$message)
    $outputBox.AppendText("$message`r`n")
    $outputBox.ScrollToCaret()
}

function Write-ColoredLine {
    param(
        [string]$text,
        [System.Drawing.Color]$color
    )
    $start = $outputBox.TextLength
    $outputBox.AppendText("$text`r`n")
    $end = $outputBox.TextLength

    $outputBox.Select($start, $end - $start)
    $outputBox.SelectionColor = $color
    $outputBox.SelectionLength = 0
    $outputBox.ScrollToCaret()
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Connexion ESXi et Affichage Infos"
$form.Size = New-Object System.Drawing.Size(600, 600)

$labelHost = New-Object System.Windows.Forms.Label
$labelHost.Text = "Adresse IP/Hostname ESXi:"
$labelHost.Location = New-Object System.Drawing.Point(10, 20)
$labelHost.AutoSize = $true
$form.Controls.Add($labelHost)

$textHost = New-Object System.Windows.Forms.TextBox
$textHost.Location = New-Object System.Drawing.Point(200, 20)
$textHost.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textHost)

$labelUser = New-Object System.Windows.Forms.Label
$labelUser.Text = "Nom d'utilisateur:"
$labelUser.Location = New-Object System.Drawing.Point(10, 60)
$labelUser.AutoSize = $true
$form.Controls.Add($labelUser)

$textUser = New-Object System.Windows.Forms.TextBox
$textUser.Location = New-Object System.Drawing.Point(200, 60)
$textUser.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textUser)

$labelPass = New-Object System.Windows.Forms.Label
$labelPass.Text = "Mot de passe:"
$labelPass.Location = New-Object System.Drawing.Point(10, 100)
$labelPass.AutoSize = $true
$form.Controls.Add($labelPass)

$textPass = New-Object System.Windows.Forms.MaskedTextBox
$textPass.Location = New-Object System.Drawing.Point(200, 100)
$textPass.Size = New-Object System.Drawing.Size(200, 20)
$textPass.UseSystemPasswordChar = $true
$form.Controls.Add($textPass)

$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(10, 180)
$outputBox.Size = New-Object System.Drawing.Size(560, 350)
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Connexion"
$button.Location = New-Object System.Drawing.Point(200, 140)
$button.Add_Click({
    $outputBox.Clear()
    $esxiHost = $textHost.Text
    $user = $textUser.Text
    $pass = $textPass.Text | ConvertTo-SecureString -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential ($user, $pass)

    try {
        Write-ColoredLine "Connexion à $esxiHost..." ([System.Drawing.Color]::Blue)
        Connect-VIServer -Server $esxiHost -Credential $creds -Force -ErrorAction Stop
        Write-ColoredLine "Connexion réussie à $esxiHost." ([System.Drawing.Color]::Green)

        $vms = Get-VM
        $onCount = 0
        $offCount = 0

        foreach ($vm in $vms) {
            $state = $vm.PowerState
            if ($state -eq "PoweredOn") {
                Write-ColoredLine "Nom: $($vm.Name) - État: ON" ([System.Drawing.Color]::Green)
                $onCount++
            } else {
                Write-ColoredLine "Nom: $($vm.Name) - État: DOWN" ([System.Drawing.Color]::Red)
                $offCount++
            }

            Update-Output "   CPU: $($vm.NumCpu), RAM: $($vm.MemoryMB)MB"
        }

        Write-ColoredLine "`nRésumé des états des VMs:" ([System.Drawing.Color]::Black)
        Write-ColoredLine "   Total ON : $onCount" ([System.Drawing.Color]::Green)
        Write-ColoredLine "   Total DOWN : $offCount" ([System.Drawing.Color]::Red)

    } catch {
        Write-ColoredLine "Erreur : $_" ([System.Drawing.Color]::Red)
    }
})
$form.Controls.Add($button)

[void]$form.ShowDialog()
