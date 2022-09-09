# Auto-generated argument completers for parameters of SDK ConstantClass-derived type used in cmdlets.
# Do not modify this file; it may be overwritten during version upgrades.

$psMajorVersion = $PSVersionTable.PSVersion.Major
if ($psMajorVersion -eq 2) 
{ 
	Write-Verbose "Dynamic argument completion not supported in PowerShell version 2; skipping load."
	return 
}

# PowerShell's native Register-ArgumentCompleter cmdlet is available on v5.0 or higher. For lower
# version, we can use the version in the TabExpansion++ module if installed.
$registrationCmdletAvailable = ($psMajorVersion -ge 5) -Or !((Get-Command Register-ArgumentCompleter -ea Ignore) -eq $null)

# internal function to perform the registration using either cmdlet or manipulation
# of the options table
function _awsArgumentCompleterRegistration()
{
    param
    (
        [scriptblock]$scriptBlock,
        [hashtable]$param2CmdletsMap
    )

    if ($registrationCmdletAvailable)
    {
        foreach ($paramName in $param2CmdletsMap.Keys)
        {
             $args = @{
                "ScriptBlock" = $scriptBlock
                "Parameter" = $paramName
            }

            $cmdletNames = $param2CmdletsMap[$paramName]
            if ($cmdletNames -And $cmdletNames.Length -gt 0)
            {
                $args["Command"] = $cmdletNames
            }

            Register-ArgumentCompleter @args
        }
    }
    else
    {
        if (-not $global:options) { $global:options = @{ CustomArgumentCompleters = @{ }; NativeArgumentCompleters = @{ } } }

        foreach ($paramName in $param2CmdletsMap.Keys)
        {
            $cmdletNames = $param2CmdletsMap[$paramName]

            if ($cmdletNames -And $cmdletNames.Length -gt 0)
            {
                foreach ($cn in $cmdletNames)
                {
                    $fqn =  [string]::Concat($cn, ":", $paramName)
                    $global:options['CustomArgumentCompleters'][$fqn] = $scriptBlock
                }
            }
            else
            {
                $global:options['CustomArgumentCompleters'][$paramName] = $scriptBlock
            }
        }

        $function:tabexpansion2 = $function:tabexpansion2 -replace 'End\r\n{', 'End { if ($null -ne $options) { $options += $global:options} else {$options = $global:options}'
    }
}

# To allow for same-name parameters of different ConstantClass-derived types 
# each completer function checks on command name concatenated with parameter name.
# Additionally, the standard code pattern for completers is to pipe through 
# sort-object after filtering against $wordToComplete but we omit this as our members 
# are already sorted.

# Argument completions for service Amazon Simple Storage Service (S3)


$S3_Completers = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    switch ($("$commandName/$parameterName"))
    {
        # Amazon.S3.BucketAccelerateStatus
        "Write-S3BucketAccelerateConfiguration/AccelerateConfiguration_Status"
        {
            $v = "Enabled","Suspended"
            break
        }

        # Amazon.S3.EncodingType
        {
            ($_ -eq "Get-S3MultipartUpload/Encoding") -Or
            ($_ -eq "Get-S3Object/Encoding") -Or
            ($_ -eq "Get-S3ObjectV2/Encoding") -Or
            ($_ -eq "Get-S3Version/Encoding")
        }
        {
            $v = "Url"
            break
        }

        # Amazon.S3.ExpressionType
        "Select-S3ObjectContent/ExpressionType"
        {
            $v = "SQL"
            break
        }

        # Amazon.S3.GlacierJobTier
        {
            ($_ -eq "Restore-S3Object/RetrievalTier") -Or
            ($_ -eq "Restore-S3Object/Tier")
        }
        {
            $v = "Bulk","Expedited","Standard"
            break
        }

        # Amazon.S3.IntelligentTieringStatus
        "Write-S3BucketIntelligentTieringConfiguration/IntelligentTieringConfiguration_Status"
        {
            $v = "Disabled","Enabled"
            break
        }

        # Amazon.S3.InventoryFormat
        "Write-S3BucketInventoryConfiguration/InventoryConfiguration_Destination_S3BucketDestination_InventoryFormat"
        {
            $v = "CSV","ORC","Parquet"
            break
        }

        # Amazon.S3.InventoryFrequency
        "Write-S3BucketInventoryConfiguration/InventoryConfiguration_Schedule_Frequency"
        {
            $v = "Daily","Weekly"
            break
        }

        # Amazon.S3.InventoryIncludedObjectVersions
        "Write-S3BucketInventoryConfiguration/InventoryConfiguration_IncludedObjectVersions"
        {
            $v = "All","Current"
            break
        }

        # Amazon.S3.ObjectLockEnabled
        "Write-S3ObjectLockConfiguration/ObjectLockConfiguration_ObjectLockEnabled"
        {
            $v = "Enabled"
            break
        }

        # Amazon.S3.ObjectLockLegalHoldStatus
        {
            ($_ -eq "Write-S3ObjectLegalHold/LegalHold_Status") -Or
            ($_ -eq "Write-S3GetObjectResponse/ObjectLockLegalHoldStatus")
        }
        {
            $v = "OFF","ON"
            break
        }

        # Amazon.S3.ObjectLockMode
        "Write-S3GetObjectResponse/ObjectLockMode"
        {
            $v = "COMPLIANCE","GOVERNANCE"
            break
        }

        # Amazon.S3.ObjectLockRetentionMode
        {
            ($_ -eq "Write-S3ObjectLockConfiguration/ObjectLockConfiguration_Rule_DefaultRetention_Mode") -Or
            ($_ -eq "Write-S3ObjectRetention/Retention_Mode")
        }
        {
            $v = "COMPLIANCE","GOVERNANCE"
            break
        }

        # Amazon.S3.ReplicationStatus
        "Write-S3GetObjectResponse/ReplicationStatus"
        {
            $v = "COMPLETED","FAILED","PENDING","REPLICA"
            break
        }

        # Amazon.S3.RequestCharged
        "Write-S3GetObjectResponse/RequestCharged"
        {
            $v = "requester"
            break
        }

        # Amazon.S3.RequestPayer
        {
            ($_ -eq "Get-S3Object/RequestPayer") -Or
            ($_ -eq "Get-S3ObjectLegalHold/RequestPayer") -Or
            ($_ -eq "Get-S3ObjectMetadata/RequestPayer") -Or
            ($_ -eq "Get-S3ObjectRetention/RequestPayer") -Or
            ($_ -eq "Get-S3ObjectTagSet/RequestPayer") -Or
            ($_ -eq "Get-S3ObjectV2/RequestPayer") -Or
            ($_ -eq "Restore-S3Object/RequestPayer") -Or
            ($_ -eq "Write-S3ObjectLegalHold/RequestPayer") -Or
            ($_ -eq "Write-S3ObjectLockConfiguration/RequestPayer") -Or
            ($_ -eq "Write-S3ObjectRetention/RequestPayer") -Or
            ($_ -eq "Write-S3ObjectTagSet/RequestPayer")
        }
        {
            $v = "requester"
            break
        }

        # Amazon.S3.RestoreRequestType
        "Restore-S3Object/RestoreRequestType"
        {
            $v = "SELECT"
            break
        }

        # Amazon.S3.S3CannedACL
        {
            ($_ -eq "Set-S3ACL/CannedACL") -Or
            ($_ -eq "Copy-S3Object/CannedACLName") -Or
            ($_ -eq "New-S3Bucket/CannedACLName") -Or
            ($_ -eq "Write-S3Object/CannedACLName") -Or
            ($_ -eq "Restore-S3Object/OutputLocation_S3_CannedACL")
        }
        {
            $v = "authenticated-read","aws-exec-read","bucket-owner-full-control","bucket-owner-read","log-delivery-write","NoACL","private","public-read","public-read-write"
            break
        }

        # Amazon.S3.S3StorageClass
        {
            ($_ -eq "Restore-S3Object/OutputLocation_S3_StorageClass") -Or
            ($_ -eq "Write-S3GetObjectResponse/StorageClass")
        }
        {
            $v = "DEEP_ARCHIVE","GLACIER","INTELLIGENT_TIERING","ONEZONE_IA","OUTPOSTS","REDUCED_REDUNDANCY","STANDARD","STANDARD_IA"
            break
        }

        # Amazon.S3.ServerSideEncryptionCustomerMethod
        {
            ($_ -eq "Copy-S3Object/CopySourceServerSideEncryptionCustomerMethod") -Or
            ($_ -eq "Select-S3ObjectContent/ServerSideCustomerEncryptionMethod") -Or
            ($_ -eq "Copy-S3Object/ServerSideEncryptionCustomerMethod") -Or
            ($_ -eq "Get-S3ObjectMetadata/ServerSideEncryptionCustomerMethod") -Or
            ($_ -eq "Get-S3PreSignedURL/ServerSideEncryptionCustomerMethod") -Or
            ($_ -eq "Read-S3Object/ServerSideEncryptionCustomerMethod") -Or
            ($_ -eq "Write-S3Object/ServerSideEncryptionCustomerMethod") -Or
            ($_ -eq "Write-S3GetObjectResponse/SSECustomerAlgorithm")
        }
        {
            $v = "","AES256"
            break
        }

        # Amazon.S3.ServerSideEncryptionMethod
        {
            ($_ -eq "Restore-S3Object/OutputLocation_S3_Encryption_EncryptionType") -Or
            ($_ -eq "Copy-S3Object/ServerSideEncryption") -Or
            ($_ -eq "Write-S3Object/ServerSideEncryption") -Or
            ($_ -eq "Get-S3PreSignedURL/ServerSideEncryptionMethod") -Or
            ($_ -eq "Write-S3GetObjectResponse/ServerSideEncryptionMethod")
        }
        {
            $v = "","AES256","aws:kms"
            break
        }

        # Amazon.S3.StorageClassAnalysisSchemaVersion
        "Write-S3BucketAnalyticsConfiguration/AnalyticsConfiguration_StorageClassAnalysis_DataExport_OutputSchemaVersion"
        {
            $v = "V_1"
            break
        }

        # Amazon.S3.VersionStatus
        "Write-S3BucketVersioning/VersioningConfig_Status"
        {
            $v = "Enabled","Off","Suspended"
            break
        }


    }

    $v |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object { New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_ }
}

$S3_map = @{
    "AccelerateConfiguration_Status"=@("Write-S3BucketAccelerateConfiguration")
    "AnalyticsConfiguration_StorageClassAnalysis_DataExport_OutputSchemaVersion"=@("Write-S3BucketAnalyticsConfiguration")
    "CannedACL"=@("Set-S3ACL")
    "CannedACLName"=@("Copy-S3Object","New-S3Bucket","Write-S3Object")
    "CopySourceServerSideEncryptionCustomerMethod"=@("Copy-S3Object")
    "Encoding"=@("Get-S3MultipartUpload","Get-S3Object","Get-S3ObjectV2","Get-S3Version")
    "ExpressionType"=@("Select-S3ObjectContent")
    "IntelligentTieringConfiguration_Status"=@("Write-S3BucketIntelligentTieringConfiguration")
    "InventoryConfiguration_Destination_S3BucketDestination_InventoryFormat"=@("Write-S3BucketInventoryConfiguration")
    "InventoryConfiguration_IncludedObjectVersions"=@("Write-S3BucketInventoryConfiguration")
    "InventoryConfiguration_Schedule_Frequency"=@("Write-S3BucketInventoryConfiguration")
    "LegalHold_Status"=@("Write-S3ObjectLegalHold")
    "ObjectLockConfiguration_ObjectLockEnabled"=@("Write-S3ObjectLockConfiguration")
    "ObjectLockConfiguration_Rule_DefaultRetention_Mode"=@("Write-S3ObjectLockConfiguration")
    "ObjectLockLegalHoldStatus"=@("Write-S3GetObjectResponse")
    "ObjectLockMode"=@("Write-S3GetObjectResponse")
    "OutputLocation_S3_CannedACL"=@("Restore-S3Object")
    "OutputLocation_S3_Encryption_EncryptionType"=@("Restore-S3Object")
    "OutputLocation_S3_StorageClass"=@("Restore-S3Object")
    "ReplicationStatus"=@("Write-S3GetObjectResponse")
    "RequestCharged"=@("Write-S3GetObjectResponse")
    "RequestPayer"=@("Get-S3Object","Get-S3ObjectLegalHold","Get-S3ObjectMetadata","Get-S3ObjectRetention","Get-S3ObjectTagSet","Get-S3ObjectV2","Restore-S3Object","Write-S3ObjectLegalHold","Write-S3ObjectLockConfiguration","Write-S3ObjectRetention","Write-S3ObjectTagSet")
    "RestoreRequestType"=@("Restore-S3Object")
    "Retention_Mode"=@("Write-S3ObjectRetention")
    "RetrievalTier"=@("Restore-S3Object")
    "ServerSideCustomerEncryptionMethod"=@("Select-S3ObjectContent")
    "ServerSideEncryption"=@("Copy-S3Object","Write-S3Object")
    "ServerSideEncryptionCustomerMethod"=@("Copy-S3Object","Get-S3ObjectMetadata","Get-S3PreSignedURL","Read-S3Object","Write-S3Object")
    "ServerSideEncryptionMethod"=@("Get-S3PreSignedURL","Write-S3GetObjectResponse")
    "SSECustomerAlgorithm"=@("Write-S3GetObjectResponse")
    "StorageClass"=@("Write-S3GetObjectResponse")
    "Tier"=@("Restore-S3Object")
    "VersioningConfig_Status"=@("Write-S3BucketVersioning")
}

_awsArgumentCompleterRegistration $S3_Completers $S3_map

$S3_SelectCompleters = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $cmdletType = Invoke-Expression "[Amazon.PowerShell.Cmdlets.S3.$($commandName.Replace('-', ''))Cmdlet]"
    if (-not $cmdletType) {
        return
    }
    $awsCmdletAttribute = $cmdletType.GetCustomAttributes([Amazon.PowerShell.Common.AWSCmdletAttribute], $false)
    if (-not $awsCmdletAttribute) {
        return
    }
    $type = $awsCmdletAttribute.SelectReturnType
    if (-not $type) {
        return
    }

    $splitSelect = $wordToComplete -Split '\.'
    $splitSelect | Select-Object -First ($splitSelect.Length - 1) | ForEach-Object {
        $propertyName = $_
        $properties = $type.GetProperties(('Instance', 'Public', 'DeclaredOnly')) | Where-Object { $_.Name -ieq $propertyName }
        if ($properties.Length -ne 1) {
            break
        }
        $type = $properties.PropertyType
        $prefix += "$($properties.Name)."

        $asEnumerableType = $type.GetInterface('System.Collections.Generic.IEnumerable`1')
        if ($asEnumerableType -and $type -ne [System.String]) {
            $type =  $asEnumerableType.GetGenericArguments()[0]
        }
    }

    $v = @( '*' )
    $properties = $type.GetProperties(('Instance', 'Public', 'DeclaredOnly')).Name | Sort-Object
    if ($properties) {
        $v += ($properties | ForEach-Object { $prefix + $_ })
    }
    $parameters = $cmdletType.GetProperties(('Instance', 'Public')) | Where-Object { $_.GetCustomAttributes([System.Management.Automation.ParameterAttribute], $true) } | Select-Object -ExpandProperty Name | Sort-Object
    if ($parameters) {
        $v += ($parameters | ForEach-Object { "^$_" })
    }

    $v |
        Where-Object { $_ -match "^$([System.Text.RegularExpressions.Regex]::Escape($wordToComplete)).*" } |
        ForEach-Object { New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_ }
}

$S3_SelectMap = @{
    "Select"=@("Remove-S3BucketAnalyticsConfiguration",
               "Remove-S3BucketEncryption",
               "Remove-S3BucketIntelligentTieringConfiguration",
               "Remove-S3BucketInventoryConfiguration",
               "Remove-S3BucketMetricsConfiguration",
               "Remove-S3BucketOwnershipControl",
               "Remove-S3BucketPolicy",
               "Remove-S3BucketReplication",
               "Remove-S3BucketTagging",
               "Remove-S3BucketWebsite",
               "Remove-S3CORSConfiguration",
               "Remove-S3LifecycleConfiguration",
               "Remove-S3ObjectTagSet",
               "Remove-S3PublicAccessBlock",
               "Get-S3ACL",
               "Get-S3BucketAccelerateConfiguration",
               "Get-S3BucketAnalyticsConfiguration",
               "Get-S3BucketEncryption",
               "Get-S3BucketIntelligentTieringConfiguration",
               "Get-S3BucketInventoryConfiguration",
               "Get-S3BucketLocation",
               "Get-S3BucketLogging",
               "Get-S3BucketMetricsConfiguration",
               "Get-S3BucketNotification",
               "Get-S3BucketOwnershipControl",
               "Get-S3BucketPolicy",
               "Get-S3BucketPolicyStatus",
               "Get-S3BucketReplication",
               "Get-S3BucketRequestPayment",
               "Get-S3BucketTagging",
               "Get-S3BucketVersioning",
               "Get-S3BucketWebsite",
               "Get-S3CORSConfiguration",
               "Get-S3LifecycleConfiguration",
               "Get-S3ObjectLegalHold",
               "Get-S3ObjectLockConfiguration",
               "Get-S3ObjectMetadata",
               "Get-S3ObjectRetention",
               "Get-S3ObjectTagSet",
               "Get-S3PublicAccessBlock",
               "Get-S3BucketAnalyticsConfigurationList",
               "Get-S3BucketIntelligentTieringConfigurationList",
               "Get-S3BucketInventoryConfigurationList",
               "Get-S3BucketMetricsConfigurationList",
               "Get-S3Bucket",
               "Get-S3Object",
               "Get-S3ObjectV2",
               "Get-S3Version",
               "Set-S3ACL",
               "Write-S3BucketAccelerateConfiguration",
               "Write-S3BucketAnalyticsConfiguration",
               "Set-S3BucketEncryption",
               "Write-S3BucketIntelligentTieringConfiguration",
               "Write-S3BucketInventoryConfiguration",
               "Write-S3BucketLogging",
               "Write-S3BucketMetricsConfiguration",
               "Write-S3BucketNotification",
               "Write-S3BucketOwnershipControl",
               "Write-S3BucketPolicy",
               "Write-S3BucketReplication",
               "Write-S3BucketRequestPayment",
               "Write-S3BucketTagging",
               "Write-S3BucketVersioning",
               "Write-S3BucketWebsite",
               "Write-S3CORSConfiguration",
               "Write-S3LifecycleConfiguration",
               "Write-S3ObjectLegalHold",
               "Write-S3ObjectLockConfiguration",
               "Write-S3ObjectRetention",
               "Write-S3ObjectTagSet",
               "Add-S3PublicAccessBlock",
               "Restore-S3Object",
               "Select-S3ObjectContent",
               "Write-S3GetObjectResponse",
               "Copy-S3Object",
               "Get-S3MultipartUpload",
               "Get-S3PreSignedURL",
               "New-S3Bucket",
               "Read-S3Object",
               "Remove-S3Bucket",
               "Remove-S3MultipartUpload",
               "Remove-S3Object",
               "Test-S3Bucket",
               "Write-S3Object")
}

_awsArgumentCompleterRegistration $S3_SelectCompleters $S3_SelectMap


# SIG # Begin signature block
# MIIa4gYJKoZIhvcNAQcCoIIa0zCCGs8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDMgFkG8Yrj1t0m
# uwTL7KoxD43QlQPfNVrYKxEPyQMUl6CCCoYwggUwMIIEGKADAgECAhAECRgbX9W7
# ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEwMjIxMjAwMDBa
# Fw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lD
# ZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7RZmxOttE9X/l
# qJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p0WfTxvspJ8fT
# eyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6YgsIJWuHEqH
# CN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grkV7tKtel05iv+
# bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0xY4PwaLo
# LFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMBAAGjggHNMIIB
# yTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAK
# BggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9v
# Y3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHow
# eDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJl
# ZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgGCmCGSAGG/WwA
# AgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAK
# BghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHwYDVR0j
# BBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQADggEBAD7s
# DVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q3yBVN7Dh9tGS
# dQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEbBw6RFfu6
# r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dcIFzZcbEMj7uo
# +MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6dGRrsutmQ9qz
# sIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT+hKUGIUukpHq
# aGxEMrJmoecYpJpkUe8wggVOMIIENqADAgECAhALTIJyAKtH3xTtbI8ZUVgmMA0G
# CSqGSIb3DQEBCwUAMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJ
# bmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0
# IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwHhcNMjAwNjIyMDAwMDAw
# WhcNMjEwNjMwMTIwMDAwWjCBijELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1NlYXR0bGUxIjAgBgNVBAoTGUFtYXpvbiBXZWIgU2Vy
# dmljZXMsIEluYy4xDDAKBgNVBAsTA0FXUzEiMCAGA1UEAxMZQW1hem9uIFdlYiBT
# ZXJ2aWNlcywgSW5jLjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALmr
# sFGrSta/FARlw23GEH+EpVCu0ejJBCgyuE2cX1ArId8rh8M6Q9/R8mlash12LDk6
# Zhfl0418bvsGqxp4V7x1PBwM9LqHwv+v9SRNJkIIRE9XQW5XLubMLDSZbqz4ysK4
# BeNXx8fg3DPIhzRYnNVAsINj43T95kW21Mje7pe8nABgUF+ihOyarccQ/+eUYHbf
# vNKEn7jVwVElzKc0zlYB2xwn6NC75FunB9ah9bK1eiKyDIVq0lQfW07yW4ReAIci
# 7Lmk/NLK6p+WX18tevZyOZvTp2JWCMrjQpi4Z6zNcgPVlQH/Fw9pOH88AoRNspJq
# M4cTQ9nZuVO1YP37uh8CAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl
# 6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBRslc5x8VXQyhHcfVS3bCh5Tu1ZcTAOBgNV
# HQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOg
# MYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5j
# cmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQt
# Y3MtZzEuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEW
# HGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEF
# BQcBAQR4MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBO
# BggrBgEFBQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# U0hBMkFzc3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJ
# KoZIhvcNAQELBQADggEBAIyDXLu8ZDZqNX5ET8VHvAu/9V6yXI+HNMeUOJO4/az7
# 5HmJmja6SpmfLZC3g+WbNgF4roHwMNsIdb7dbdTGedxef49HJe5Ut5iV5vQ8DuKn
# PA7ezZV93Y5XDEiboX3sys5/k+7B1ZcP1jkObnfzQs7QXLAa3C/+kPtNmsXmTFOg
# DzRBmkr1Z/LXGTxgoWNQVZKNm2HA6ePRLPGBIXw7DUTnHtr9+4Fqxadck6fn5izz
# PUMOliRngw8XKTIRgBODRInHJZN9GRZI11emCP25LdHwLySxdHBTKsaslToKRAnd
# hrQhoc1FDAV6wKBOQoEKRZd75GIijtMCFaih+sVRCNAxgg+yMIIPrgIBATCBhjBy
# MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
# d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQg
# SUQgQ29kZSBTaWduaW5nIENBAhALTIJyAKtH3xTtbI8ZUVgmMA0GCWCGSAFlAwQC
# AQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIE
# IMH1tuPRGc5HC0LNSDMywG3Y21TxFeqlRsmlJQ9/8aXMMA0GCSqGSIb3DQEBAQUA
# BIIBAA2JwWgqhVd+MaB1JrLfg5grQ2DTc8q/PZ8bNdheEDjzXQJWyce7CEaWkBgS
# nUXLvsVCHNebgxOfsRuyJu8fxlF87d5BMt+wh72tYV1ahafWkLJZHRHLhbSBlaN4
# j7eNxv3z2dXEQLT29Zwrx/3FuN64/KXaHIW2ec34KlEIXuqIamv2LyQMHi/tNK2G
# 4QtJvhr6mnm96mVU1koZunRExwd1WB8NSnizMar7HhroCFLqNe2QglFqZrAtBLW1
# JXizopJEuASdKOEm3mfFU2visgs1k97Hls5V64KzWDHheJMPSYVv8PGJRzS3Tr89
# sq4nx9HyzqUnKkyhKSOUXE3clEqhgg1+MIINegYKKwYBBAGCNwMDATGCDWowgg1m
# BgkqhkiG9w0BBwKggg1XMIINUwIBAzEPMA0GCWCGSAFlAwQCAQUAMHgGCyqGSIb3
# DQEJEAEEoGkEZzBlAgEBBglghkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQgDHqm
# ihtvn0C/S4AvhsaU1GStbG57FDjmgzLIbKWoYsgCEQDf4MFeiTvZPDn9BAV3bcel
# GA8yMDIxMDYwMTIyMzM1N1qgggo3MIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHO
# FADw3TANBgkqhkiG9w0BAQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhE
# aWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIxMDEw
# MTAwMDAwMFoXDTMxMDEwNjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoT
# DkRpZ2lDZXJ0LCBJbmMuMSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAy
# MTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQikRcpj
# a1HXOhFCvQp1dU2UtAxQtSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cLnGP9
# NmqB+in43Stwhd4CGPN4bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHTWjaP
# xqPhLxs6t2HWc+xObTOKfF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WHIOsO
# jizVI9r0TXhG4wODMSlKXAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6BqrW7Ed
# MMKbaYK02/xWVLwfoYervnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+DUmE
# vQECAwEAAaOCAbgwggG0MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYG
# A1UdJQEB/wQMMAoGCCsGAQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcBMCkw
# JwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNVHSME
# GDAWgBT0tuEgHf4prtLkYaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+vCgt
# HUQ23eNqerwwcQYDVR0fBGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL3NoYTItYXNzdXJlZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRpZ2lj
# ZXJ0LmNvbS9zaGEyLWFzc3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcwJAYI
# KwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZD
# aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJ
# RFRpbWVzdGFtcGluZ0NBLmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctemaI7zn
# GucgDo5nRv1CclF0CiNHo6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+RAJm
# Te1ppA/2uHDPYuj1UUp4eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+t2R3
# Y18jUmmDgvoaU+2QzI2hF3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8gQ74
# wOFcz8QRcucbZEnYIpp1FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1HavWPW
# H1ub9y4bTxMd90oNcX6Xt/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHL
# KNpbh6aKLzCCBTEwggQZoAMCAQICEAqhJdbWMht+QeQF2jaXwhUwDQYJKoZIhvcN
# AQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcG
# A1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJl
# ZCBJRCBSb290IENBMB4XDTE2MDEwNzEyMDAwMFoXDTMxMDEwNzEyMDAwMFowcjEL
# MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3
# LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElE
# IFRpbWVzdGFtcGluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AL3QMu5LzY9/3am6gpnFOVQoV7YjSsQOB0UzURB90Pl9TWh+57ag9I2ziOSXv2Mh
# kJi/E7xX08PhfgjWahQAOPcuHjvuzKb2Mln+X2U/4Jvr40ZHBhpVfgsnfsCi9aDg
# 3iI/Dv9+lfvzo7oiPhisEeTwmQNtO4V8CdPuXciaC1TjqAlxa+DPIhAPdc9xck4K
# rd9AOly3UeGheRTGTSQjMF287DxgaqwvB8z98OpH2YhQXv1mblZhJymJhFHmgudG
# UP2UKiyn5HU+upgPhH+fMRTWrdXyZMt7HgXQhBlyF/EXBu89zdZN7wZC/aJTKk+F
# HcQdPK/P2qwQ9d2srOlW/5MCAwEAAaOCAc4wggHKMB0GA1UdDgQWBBT0tuEgHf4p
# rtLkYaWyoiWyyBc1bjAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAS
# BgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggr
# BgEFBQcDCDB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHoweDA6
# oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElE
# Um9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0QXNzdXJlZElEUm9vdENBLmNybDBQBgNVHSAESTBHMDgGCmCGSAGG/WwAAgQw
# KjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzALBglg
# hkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggEBAHGVEulRh1Zpze/d2nyqY3qzeM8G
# N0CE70uEv8rPAwL9xafDDiBCLK938ysfDCFaKrcFNB1qrpn4J6JmvwmqYN92pDqT
# D/iy0dh8GWLoXoIlHsS6HHssIeLWWywUNUMEaLLbdQLgcseY1jxk5R9IEBhfiThh
# TWJGJIdjjJFSLK8pieV4H9YLFKWA1xJHcLN11ZOFk362kmf7U2GJqPVrlsD0WGkN
# fMgBsbkodbeZY4UijGHKeZR+WfyMD+NvtQEmtmyl7odRIeRYYJu6DC0rbaLEfrvE
# JStHAgh8Sa4TtuF8QkIoxhhWz0E0tmZdtnR79VYzIi8iNrJLokqV2PWmjlIxggKG
# MIICggIBATCBhjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBT
# SEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBAhANQkrgvjqI/2BAIc4UAPDd
# MA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAc
# BgkqhkiG9w0BCQUxDxcNMjEwNjAxMjIzMzU3WjArBgsqhkiG9w0BCRACDDEcMBow
# GDAWBBTh14Ko4ZG+72vKFpG1qrSUpiSb8zAvBgkqhkiG9w0BCQQxIgQg505oIQTs
# KtAH52KwOUznMmM5AMFlEVteWFv46rAl9YkwNwYLKoZIhvcNAQkQAi8xKDAmMCQw
# IgQgsxCQBrwK2YMHkVcp4EQDQVyD4ykrYU8mlkyNNXHs9akwDQYJKoZIhvcNAQEB
# BQAEggEAeA7b5QOKliLmnKgxs9/OmsnxGPe0XXlT+hwe/mX/KXkiU691cGQAY1yS
# qkZe4EqpRCeya8ZThpXqd7NBlkgpgJHr+WK2uYIOUbeQjzNk+SjbfDhv5MzykySk
# l3NUPWG2dAgIGgrNNcAl76+WF9/0IRFFZZe8qJT6DnShozh/Ox1Wd5Rl5TVnRJWO
# IdVdjI1zVTla7z4Axf2nWcsasoxGXscyTXDqGk2oSrmRnIS8upNQcL0qnbuT0NYN
# taWWsaolHJFzIVm9/OXUtL1s9vK+uKFyegn4HhC+Nih25t+BMUmv3JGLxNVXiXrG
# TkyJIdakf62pSkxx7Gpeo17vxR1GAg==
# SIG # End signature block
