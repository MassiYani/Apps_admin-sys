#Requires -Modules Exchange.Management
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string[]]$Servers,

    [Parameter(Mandatory = $true)]
    [string]$User,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [Parameter(Mandatory = $false)]
    [string]$ParamsJson
)

# S'assurer que la sortie est en UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Convertir le JSON des paramètres en objet PowerShell
$params = if (-not [string]::IsNullOrEmpty($ParamsJson)) {
    $ParamsJson | ConvertFrom-Json
} else {
    @{ }
}

# Fonction pour créer et gérer la session distante
function Invoke-ExchangeCommand {
    param(
        [scriptblock]$ScriptBlock
    )
    
    $allResults = @()
    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($User, $securePassword)

    foreach ($server in $Servers) {
        $session = $null
        try {
            $sessionOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
            $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$server/PowerShell/" -Authentication Kerberos -Credential $credential -SessionOption $sessionOptions -ErrorAction Stop
            
            # Invoquer la commande et ajouter le nom du serveur aux résultats
            $results = Invoke-Command -Session $session -ScriptBlock $ScriptBlock
            if ($results) {
                $resultsWithServer = $results | Select-Object *, @{Name = 'ExchangeServer'; Expression = { $server } }
                $allResults += $resultsWithServer
            }
        }
        catch {
            Write-Error "Erreur de connexion à '$server': $($_.Exception.Message)"
            # On ne sort pas, on continue avec le serveur suivant pour tenter de se connecter aux autres
        }
        finally {
            if ($session -ne $null) {
                Remove-PSSession -Session $session
            }
        }
    }
    return $allResults
}

try {
    $finalOutput = switch ($Action) {
        'track' {
            $scriptBlock = {
                $trackingParams = @{ ResultSize = '500'; Start = (Get-Date).AddDays(-1); End = (Get-Date) }
                if ($using:params.sender) { $trackingParams.Sender = $using:params.sender }
                if ($using:params.recipient) { $trackingParams.Recipients = $using:params.recipient }
                if ($using:params.subject) { $trackingParams.MessageSubject = "*$($using:params.subject)*" }
                Get-MessageTrackingLog @trackingParams | Select-Object Timestamp, Sender, @{N = 'Recipients'; E = { $_.Recipients -join '; ' } }, MessageSubject, EventId, Source
            }
            Invoke-ExchangeCommand -ScriptBlock $scriptBlock
        }
        'audit' {
            if (-not $params.mailbox) { throw "Le nom de la boîte partagée est requis pour l'action 'audit'." }
            $scriptBlock = [scriptblock]::Create("
                Get-MailboxPermission -Identity '$($using:params.mailbox)' | Where-Object { \$_.User -notlike 'NT AUTHORITY\*' -and \$_.IsInherited -eq \$false } | Select-Object Identity, User, @{N='AccessRights';E={(\$_.AccessRights | ForEach-Object { \$_.ToString() }) -join ', '}}
            ")
            Invoke-ExchangeCommand -ScriptBlock $scriptBlock
        }
        'journal' {
            $scriptBlock = { Get-JournalRule | Select-Object Name, Recipient, JournalEmailAddress, Scope, Enabled }
            Invoke-ExchangeCommand -ScriptBlock $scriptBlock
        }
        default { throw "Action '$Action' non reconnue." }
    }

    $finalOutput | ConvertTo-Json -Depth 5
} catch {
    Write-Error "Erreur globale dans le script Exchange: $($_.Exception.Message)"
    exit 1
}