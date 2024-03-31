<#
.SYNOPSIS
    Set the authentication method policy for passkeys/FIDO2 and enable the Entra ID passkey preview feature.

.DESCRIPTION
    This function sets the authentication method policy for passkeys/FIDO2 and enables the Entra ID passkey preview feature for your organization.
    The Entra ID passkey preview feature allows you to use passkey as an authentication method for your organization.

    Read more about the Entra ID passkey preview at https://cloudbrothers.info/passkeyPreview

.PARAMETER EnforceAttestation
    Enforce attestation for FIDO2 authenticators.
    This means that the authenticator must be verified by the manufacturer before it can be used for authentication.
    In the public preview, this setting is not supported and must be set to $false.

    Default value is $false.

.PARAMETER AAGUIDsAllowed
    List of AAGUIDs that are allowed to be used as passkeys. AAGUIDs are unique identifiers for FIDO2 authenticators.

    Default value is an empty array.

.PARAMETER MicrosoftAAGUIDsAllowed
    All          =  All passkeys from Microsoft are allowed. This includes all Microsoft Authenticator device-bound passkeys.
    iOS          =  90a3ccdf-635c-4729-a248-9b709135078f - iOS Microsoft Authenticator device bound passkey
    Android      =  de1e552d-db1d-4423-a619-566b625cdc84 - Android Microsoft Authenticator device bound passkey

    Default value is "All".

.PARAMETER OverwriteExistingAAGUIDs
    Overwrite existing AAGUIDs with the ones provided in the AAGUIDsAllowed parameter.
    If this switch is not used, the AAGUIDs provided in the AAGUIDsAllowed parameter will be added to the existing list of allowed AAGUIDs.

    Default value is $false.

.EXAMPLE
    # Set-PasskeyAuthenticationMethodsPolicy -EnforceAttestation $false -AAGUIDsAllowed "77010bd7-212a-4fc9-b236-d2ca5e9d4084" -MicrosoftAAGUIDsAllowed "All"

    This example sets the authentication method policy for passkeys/FIDO2 to allow all Microsoft AAGUIDs and the custom AAGUID 77010bd7-212a-4fc9-b236-d2ca5e9d4084 (Feitian BioPass FIDO2 Authenticator).

.NOTES
   Read more about the Entra ID passkey preview at https://cloudbrothers.info/passkeyPreview
#>
function Set-PasskeyAuthenticationMethodsPolicy {
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [Parameter()]
        [bool]$EnforceAttestation = $false,

        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidateScript(
            { $_ | ForEach-Object { $_ -match "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$" } }
        )]
        [Alias("aaGuid")]
        [string[]]$AAGUIDsAllowed,

        [Parameter()]
        [ValidateSet("All", "iOS", "Android")]
        [string[]]$MicrosoftAAGUIDsAllowed = "All",

        [Parameter()]
        [switch]$OverwriteExistingAAGUIDs
    )

    begin {
        # Initialize the array list
        $AAGUIDsAllowedFromPipeline = [System.Collections.ArrayList]::new()
    }
    
    process {
        # Add the AAGUIDs from the pipeline to the array list
        $AAGUIDsAllowed | ForEach-Object {
            $AAGUIDsAllowedFromPipeline.Add($_) | Out-Null
        }
    }

    end {

        if ($AAGUIDsAllowedFromPipeline -ne $null) {
            $TmpAAGUIDsAllowed = $AAGUIDsAllowedFromPipeline
        } else {
            $TmpAAGUIDsAllowed = $AAGUIDsAllowed
        }

        $AvailablePasskeyAAGUIDs = @{
            "iOS"     = "90a3ccdf-635c-4729-a248-9b709135078f"
            "Android" = "de1e552d-db1d-4423-a619-566b625cdc84"
        }

        $SelectedAAGUIDs = [System.Collections.ArrayList]::new()
        if ( $MicrosoftAAGUIDsAllowed -contains "All" ) {
            Write-Verbose "All Microsoft AAGUIDs are allowed"
            $SelectedAAGUIDs.AddRange($AvailablePasskeyAAGUIDs.Values) | Out-Null
        } else {
            foreach ( $AAGUID in $MicrosoftAAGUIDsAllowed ) {
                Write-Verbose "Adding Microsoft AAGUID $AAGUID to the allowed list"
                $SelectedAAGUIDs.Add($AvailablePasskeyAAGUIDs[$AAGUID]) | Out-Null
            }
        }

        foreach ( $AAGUID in $TmpAAGUIDsAllowed ) {
            Write-Verbose "Adding custom AAGUID $AAGUID to the allowed list"
            $SelectedAAGUIDs.Add($AAGUID) | Out-Null
        }

        if ($EnforceAttestation -eq $false) {
            Write-Warning "EnforceAttestation is set to $false because it's required for the public preview. Please make sure if this is the desired setting for your organization."
        }

        try {
            $CurrentConfiguration = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/policies/authenticationmethodspolicy/authenticationMethodConfigurations/Fido2" -Method Get -Verbose:$false
        } catch {
            Write-Error "Failed to get current configuration. Error: $_"
            throw
        }

        if ($CurrentConfiguration.state -eq "disabled") {
            Write-Verbose "Authentication method policy for passkeys/FIDO2 is currently disabled."
        } else {
            Write-Verbose "Authentication method policy for passkeys/FIDO2 is currently enabled."
        }

        Write-Verbose "Attestation enforcement is $($CurrentConfiguration.isAttestationEnforced)"

        if ( $CurrentConfiguration.keyRestrictions.isEnforced ) {
            Write-Verbose "Enforcement type is $($CurrentConfiguration.keyRestrictions.enforcementType)"
            if ($CurrentConfiguration.keyRestrictions.enforcementType -eq "allow") {
                Write-Verbose "Currently allowed AAGUIDs are $($CurrentConfiguration.keyRestrictions.aaGuids -join ', ')"
            } else {
                Write-Verbose "Currently disallowed AAGUIDs are $($CurrentConfiguration.keyRestrictions.aaGuids -join ', ')"
            }
        }

        if ( $OverwriteExistingAAGUIDs ) {
            Write-Verbose "Overwriting existing AAGUIDs"
            $SelectedAAGUIDs = $SelectedAAGUIDs | Sort-Object -Unique
        } else {
            Write-Verbose "Adding new AAGUIDs to existing list"
            $SelectedAAGUIDs.AddRange($CurrentConfiguration.keyRestrictions.aaGuids) | Out-Null
            $SelectedAAGUIDs = $SelectedAAGUIDs | Sort-Object -Unique
        }

        $NewConfiguration = @{
            "@odata.type"                      = "#microsoft.graph.fido2AuthenticationMethodConfiguration"
            "isAttestationEnforced"            = $EnforceAttestation
            "isSelfServiceRegistrationAllowed" = $true
            "keyRestrictions"                  = @{
                "aaGuids"         = $SelectedAAGUIDs
                "enforcementType" = "allow"
                "isEnforced"      = $true
            }
            "state"                            = "enabled"
        }

        $NewConfiguration | ConvertTo-Json -Depth 10 | Write-Verbose

        try {
            Write-Output "Setting new authentication method policy for passkeys/FIDO2"
            if ($PSCmdlet.ShouldProcess("https://graph.microsoft.com/beta/policies/authenticationmethodspolicy/authenticationMethodConfigurations/Fido2")) {
                Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/policies/authenticationmethodspolicy/authenticationMethodConfigurations/Fido2" -Method Patch -Body ($NewConfiguration | ConvertTo-Json -Depth 10) -Verbose:$false | Out-Null
            }
            Write-Output "Successfully set new configuration. Have a nice day!"
        } catch {
            Write-Error "Failed to set new configuration. Error: $_"
            throw
        }
    }
}