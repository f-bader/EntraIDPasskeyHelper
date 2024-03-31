# Entra ID device-bound passkey preview

This module helps you to enable the Entra ID device-bound passkey preview feature for your organization.

The Entra ID device-bound passkey preview feature allows you to use the Entra ID device-bound passkey as an authentication method for your organization.

## Example #1

This example enables the Entra ID device-bound passkey preview feature for all new Microsoft AAGUIDs while maintaining all existing AAGUIDs.
It first queries all passkey device-bound AAGUIDs already present in current tenant and then sets the authentication method policy for passkeys/FIDO2.
Since the parameter `-MicrosoftAAGUIDsAllowed` is set to All, all Microsoft AAGUIDs are allowed as passkeys.

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All", "Policy.ReadWrite.AuthenticationMethod" -DeviceCode
# Enable the Entra ID device-bound passkey preview feature for all new Microsoft AAGUIDs while maintaining all existing AAGUIDs
Get-PasskeyDeviceBoundAAGUID | Set-PasskeyAuthenticationMethodsPolicy -MicrosoftAAGUIDsAllowed All
```

## Example #2

In this example, the Entra ID device-bound passkey preview feature is enabled, while maintaining all existing AAGUIDs but only allowing a subset of the new Microsoft AAGUIDs.

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All", "Policy.ReadWrite.AuthenticationMethod" -DeviceCode
# Enable the Entra ID device-bound passkey preview feature for Android AAGUIDs while maintaining all existing AAGUIDs
Get-PasskeyDeviceBoundAAGUID | Set-PasskeyAuthenticationMethodsPolicy -MicrosoftAAGUIDsAllowed 'Android' -OverwriteExistingAAGUIDs
```

## Example #3

If you would like to configure the authentication policy method yourself, you can use the following example to gather information about all currently registered FIDO2 security keys.

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All" -DeviceCode -NoWelcome
# Gather information about all currently registered FIDO2 security keys
Get-PasskeyDeviceBoundAAGUID
```
