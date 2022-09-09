function AWSToolsImportGuard() {
    Microsoft.PowerShell.Core\Set-StrictMode -Version 3

    [string[]]$rootModules = @( 'AWSPowerShell', 'AWSPowerShell.NetCore', 'AWS.Tools.Common' )

    foreach ($rootModule in $rootModules) {
        [string]$version = Microsoft.PowerShell.Core\Get-Module -Name $rootModule | Select-Object -First 1 -ExpandProperty Version
        if ($version) {
            [string]$message = "$rootModule version $version is currently imported. Only a single version of a single variant of AWS Tools for PowerShell (AWSPowerShell, AWSPowerShell.NetCore or AWS.Tools.Common) can be imported at any time."

            [System.Management.Automation.PSModuleInfo[]]$importingModule = Get-Module "$PSScriptRoot/*.psd1" -ListAvailable
            if ($importingModule.Count -eq 1) {
                if ($PSVersionTable.PSVersion.Major -ge 5) {
                    [System.Collections.Hashtable]$importingModuleData = Microsoft.PowerShell.Utility\Import-PowerShellDataFile $importingModule.Path
                    $message = "Module $($importingModule.Name) version $($importingModuleData.ModuleVersion) failed importing. " + $message
                } else {
                    $message = "Module $($importingModule.Name) failed importing. " + $message
                }
            }

            throw $message
        }
    }

    [System.Management.Automation.PSModuleInfo[]]$installedAWSToolsModules = Microsoft.PowerShell.Core\Get-Module -Name 'AWS.Tools.*' -ListAvailable | Where-Object { $_.Name -ne 'AWS.Tools.Installer' }
    if ($installedAWSToolsModules) {
        [System.Version]$maxAWSToolsVersion = $installedAWSToolsModules | Select-Object -ExpandProperty Version | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
        [string[]]$maxVersionModules = $installedAWSToolsModules | Where-Object { $_.Version -eq $maxAWSToolsVersion } | Select-Object -ExpandProperty Name | Sort-Object -Unique
        [string[]]$prevVersionsModules = $installedAWSToolsModules | Where-Object { $_.Version -ne $maxAWSToolsVersion } | Select-Object -ExpandProperty Name | Sort-Object -Unique
        if ($prevVersionsModules | Where-Object { -not $maxVersionModules.Contains($_) }) {
            if (Get-Module 'AWS.Tools.Installer' -ListAvailable) {
                Write-Warning 'You have mismatched versions of the AWS.Tools modules. You can use Update-AWSToolsModule to synchronize the versions of all installed AWS.Tools modules.'
            } else {
                Write-Warning 'You have mismatched versions of the AWS.Tools modules. You can run ''Install-Module AWS.Tools.Installer ; Update-AWSToolsModule'' to synchronize the versions of all installed AWS.Tools modules.'
            }
        }
    }

    [int]$installedModuleVariants = Microsoft.PowerShell.Core\Get-Module -Name $rootModules -ListAvailable | Group-Object -Property Name -NoElement | Measure-Object | Select-Object -ExpandProperty Count
    if ($installedModuleVariants -gt 1) {
        Write-Warning 'Multiple variants of AWS Tools for PowerShell (AWSPowerShell, AWSPowerShell.NetCore or AWS.Tools) are currently installed. Please run ''Get-Module -Name AWSPowerShell,AWSPowerShell.NetCore,AWS.Tools.Common -ListAvailable'' for details. To avoid problems with cmdlet auto-importing, it is suggested to only install one variant.
AWS.Tools is the new modularized version of AWS Tools for PowerShell, compatible with PowerShell Core 6+ and Windows Powershell 5.1+ (when .NET Framework 4.7.2+ is installed).
AWSPowerShell.NetCore is the monolithic variant that supports all AWS services in a single large module, it is compatible with PowerShell Core 6+ and Windows Powershell 3+ (when .NET Framework 4.7.2+ is installed).
AWSPowerShell is the legacy module for older systems which are either running Windows PowerShell 2 or cannot be updated to .NET Framework 4.7.2 (or newer).'
    }
}

AWSToolsImportGuard
# SIG # Begin signature block
# MIIa4gYJKoZIhvcNAQcCoIIa0zCCGs8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDtZJivv/fntZDI
# 2NIfQhXcSxPUU3+2CFiuqxVOA96QKqCCCoYwggUwMIIEGKADAgECAhAECRgbX9W7
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
# IK2uSFlxfhO6aMjMzLr2MsOekQpGeNd4ElRJJ4n2sxqwMA0GCSqGSIb3DQEBAQUA
# BIIBADT/dsA5pKXWZ5QOWV4nw/DwEdaUDOROm8kIjtHsnZqsjtSejkdMUv/jjOXi
# Xn0H8sr+COGOcpX/gwEMj0mDR0FxcBWGWVVcXg3qqkrMMI5QO1lnR90wzhVmWrRF
# n40NTkY5Xnb8KK0SPssyjDjyP04ywQuLN1LCVCzxj1z9fRkH0DheVxPz21yCwDCJ
# 6tXN4xVwU+FZtbWYPd0sSPKkziuY+zlUdpCMbT604pNY81LdbCbBvMbjcBO+Lpkq
# PkKpaf8xHs9Xceh6xMbGMe/0VOjvDZJ5USPEfSTW61PsmmqIm/iM6zAZZC4QpgQe
# GOW+aNlhbHZ18Mm3eeAEF3cYmpWhgg1+MIINegYKKwYBBAGCNwMDATGCDWowgg1m
# BgkqhkiG9w0BBwKggg1XMIINUwIBAzEPMA0GCWCGSAFlAwQCAQUAMHgGCyqGSIb3
# DQEJEAEEoGkEZzBlAgEBBglghkgBhv1sBwEwMTANBglghkgBZQMEAgEFAAQg/bTF
# s/Hg/Woc6OAztOf8wMqg0L1L7O6rQIwsZKxqLwsCEQDnyHow7wNY8f1olXUlERYh
# GA8yMDIxMDYwMTIyMzE0OVqgggo3MIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHO
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
# BgkqhkiG9w0BCQUxDxcNMjEwNjAxMjIzMTQ5WjArBgsqhkiG9w0BCRACDDEcMBow
# GDAWBBTh14Ko4ZG+72vKFpG1qrSUpiSb8zAvBgkqhkiG9w0BCQQxIgQgSzJDl2yG
# KAHEIoMFbM8NX+PO+hYt5qj3T1IUu2jOStgwNwYLKoZIhvcNAQkQAi8xKDAmMCQw
# IgQgsxCQBrwK2YMHkVcp4EQDQVyD4ykrYU8mlkyNNXHs9akwDQYJKoZIhvcNAQEB
# BQAEggEAQeFmp3MwYhurkAuXfpzJEGcFyd6u4gVdAPrViP8ccqpdZPD8IrHsIskp
# AN4cgvdF5JGGcI9masIHCT7k3O7sdpV50+GolUK0oi0JmPn7sx6Q9SkRx9HwtArM
# zK6R4GcjnPM3ps5aCNcEc+hOAYx3CN886/lHZqH9p+nvIhw/1pdDKYiWDWOe0etx
# gchhby1SuVo796ZHNS4MHAZeLYh9kxjwoI/+RmzSTaBC8Iuk9iF/MRCsq+u0ezGX
# 9t50msPmR/U/mfuIDJBHlV9bK2HyxWSx/G4zjXj/X13d/YmAhXLnn0DQE0W3m28p
# w7Ff6fMQ/kdMRQjKOxIS8HVtoCJXrg==
# SIG # End signature block
