# Entra ID device-bound passkey preview

This module helps you to enable the Entra ID device-bound passkey preview feature for your organization.

The Entra ID device-bound passkey preview feature allows you to use the Entra ID device-bound passkey as an authentication method for your organization.

## Installation

To install the module from the [PowerShell Gallery](https://www.powershellgallery.com/packages/EntraIdPasskeyHelper), you can use the following command:

```powershell
Install-Module -Name EntraIDPasskeyHelper
```

You find the module [here](https://www.powershellgallery.com/packages/EntraIdPasskeyHelper) in the PowerShell Gallery.

## Usage

### Example #1

This example enables the Entra ID device-bound passkey preview feature for all new Microsoft AAGUIDs while maintaining all existing AAGUIDs.
It first queries all passkey device-bound AAGUIDs already present in current tenant and then sets the authentication method policy for passkeys/FIDO2.
Since the parameter `-MicrosoftAAGUIDsAllowed` is set to All, all Microsoft AAGUIDs are allowed as passkeys.

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All", "Policy.ReadWrite.AuthenticationMethod", "User.Read.All", "UserAuthenticationMethod.Read.All"
# Enable the Entra ID device-bound passkey preview feature for all new Microsoft AAGUIDs while maintaining all existing AAGUIDs
Get-PasskeyDeviceBoundAAGUID | Set-PasskeyAuthenticationMethodsPolicy -MicrosoftAAGUIDsAllowed All
```

### Example #2

In this example, the Entra ID device-bound passkey preview feature is enabled, while maintaining all existing AAGUIDs but only allowing a subset of the new Microsoft AAGUIDs.

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All", "Policy.ReadWrite.AuthenticationMethod", "User.Read.All", "UserAuthenticationMethod.Read.All"
# Enable the Entra ID device-bound passkey preview feature for Android AAGUIDs while maintaining all existing AAGUIDs
Get-PasskeyDeviceBoundAAGUID | Set-PasskeyAuthenticationMethodsPolicy -MicrosoftAAGUIDsAllowed 'Android' -OverwriteExistingAAGUIDs
```

### Example #3

If you would like to configure the authentication policy method yourself, you can use the following example to gather information about all currently registered FIDO2 security keys.

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All", "User.Read.All", "UserAuthenticationMethod.Read.All" -DeviceCode -NoWelcome
# Gather information about all currently registered FIDO2 security keys
Get-PasskeyDeviceBoundAAGUID
```

## Known limitations

If the tenant is not licensed with Entra ID P1 or P2 the Microsoft Graph endpoint 'reports/authenticationMethods/userRegistrationDetails' is not available.
In this case all users are enumerated and check for authentication methods.

This can be a very slow process if you have thousands of users.
