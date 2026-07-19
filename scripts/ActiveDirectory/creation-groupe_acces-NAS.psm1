# Bouton 2 : Créer groupes d'accès GRPG / GRPL
$button2 = New-Object System.Windows.Forms.Button
$button2.Location = New-Object System.Drawing.Point(50, 120)
$button2.Text = "2. Création des groupes d'accès"
$button2.Font = $buttonStyle.Font
$button2.ForeColor = $buttonStyle.ForeColor
$button2.BackColor = $buttonStyle.BackColor
$button2.FlatStyle = $buttonStyle.FlatStyle
$button2.Size = $buttonStyle.Size

$button2.Add_Click({
    # ───────────────────────────────────────────────
    # Fenêtre principale
    # ───────────────────────────────────────────────
    $formGrp = New-Object System.Windows.Forms.Form
    $formGrp.Text = "Création groupes GRPG / GRPL"
    $formGrp.Size = New-Object System.Drawing.Size(580, 240)
    $formGrp.StartPosition = "CenterScreen"
    $formGrp.FormBorderStyle = "FixedDialog"
    $formGrp.MaximizeBox = $false

    # OU de base
    $lblOU = New-Object System.Windows.Forms.Label
    $lblOU.Text = "OU de base (doit contenir GLOBAL et LOCAL) :"
    $lblOU.Location = New-Object System.Drawing.Point(12, 15)
    $lblOU.AutoSize = $true
    $formGrp.Controls.Add($lblOU)

    $tbOU = New-Object System.Windows.Forms.TextBox
    $tbOU.Location = New-Object System.Drawing.Point(12, 38)
    $tbOU.Size = New-Object System.Drawing.Size(420, 22)
    $tbOU.ReadOnly = $true
    $formGrp.Controls.Add($tbOU)

    $btnBrowseOU = New-Object System.Windows.Forms.Button
    $btnBrowseOU.Text = "Choisir OU"
    $btnBrowseOU.Location = New-Object System.Drawing.Point(440, 37)
    $btnBrowseOU.Size = New-Object System.Drawing.Size(100, 26)
    $formGrp.Controls.Add($btnBrowseOU)

    # Groupe(s) à créer
    $lblGroup = New-Object System.Windows.Forms.Label
    $lblGroup.Text = "Nom du groupe ou fichier .txt (Ex: GRPG_X) :"
    $lblGroup.Location = New-Object System.Drawing.Point(12, 75)
    $lblGroup.AutoSize = $true
    $formGrp.Controls.Add($lblGroup)

    $tbGroupInput = New-Object System.Windows.Forms.TextBox
    $tbGroupInput.Location = New-Object System.Drawing.Point(12, 98)
    $tbGroupInput.Size = New-Object System.Drawing.Size(420, 22)
    $tbGroupInput.Text = "GRPG_"
    $formGrp.Controls.Add($tbGroupInput)

    $btnImportFile = New-Object System.Windows.Forms.Button
    $btnImportFile.Text = "Importer .txt"
    $btnImportFile.Location = New-Object System.Drawing.Point(440, 97)
    $btnImportFile.Size = New-Object System.Drawing.Size(100, 26)
    $formGrp.Controls.Add($btnImportFile)

    # Bouton Créer
    $btnCreate = New-Object System.Windows.Forms.Button
    $btnCreate.Text = "Créer groupe(s)"
    $btnCreate.Location = New-Object System.Drawing.Point(200, 150)
    $btnCreate.Size = New-Object System.Drawing.Size(120, 30)
    $btnCreate.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $formGrp.Controls.Add($btnCreate)

    # ───────────────────────────────────────────────
    # Sélecteur OU avec DOUBLE-CLIC pour valider
    # ───────────────────────────────────────────────
    $btnBrowseOU.Add_Click({
        $ouSelector = New-Object System.Windows.Forms.Form
        $ouSelector.Text = "Sélectionner l'OU de base"
        $ouSelector.Size = New-Object System.Drawing.Size(520, 580)
        $ouSelector.StartPosition = "CenterParent"

        $tree = New-Object System.Windows.Forms.TreeView
        $tree.Dock = "Fill"
        $ouSelector.Controls.Add($tree)

        function Load-Children($node) {
            if ($node.Nodes.Count -eq 1 -and $node.Nodes[0].Text -eq "…") {
                $node.Nodes.Clear()
                Get-ADOrganizationalUnit -SearchBase $node.Tag -SearchScope OneLevel -Filter * |
                    Sort-Object Name |
                    ForEach-Object {
                        $child = New-Object System.Windows.Forms.TreeNode
                        $child.Text = $_.Name
                        $child.Tag  = $_.DistinguishedName
                        $child.Nodes.Add("…") | Out-Null
                        $node.Nodes.Add($child) | Out-Null
                    }
            }
        }

        @(
            "OU=Bejaia,DC=cevital,DC=com",
            "OU=Cojek,DC=cevital,DC=com",
            "OU=Lalla Khedidja,DC=cevital,DC=com"
        ) | ForEach-Object {
            try {
                $ou = Get-ADOrganizationalUnit -Identity $_
                $root = New-Object System.Windows.Forms.TreeNode
                $root.Text = $ou.Name
                $root.Tag  = $ou.DistinguishedName
                $root.Nodes.Add("…") | Out-Null
                $tree.Nodes.Add($root) | Out-Null
            } catch {}
        }

        $tree.Add_BeforeExpand({ Load-Children $_.Node })

        # DOUBLE-CLIC = sélection + fermeture immédiate
        $tree.Add_NodeMouseDoubleClick({
            if ($_.Node.Tag) {
                $tbOU.Text = $_.Node.Tag
                $ouSelector.Close()
            }
        })

        # Bouton Valider (facultatif)
        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text = "Valider"
        $btnOK.Location = New-Object System.Drawing.Point(200, 510)
        $btnOK.Size = New-Object System.Drawing.Size(100, 35)
        $btnOK.Add_Click({
            if ($tree.SelectedNode -and $tree.SelectedNode.Tag) {
                $tbOU.Text = $tree.SelectedNode.Tag
            }
            $ouSelector.Close()
        })
        $ouSelector.Controls.Add($btnOK)

        $ouSelector.ShowDialog() | Out-Null
    })

    # Importer fichier
    $btnImportFile.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "Fichiers texte (*.txt)|*.txt"
        if ($ofd.ShowDialog() -eq "OK") {
            $tbGroupInput.Text = $ofd.FileName
        }
    })

    # ───────────────────────────────────────────────
    # Création + affichage séparé Global / Local
    # ───────────────────────────────────────────────
    $btnCreate.Add_Click({
        if ([string]::IsNullOrWhiteSpace($tbOU.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Sélectionnez une OU de base.", "Erreur", "OK", "Error")
            return
        }

        $input = $tbGroupInput.Text.Trim()
        $groupsToCreate = @()

        if (Test-Path $input -PathType Leaf) {
            $groupsToCreate = Get-Content $input -Encoding UTF8 |
                              ForEach-Object { $_.Trim() } |
                              Where-Object { $_ -and $_ -match '^GRPG_' }
        }
        elseif ($input -match '^GRPG_') {
            $groupsToCreate = @($input)
        }

        if ($groupsToCreate.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Aucun groupe valide (doit commencer par GRPG_).", "Information")
            return
        }

        $globalCreated  = @()
        $localCreated   = @()
        $alreadyExist   = @()
        $errors         = @()

        foreach ($grpPrefix in $groupsToCreate) {
            $baseName = $grpPrefix -replace '^GRPG_', ''

            $ouGlobal = Get-ADOrganizationalUnit -Filter 'Name -eq "GLOBAL"' -SearchBase $tbOU.Text -SearchScope OneLevel -EA SilentlyContinue
            $ouLocal  = Get-ADOrganizationalUnit -Filter 'Name -eq "LOCAL"'  -SearchBase $tbOU.Text -SearchScope OneLevel -EA SilentlyContinue

            if (-not $ouGlobal -or -not $ouLocal) {
                $errors += "$grpPrefix → OU GLOBAL ou LOCAL introuvable"
                continue
            }

            $definitions = @(
                @{Name="GRPG_${baseName}_L";   Scope="Global";      Path=$ouGlobal.DistinguishedName; Type="Global"}
                @{Name="GRPG_${baseName}_E";   Scope="Global";      Path=$ouGlobal.DistinguishedName; Type="Global"}
                @{Name="GRPL_R_${baseName}";   Scope="DomainLocal"; Path=$ouLocal.DistinguishedName;  Type="Local"}
                @{Name="GRPL_RW_${baseName}";  Scope="DomainLocal"; Path=$ouLocal.DistinguishedName;  Type="Local"}
            )

            foreach ($def in $definitions) {
                $gName = $def.Name

                if (Get-ADGroup -Filter "Name -eq '$gName'" -EA SilentlyContinue) {
                    $alreadyExist += $gName
                    continue
                }

                try {
                    New-ADGroup -Name $gName `
                                -GroupScope $def.Scope `
                                -GroupCategory Security `
                                -Path $def.Path `
                                -Description "Groupe accès $baseName ($($def.Scope))" `
                                -ErrorAction Stop

                    if ($def.Type -eq "Global") {
                        $globalCreated += $gName
                    } else {
                        $localCreated += $gName
                    }
                }
                catch {
                    $errors += "$gName → $($_.Exception.Message)"
                }
            }

            # Liaison membres
            try {
                Add-ADGroupMember -Identity "GRPL_R_${baseName}"  -Members "GRPG_${baseName}_L"  -EA SilentlyContinue
                Add-ADGroupMember -Identity "GRPL_RW_${baseName}" -Members "GRPG_${baseName}_E"  -EA SilentlyContinue
            }
            catch {
                $errors += "Liaison membres $baseName → $($_.Exception.Message)"
            }
        }

        # ───────────────────────────────────────────────
        # Affichage clair : Global / Local séparés
        # ───────────────────────────────────────────────
        $resultsBox.Clear()

        # Groupe(s) Global créé(s)
        if ($globalCreated.Count -gt 0) {
            $resultsBox.SelectionColor = [System.Drawing.Color]::DarkBlue
            $resultsBox.SelectionFont  = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("Groupes GLOBAUX créés ($($globalCreated.Count))`n")
            $resultsBox.SelectionColor = [System.Drawing.Color]::Black
            $resultsBox.SelectionFont  = New-Object System.Drawing.Font("Consolas", 9)
            $globalCreated | Sort | ForEach-Object { $resultsBox.AppendText("  • $_`n") }
            $resultsBox.AppendText("`n")
        }

        # Groupe(s) Local créé(s)
        if ($localCreated.Count -gt 0) {
            $resultsBox.SelectionColor = [System.Drawing.Color]::DarkGreen
            $resultsBox.SelectionFont  = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $resultsBox.AppendText("Groupes LOCAUX créés ($($localCreated.Count))`n")
            $resultsBox.SelectionColor = [System.Drawing.Color]::Black
            $resultsBox.SelectionFont  = New-Object System.Drawing.Font("Consolas", 9)
            $localCreated | Sort | ForEach-Object { $resultsBox.AppendText("  • $_`n") }
            $resultsBox.AppendText("`n")
        }

        # Déjà existants
        if ($alreadyExist.Count -gt 0) {
            $resultsBox.SelectionColor = [System.Drawing.Color]::DarkOrange
            $resultsBox.AppendText("Groupes DÉJÀ EXISTANTS ($($alreadyExist.Count))`n")
            $resultsBox.SelectionColor = [System.Drawing.Color]::Black
            $alreadyExist | Sort | ForEach-Object { $resultsBox.AppendText("  • $_`n") }
            $resultsBox.AppendText("`n")
        }

        # Erreurs
        if ($errors.Count -gt 0) {
            $resultsBox.SelectionColor = [System.Drawing.Color]::Red
            $resultsBox.AppendText("ERREURS ($($errors.Count))`n")
            $resultsBox.SelectionColor = [System.Drawing.Color]::DarkRed
            $errors | ForEach-Object { $resultsBox.AppendText("  • $_`n") }
        }

        if ($globalCreated.Count -eq 0 -and $localCreated.Count -eq 0 -and $alreadyExist.Count -eq 0 -and $errors.Count -eq 0) {
            $resultsBox.SelectionColor = [System.Drawing.Color]::Gray
            $resultsBox.AppendText("Aucun groupe traité.`n")
        }

        $formGrp.Close()
    })

    $formGrp.ShowDialog() | Out-Null
})

$form.Controls.Add($button2)

