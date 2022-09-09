<#
.SYNOPSIS
	Processing script to enrich collections with processed data.
.DESCRIPTION
	This downloads a specified case that was collected, download and extract it, process the artifacts, then upload to another AWS S3 bucket.
.PARAMETER casenum
	Ticket number for case identification.
.EXAMPLE
	PS> ./Invoke-ArtifactProcessing.ps1 -casenum SIR0000000 

    Downloads and decrypts all files collected for case SIR0000000.
.LINK
	Will be released shortly.
.NOTES
	Authors: Lukas Klein and Jason Ballard 
#>

############ EDIT THIS SECTION ############
$BucketName = "your-bucket-name"
$KapeDir = "C:\Users\Administrator\Desktop\Kape\kape.exe" # Location of kape.exe
$TicketRegex = "^SIR[0-9]{7}$" # regex to match ticket or case number, Current is ServiceNow
############ END VARIABLE BLOCK ############

function local:Encrypt-ArtifactFolder($ArtifactPath) {
    $ArtifactFolder = Split-Path -Path "$ArtifactPath\.." -Leaf
    $casenum = Split-Path -Path "$ArtifactPath\..\..\.." -Leaf
    $OutFolder = ($ArtifactFolder + "_output")

    # Check if folder follows defined directory structure
	# This prevents accidental uploads of plaintext files
    if (-not ($casenum -match "$TicketRegex") -or
        -not ($ArtifactFolder -match "^[0-9]{8}T[0-9]{6}Z_.*")) {
        throw 'Encryption Failed: Folder not following expected directory structure'
    }

	# Generate symmetric key and seal it with public key
	$SYMM_KEY = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})
    Protect-CmsMessage -Content $SYMM_KEY -To "..\ArtifactCollector\pubkey.cer" -OutFile "$ArtifactPath\..\..\$OutFolder.key"

	# Encrypt and compress artifact folder:
    .\7za.exe a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhe=on -p"$SYMM_KEY" "$ArtifactPath\..\..\$OutFolder.7z" "$ArtifactPath"

	# Remove plaintext files after encryption
    Remove-Item -Recurse -Force "$ArtifactPath"
}

function local:Upload-EncryptedArtifactFolder ($ArtifactPath) {
    $Artifact = Split-Path -Path "$ArtifactPath\.." -Leaf
    $HostName = Split-Path -Path "$ArtifactPath\..\.." -Leaf
    $casenum = Split-Path -Path "$ArtifactPath\..\..\.." -Leaf   
    $OutFolder = ($Artifact + "_output")     
    $ArchivePath = "$ArtifactPath\..\..\" + "$OutFolder.7z"
    $KeyPath = "$ArtifactPath\..\..\" + "$OutFolder.key"
    
    
    # Check if folder follows the defined directory structure
	# This prevents accidental uploads of plaintext files
    if (-not ($casenum -match "$TicketRegex") -or
        -not (Test-Path -Path "$ArchivePath") -or
        -not (Test-Path -Path "$KeyPath")) {
        throw 'Upload failed: Folder not following expected directory structure'
    }
    
    # Upload encrypted artifact folder
	Write-S3Object -BucketName "$BucketName" -UseAccelerateEndpoint `
    -AccessKey $Env:AWS_ACCESS_KEY_ID -SecretKey $Env:AWS_SECRET_ACCESS_KEY `
    -File "$ArchivePath" -Key "$casenum/$HostName/$OutFolder.7z"

    # Upload sealed symmetric key
	Write-S3Object -BucketName "$BucketName" -UseAccelerateEndpoint `
    -AccessKey $Env:AWS_ACCESS_KEY_ID -SecretKey $Env:AWS_SECRET_ACCESS_KEY `
    -File "$KeyPath" -Key "$casenum/$HostName/$OutFolder.key"
}

Import-Module ".\AWS.Tools.4.1.13.0\AWS.Tools.Common\AWS.Tools.Common.psd1"
Import-Module ".\AWS.Tools.4.1.13.0\AWS.Tools.S3\AWS.Tools.S3.psd1"

$S3_Keys = (Get-S3ObjectV2 -BucketName "$BucketName" -UseAccelerateEndpoint `
    -AccessKey $Env:AWS_ACCESS_KEY_ID -SecretKey $Env:AWS_SECRET_ACCESS_KEY).Key `
    | Select-String -Pattern "$TicketRegex\/.*KapeTriage\.(7z|key)$" `
    | foreach-object { $_.Matches } `
    | foreach-object {$_.Groups[0].Value} `
    | Get-Unique `
    | Sort-Object

# Create download log on first startup
if(-not (Test-Path "$env:SystemDrive\Cases\")){
    New-Item -ItemType "directory" -Path "$env:SystemDrive\Cases\"
}elseif(-not (Test-Path "$env:SystemDrive\Cases\Downloads.log")){
    New-Item -ItemType "file" -Path "$env:SystemDrive\Cases\Downloads.log"
}else {
    Continue
}

foreach ($Key in $S3_Keys) {

    # Check if file already downloaded
    $ArtifactDownloaded = Get-Content "$env:SystemDrive\Cases\Downloads.log" | Where-Object {$_ -like $Key}

    # Skip file if already downloaded
    if ($ArtifactDownloaded.Count -gt 0) {
        continue
    }

    # Mark artifact as downloaded
    $Key | Out-File -FilePath "$env:SystemDrive\Cases\Downloads.log" -Append

    # Download artifact
    Read-S3Object -BucketName "$BucketName" -UseAccelerateEndpoint `
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

$ParentDir = Get-childitem -Recurse -Depth 2 "$env:SystemDrive\Cases" -Directory -Filter *_KapeTriage| Select-Object  Fullname 
foreach ($Dir in $ParentDir){

    # Get Source and Destination Variables. $mdest will be cleared (flushed) on execution.
    $msource = ($Dir.FullName + "\C")
    $mdest = ($Dir.FullName + "\output")

    # Run Kape processing on each triage image
    $KapeDir --msource $msource --mdest $mdest --mflush --module 'Chainsaw,EvtxECmd,MFTECmd,PECmd,AmcacheParser,RecentFileCacheParser,AppCompatCacheParser,RECmd_Kroll,JLECmd,LECmd' --mvars Computername:$HostName
   
    # Define $KapePath for encryption & upload
    $KapePath = $mdest

    # Encrypt & upload triage image
    Encrypt-ArtifactFolder("$KapePath") 
    Upload-EncryptedArtifactFolder("$KapePath") 
    }