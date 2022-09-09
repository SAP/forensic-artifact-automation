<#
.SYNOPSIS
	Downloads artifact collections.
.DESCRIPTION
	This downloads a specified case that was collected by either Invoke-TriageCollection.ps1 or Invoke-LRCollection.ps1.  It will download, decrypt, extract collections to the C:\Cases directory.  All encrypted collections will be deleted after extraction.
.PARAMETER casenum
	Ticket number for case identification.
.EXAMPLE
	PS> ./Invoke-ArtifactDownload.ps1 -casenum SIR0000000 

    Downloads and decrypts all files collected for case SIR0000000.
.LINK
	Will be released shortly.
.NOTES
	Authors: Lukas Klein and Jason Ballard 
#>

param( [Parameter(Mandatory=$true, HelpMessage="Specify the incident number.")] $casenum )

############ EDIT THIS SECTION ############
$BucketName = "your-bucket-name"
$TicketRegex = "^SIR[0-9]{7}$" # regex to match ticket or case number, Current is ServiceNow
############ END VARIABLE BLOCK ############

# Import AWS Modules that are required for the S3 upload
Import-Module ".\AWS.Tools.4.1.13.0\AWS.Tools.Common\AWS.Tools.Common.psd1"
Import-Module ".\AWS.Tools.4.1.13.0\AWS.Tools.S3\AWS.Tools.S3.psd1"

# List objects in buckets
# https://docs.aws.amazon.com/powershell/latest/reference/items/Get-S3ObjectV2.html
$S3_Keys = (Get-S3ObjectV2 -BucketName "$BucketName" -UseAccelerateEndpoint `
    -AccessKey $Env:AWS_ACCESS_KEY_ID -SecretKey $Env:AWS_SECRET_ACCESS_KEY).Key `
    | Select-String -Pattern "^$casenum\/.*" `
    | foreach-object { $_.Matches } `
    | foreach-object {$_.Groups[0].Value} `
    | Get-Unique `
    | Sort-Object

foreach ($Key in $S3_Keys) {
    # Create download log on first startup
    if (-Not (Test-Path "$env:SystemDrive\Cases\Downloads.log")) {
        New-Item -ItemType "directory" -Path "$env:SystemDrive\Cases\"
        New-Item -ItemType "file" -Path "$env:SystemDrive\Cases\Downloads.log"
    }

    # Check if file already downloaded
    $ArtifactDownloaded = Get-Content "$env:SystemDrive\Cases\Downloads.log" | Where-Object {$_ -like $Key}

    # Skip file if already downloaded
    if ($ArtifactDownloaded.Count -gt 0) {
        continue
    }

    # Mark artifact as downloaded
    $Key | Out-File -FilePath "$env:SystemDrive\Cases\Downloads.log" -Append

    # Download artifact
    Read-S3Object -BucketName"$BucketName" -UseAccelerateEndpoint `
        -AccessKey $Env:AWS_ACCESS_KEY_ID -SecretKey $Env:AWS_SECRET_ACCESS_KEY `
        -Key $Key -File "$env:SystemDrive\Cases\$Key"
    
    # Check if current file is a key file. If so, use it to decrypt artifact
    # Key files are always downloaded after the encrypted artifact
    if ($Key.endswith(".key")) {
        # decrypt symmetric key with private GSO key
        $SYMM_KEY = Unprotect-CmsMessage -Path "$env:SystemDrive\Cases\$Key"

        # Get path of encrypted archive
        $EncryptedArtifact = $Key.replace('.key', '.7z')

        # Get parent directory for zip output
        $ParentDirectory = $Key | Split-Path

        # decrypt encrypted archive with symmetric key
        & "$PSScriptRoot\7za.exe" x "$env:SystemDrive\Cases\$EncryptedArtifact" -o"$env:SystemDrive\Cases\$ParentDirectory" -p"$SYMM_KEY"

       #delete encrypted artifacts to save space
       Remove-Item "$env:SystemDrive\Cases\$Key"
       Remove-Item "$env:SystemDrive\Cases\$EncryptedArtifact"
    }
}
