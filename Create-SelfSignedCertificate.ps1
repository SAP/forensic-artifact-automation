<#
.SYNOPSIS
    Creates a new self signed certificate for encryption of data.
.PARAMETER CertName
    Name of the certificate (also used as CN)
.PARAMETER CertPath
    Folder path where the certificate should be stored
.PARAMETER PrivateKeyPassword
    Password for the exported private key
.PARAMETER SkipRemoveFromCertificateStore
    Set if you want to skip the removal of the certificate from your own certificate store
.EXAMPLE
    PS> .\Create-SelfSignedCertificate.ps1 -CertName "Triage collection" -CertPath "C:\Users\forensics\Desktop\"

    Creates a certificate with the name (and CN) "Triage collection" and stores the private key there "C:\Users\forensics\Desktop\Triage collection.pfx" (without password) and the public key (Triage collection.cer) next to it. The temporary generated certificate is then deleted from your own certificate store.
.EXAMPLE
    PS> .\Create-SelfSignedCertificate.ps1 -CertName "Triage collection" -CertPath "C:\Users\forensics\Desktop\" -PrivateKeyPassword "asdf" -SkipRemoveFromCertificateStore

    Creates a certificate with the name (and CN) "Triage collection" and stores the private key there "C:\Users\forensics\Desktop\Triage collection.pfx" (using the password "asdf") and the public key (Triage collection.cer) next to it. The temporary generated certificate is not deleted from your certificate store afterwards.
.NOTES
#>
param(
    [Parameter(HelpMessage="Name of the certificate (also used as CN)", Mandatory=$true)][string]$CertName,
    [Parameter(HelpMessage="Folder path where the certificate should be stored", Mandatory=$true)][string]$CertPath,
    [Parameter(HelpMessage="Password for the exported private key", Mandatory=$false)][string]$PrivateKeyPassword,
    [Parameter(HelpMessage="Set if you want to skip the removal of the certificate from your own certificate store", Mandatory=$false)][Switch]$SkipRemoveFromCertificateStore
)

<#
.SYNOPSIS
    Creates a new self signed certificate for encryption of data.
.PARAMETER CertName
    Name of the certificate (also used as CN)
.PARAMETER CertPath
    Folder path where the certificate should be stored
.PARAMETER PrivateKeyPassword
    Password for the exported private key
.PARAMETER SkipRemoveFromCertificateStore
    Set if you want to skip the removal of the certificate from your own certificate store
#>
function Create-SelfSignedCertificate() {
    param(
        [Parameter(HelpMessage="Name of the certificate (also used as CN)", Mandatory=$true)][string]$CertName,
        [Parameter(HelpMessage="Folder path where the certificate should be stored", Mandatory=$true)][string]$CertPath,
        [Parameter(HelpMessage="Password for the exported private key", Mandatory=$false)][string]$PrivateKeyPassword,
        [Parameter(HelpMessage="Set if you want to skip the removal of the certificate from your own certificate store", Mandatory=$false)][Switch]$SkipRemoveFromCertificateStore
    )

    # Create new certificate
    $cert = New-SelfSignedCertificate -DnsName "$CertName" -KeyUsage @('DataEncipherment', 'KeyAgreement', 'KeyEncipherment') -Type DocumentEncryptionCert -CertStoreLocation Cert:\CurrentUser\My
    Write-Output ("Successfully created certificate '{0}' with thumbprint {1}" -f $cert.Subject, $cert.Thumbprint) | Log-Success

    # Export private key
    $privateKeyPath = "$([System.IO.Path]::Combine("$CertPath", "$($CertName).pfx"))"
    if ([string]::IsNullOrEmpty("$PrivateKeyPassword")) {
        [System.IO.File]::WriteAllBytes("$privateKeyPath", $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx))
        Write-Output ("Exported private key (without password): {0}" -f $privateKeyPath) | Log-Info
    } else {
        [System.IO.File]::WriteAllBytes("$privateKeyPath", $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, "$PrivateKeyPassword"))
        Write-Output ("Exported private key (using provided password): {0}" -f $privateKeyPath) | Log-Info
    }

    # Export public key
    $cer = "-----BEGIN CERTIFICATE-----" + [Environment]::NewLine
    $cer += [System.Convert]::ToBase64String($cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert), [System.Base64FormattingOptions]::InsertLineBreaks)
    $cer += [Environment]::NewLine + "-----END CERTIFICATE-----"
    
    $publicKeyPath = "$([System.IO.Path]::Combine("$CertPath", "$($CertName).cer"))"
    [System.IO.File]::WriteAllText("$publicKeyPath", $cer)
    Write-Output ("Exported public key: {0}" -f $publicKeyPath) | Log-Info

    # Remove certificate again
    if (!$SkipRemoveFromCertificateStore) {
        $certStore = [System.Security.Cryptography.X509Certificates.X509Store]::new([System.Security.Cryptography.X509Certificates.StoreName]::My, [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser)
        $certStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite + [System.Security.Cryptography.X509Certificates.OpenFlags]::IncludeArchived)

        $certStore.Remove($cert)

        $certStore.Close()

        Write-Output ("Removed certificated from your certificate store again") | Log-Success
    }
}

<#
.SYNOPSIS
    Logs the given message as error.
.PARAMETER Message
    Message to be logged
.EXAMPLE
    PS> Log-Error -Message "My error message"
#>
function Log-Error() {
    param(
        [Parameter(HelpMessage="Message to log", Mandatory=$true, ValueFromPipeline=$true)][string]$Message
    )
    Write-Error "[$([System.DateTime]::Now.ToString("o"))] [E] $Message"
}

<#
.SYNOPSIS
    Logs the given message as information.
.PARAMETER Message
    Message to be logged
.EXAMPLE
    PS> Log-Info -Message "My informal message"
#>
function Log-Info() {
    param(
        [Parameter(HelpMessage="Message to log", Mandatory=$true, ValueFromPipeline=$true)][string]$Message
    )
    Write-Host "[$([System.DateTime]::Now.ToString("o"))] [I] $Message"
}

<#
.SYNOPSIS
    Logs the given message as warning.
.PARAMETER Message
    Message to be logged
.EXAMPLE
    PS> Log-Warning -Message "My warning message"
#>
function Log-Warning() {
    param(
        [Parameter(HelpMessage="Message to log", Mandatory=$true, ValueFromPipeline=$true)][string]$Message
    )
    Write-Host -ForegroundColor Yellow "[$([System.DateTime]::Now.ToString("o"))] [W] $Message"
}

<#
.SYNOPSIS
    Logs the given message as success.
.PARAMETER Message
    Message to be logged
.EXAMPLE
    PS> Log-Success -Message "My success message"
#>
function Log-Success() {
    param(
        [Parameter(HelpMessage="Message to log", Mandatory=$true, ValueFromPipeline=$true)][string]$Message
    )
    Write-Host -ForegroundColor Green "[$([System.DateTime]::Now.ToString("o"))] [S] $Message"
}

# Set current working directory for .NET
[System.IO.Directory]::SetCurrentDirectory("$PSScriptRoot")

# Invoke required function
Create-SelfSignedCertificate -CertName "$CertName" -CertPath "$CertPath" -PrivateKeyPassword "$PrivateKeyPassword" -SkipRemoveFromCertificateStore:$SkipRemoveFromCertificateStore