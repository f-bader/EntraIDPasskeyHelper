<#
.SYNOPSIS
    Get the AAGUIDs of all passkeys that are registered in the tenant.

.DESCRIPTION
    Get the AAGUIDs of all passkeys that are registered in the tenant.

.EXAMPLE
    # Connect-MgGraph -Scopes "AuditLog.Read.All", "Policy.ReadWrite.AuthenticationMethod", "User.Read.All", "UserAuthenticationMethod.Read.All"
    # Get-PasskeyDeviceBoundAAGUID

    This example gets the AAGUIDs of all passkeys that are registered in the tenant.

.NOTES
    Read more about the Entra ID passkey preview at https://cloudbrothers.info/passkeyPreview
#>
function Get-PasskeyDeviceBoundAAGUID {
    [CmdletBinding()]
    param ()

    $ReturnValue = [System.Collections.Generic.List[System.Object]]::new()

    Write-Verbose "Getting AAGUIDs of all passkeys that are registered in the tenant..."

    $NextUri = "https://graph.microsoft.com/beta/reports/authenticationMethods/userRegistrationDetails?`$filter=methodsRegistered/any(x:x eq 'passKeyDeviceBound')&`$select=id"
    try {
        do {
            Write-Progress "Enumerating all user that have passkeys registered" -PercentComplete -1
            $Result = Invoke-MgGraphRequest -Uri $NextUri -Verbose:$false
            $NextUri = $Result['@odata.nextLink']
            $Result['value']  | ForEach-Object {
                $ReturnValue.Add($_) | Out-Null
            }
        } while (-not [string]::IsNullOrWhiteSpace($NextUri) )
    } catch {
        if ($_ -match "Authentication_RequestFromNonPremiumTenantOrB2CTenant") {
            Write-Warning "The Microsoft Graph API endpoint 'reports/authenticationMethods/userRegistrationDetails' requires an Entra ID Premium P1 or P2 license."
            Write-Warning "Fallback to get a list of all users in the tenant and enumerate their FIDO2 methods instead. This may be very slow."
            $UseFullEnumeration = $true
        } else {
            throw "Failed to get current list of passkey device-bound users. Error: $_"
        }
    }

    if ($UseFullEnumeration) {
        Write-Verbose "Fallback to get a list of all users in the tenant and enumerate their FIDO2 methods instead. This may be very slow."
        $NextUri = "https://graph.microsoft.com/beta/users?`$filter=accountEnabled+eq+true&`$select=id&`$top=999"
        try {
            do {
                Write-Progress "Enumerating all users" -PercentComplete -1
                $Result = Invoke-MgGraphRequest -Uri $NextUri -Verbose:$false
                $NextUri = $Result['@odata.nextLink']
                $Result['value']  | ForEach-Object {
                    $ReturnValue.Add($_)
                }
            } while (-not [string]::IsNullOrWhiteSpace($NextUri) )
        } catch {
            throw "Failed to get current list of passkey device-bound users. Error: $_"
        }
    }

    Write-Verbose "Found $($ReturnValue.Count) passkey device-bound users"

    try {
        $PassKeyDeviceBoundUsers = $ReturnValue |  Select-Object id
        $PassKeyDeviceBoundAAGUIDs = [System.Collections.Generic.List[System.Object]]::new()

        $MgBatchSize = 20
        for ($i = 0; $i -lt $PassKeyDeviceBoundUsers.Count; $i += $MgBatchSize) {
            Write-Progress "Getting AAGUIDs of all enumerated users" -PercentComplete ($i / $PassKeyDeviceBoundUsers.Count * 100)
            $LastItem = $i + $MgBatchSize - 1
            if ($LastItem -ge $PassKeyDeviceBoundUsers.Count) { $LastItem = $PassKeyDeviceBoundUsers.Length }

            # Create a batch request for all users in the current batch
            $id = 0
            $Requests = $PassKeyDeviceBoundUsers[$i..($LastItem)] | ForEach-Object {
                [PSCustomObject]@{
                    'Id'     = ++$id
                    'Method' = 'GET'
                    'Url'    = "/users/$($_.id)/authentication/fido2Methods"
                }
            }

            # Send the batch request
            $requestParams = @{
                'Method'      = 'Post'
                'Uri'         = 'https://graph.microsoft.com/v1.0/$batch'
                'ContentType' = 'application/json'
                'Body'        = @{
                    'requests' = @($requests)
                } | ConvertTo-Json
            }
            $Result = Invoke-MgGraphRequest @requestParams
            # Invoke-MgGraphRequest deserializes request to a hashtable
            $Result.responses | Where-Object status -EQ 200 | Select-Object -ExpandProperty body | Select-Object -ExpandProperty value | ForEach-Object {
                $PassKeyDeviceBoundAAGUIDs.Add([pscustomobject]$_)
            }
        }
    } catch {
        throw "Failed to get current list of passkey device-bound users. Error: $_"
    }

    Write-Verbose "Found $($PassKeyDeviceBoundAAGUIDs | Select-Object AAGuid -Unique | Measure-Object | Select-Object -ExpandProperty Count ) unique AAGUIDs"

    $PassKeyDeviceBoundAAGUIDs | Select-Object aaGuid, Model -Unique | Sort-Object Model
}
