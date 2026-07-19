#Requires -Modules VMware.PowerCLI
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$VIHost,

    [Parameter(Mandatory = $true)]
    [string]$User,

    [Parameter(Mandatory = $true)]
    [string]$Password
)

# S'assurer que la sortie est en UTF-8, ce qui est la norme pour les API JSON.
$OutputEncoding = [System.Text.Encoding]::UTF8

# Ignorer les avertissements de certificat invalide pour les environnements de test/lab.
# En production, il est recommandé de gérer les certificats correctement.
try {
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope Session | Out-Null
}
catch {
    # Ignorer si la configuration ne peut pas être définie (par ex. permissions)
}

$connection = $null
$output = @{}

try {
    # Connexion au serveur vCenter ou ESXi
    $connection = Connect-VIServer -Server $VIHost -User $User -Password $Password -ErrorAction Stop
    
    if ($connection) {
        # Récupérer les informations de base de l'hôte (on prend le premier si connecté à un vCenter)
        $esxiHost = Get-VMHost -Server $connection | Select-Object -First 1
        
        # Récupérer les informations sur les VMs avec des valeurs arrondies
        $vms = Get-VM -Server $connection | Select-Object Name, PowerState, NumCpu, @{N="MemoryGB";E={[math]::Round($_.MemoryGB, 1)}}, @{N="UsedSpaceGB";E={[math]::Round($_.UsedSpaceGB, 1)}}, @{N="ProvisionedSpaceGB";E={[math]::Round($_.ProvisionedSpaceGB, 1)}}
        
        $output = @{
            Status = "Connecté"
            HostInfo = @{
                Name = $esxiHost.Name; Version = $esxiHost.Version; Build = $esxiHost.Build; CpuModel = $esxiHost.CpuModel;
                NumCpuCores = $esxiHost.NumCpu; MemoryTotalGB = [math]::Round($esxiHost.MemoryTotalGB, 2); MemoryUsageGB = [math]::Round($esxiHost.MemoryUsageGB, 2);
            }
            VMs = @($vms)
        }
    }
}
catch {
    # En cas d'erreur, renvoyer un message et un code de sortie non nul pour que le backend le détecte.
    Write-Error "Échec de la connexion ou de la récupération des données. Message : $($_.Exception.Message)"
    exit 1
}
finally {
    # Déconnexion propre dans tous les cas
    if ($connection) {
        Disconnect-VIServer -Server $connection -Confirm:$false -Force | Out-Null
    }
}

# Convertir la sortie en JSON et l'envoyer au stdout
$output | ConvertTo-Json -Depth 5