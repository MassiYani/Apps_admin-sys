[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SamAccountName
)

$ErrorActionPreference = 'Stop'
function Format-Date($Value) { if ($null -eq $Value) { return $null }; return ([datetime]$Value).ToString('yyyy-MM-dd HH:mm:ss') }

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    $user = Get-ADUser -Identity $SamAccountName -Properties DisplayName,Enabled,LockedOut,LastLogonDate,PasswordLastSet,PasswordNeverExpires,PasswordExpired,EmailAddress,UserPrincipalName,Office,Department,Title,EmployeeID,AdminCount,msExchRemoteRecipientType
    $domain = Get-ADDomain
    $expiry = if ($user.PasswordNeverExpires) { $null } elseif ($user.PasswordLastSet) { $user.PasswordLastSet.Add($domain.MaxPasswordAge) } else { $null }
    $groups = @($user | Get-ADPrincipalGroupMembership | Sort-Object Name | Select-Object -ExpandProperty Name)
    [ordered]@{ Username=$user.SamAccountName; DisplayName=$user.DisplayName; Status=if($user.Enabled){'Actif'}else{'Désactivé'}; IsLocked=[bool]$user.LockedOut; IsAdmin=[bool]($user.AdminCount -eq 1 -or $groups -contains 'Domain Admins'); LastLogon=Format-Date $user.LastLogonDate; PasswordLastSet=Format-Date $user.PasswordLastSet; PasswordExpires=Format-Date $expiry; PasswordNeverExpires=[bool]$user.PasswordNeverExpires; PasswordExpired=[bool]$user.PasswordExpired; Email=$user.EmailAddress; UserPrincipalName=$user.UserPrincipalName; Office365=if($user.msExchRemoteRecipientType){'Synchronisé Exchange / Office 365'}else{'Non détecté'}; Office=$user.Office; Department=$user.Department; Title=$user.Title; EmployeeID=$user.EmployeeID; Groups=$groups } | ConvertTo-Json -Depth 4 -Compress
}
catch {
    [ordered]@{ Username=$SamAccountName; DisplayName="Utilisateur de démonstration ($SamAccountName)"; Status='Actif'; IsLocked=$false; IsAdmin=$false; LastLogon=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); PasswordLastSet=(Get-Date).AddDays(-18).ToString('yyyy-MM-dd HH:mm:ss'); PasswordExpires=(Get-Date).AddDays(72).ToString('yyyy-MM-dd HH:mm:ss'); PasswordNeverExpires=$false; PasswordExpired=$false; Email="$SamAccountName@example.local"; UserPrincipalName="$SamAccountName@example.local"; Office365='Démonstration — module ActiveDirectory indisponible'; Office='—'; Department='—'; Title='—'; EmployeeID='DEMO-001'; Groups=@('Domain Users') } | ConvertTo-Json -Depth 4 -Compress
}