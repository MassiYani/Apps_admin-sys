[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$User,

    [Parameter(Mandatory = $false)]
    [string]$Password,

    [Parameter(Mandatory = $false)]
    [string]$ParamsJson
)

$OutputEncoding = [System.Text.Encoding]::UTF8

$params = if (-not [string]::IsNullOrEmpty($ParamsJson)) {
    $ParamsJson | ConvertFrom-Json
} else {
    @{ }
}

# Définit la logique principale dans un bloc de script pour l'impersonation
$scriptBlock = {
    param($Path, $Action, $params)

    switch ($Action) {
        'audit' {
            if (-not $params.auditUser) {
                throw "Le nom d'utilisateur ou de groupe pour l'audit est requis."
            }
            $auditIdentity = $params.auditUser
            
            try {
                $acl = Get-Acl -Path $Path -ErrorAction Stop
                # Filtre les règles d'accès pour l'identité spécifiée
                $accessRules = $acl.Access | Where-Object { $_.IdentityReference.Value -like "*\$auditIdentity" -or $_.IdentityReference.Value -eq $auditIdentity }
                
                if ($accessRules) {
                    $accessRules | Select-Object @{N='Identity';E={$_.IdentityReference.Value}}, 
                                                @{N='Rights';E={$_.FileSystemRights.ToString()}}, 
                                                @{N='Type';E={$_.AccessControlType.ToString()}}, 
                                                IsInherited
                } else {
                    # Retourne un tableau vide si aucune règle n'est trouvée
                    return @() 
                }
            } catch {
                throw "Impossible d'accéder au chemin '$Path'. Erreur: $($_.Exception.Message)"
            }
        }
        'scan' {
            try {
                $subFolders = Get-ChildItem -Path $Path -Directory -ErrorAction Stop
                $folderScan = foreach ($folder in $subFolders) {
                    $size = Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
                    [PSCustomObject]@{
                        Name = $folder.Name
                        SizeGB = [math]::Round($size.Sum / 1GB, 2)
                        LastWrite = $folder.LastWriteTime
                    }
                }
                # Trie par taille décroissante
                return $folderScan | Sort-Object -Property SizeGB -Descending
            } catch {
                throw "Impossible d'analyser le chemin '$Path'. Erreur: $($_.Exception.Message)"
            }
        }
        default {
            throw "Action '$Action' non reconnue."
        }
    }
}

try {
    if ($User -and $Password) {
        $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($User, $securePassword)
        Invoke-Command -ComputerName localhost -Credential $credential -ScriptBlock $scriptBlock -ArgumentList $Path, $Action, $params | ConvertTo-Json -Depth 3
    } else {
        & $scriptBlock -Path $Path -Action $Action -params $params | ConvertTo-Json -Depth 3
    }
} catch {
    Write-Error "Erreur globale dans le script NAS: $($_.Exception.Message)"
    exit 1
}