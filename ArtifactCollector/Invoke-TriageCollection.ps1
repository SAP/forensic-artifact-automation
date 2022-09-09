<#
.SYNOPSIS
	Triage and memory acquisition script.
.DESCRIPTION
	Collects triage artifacts and memory images that are useful for IR investigations. Initially designed to be ran from Microsoft Defender for Endpoint 'Live Response' terminal.
    
By default, this script will not collect browser artifacts. Use -browser flag to collect web browser artifacts with collection.
.PARAMETER casenum
	ServiceNow ticket number for case identification.
.PARAMETER skipcheck
    Skip available drive space verification prior to collection.
.PARAMETER skipmem
    Skip memory collection.
.PARAMETER browseronly
    Only collects web browser artifacts.  If additional artifacts are also desired, use -browser flag instead.
.PARAMETER browser
    Additional flag to collect browser artifacts. If only browser artifacts are desired, use -browseronly flag instead.
.EXAMPLE
	PS> ./Invoke-TriageCollection.ps1 -casenum SIR0000000 

    Memory acquisition and triage collection without browser artifacts.
.EXAMPLE   
    PS> ./Invoke-TriageCollection.ps1 -casenum SIR0000000 -browser

    Memory acquisition and triage collection with browser artifacts.
.EXAMPLE
    PS> ./Invoke-TriageCollection.ps1 -casenum SIR0000000 -skipmem -browser

    Triage collection, with browser artifacts. No memory acquisition.
.EXAMPLE
    PS> ./Invoke-TriageCollection.ps1 -casenum SIR0000000 -browseronly
    
    Only collect browser artifacts
.LINK
	Will be released shortly.
.NOTES
	Authors: Lukas Klein and Jason Ballard 
#>

############ PARAMETER DEF BLOCK ############

param( 
    [Parameter(Mandatory=$true, HelpMessage="Specify the incident number.")] $casenum, 
    [Parameter(Mandatory=$false, HelpMessage="Set if you want to skip the storage check")] [Switch]$skipcheck,
    [Parameter(Mandatory=$false, HelpMessage="Set if you want to skip the memory collection")] [Switch]$skipmem,
    [Parameter(Mandatory=$false, HelpMessage="Set if you only want to collect web browser artifacts")] [Switch]$browseronly,
    [Parameter(Mandatory=$false, HelpMessage="Set if you want to collect web browser artifacts")] [Switch]$browser 
    )

############ EDIT THIS SECTION ############
$BucketName = "your-bucket-name"
$AccessKey = "YourAWSAccessKey" 
$SecretKey = "YourAWSSecretKey"
$SurgePass = "SurgePasswordProvided"
$PubCert = ".\pubkey.cer" # Name of public cert and location
$TicketRegex = "^SIR[0-9]{7}$" # regex to match ticket or case number, Current is ServiceNow
############ END VARIABLE BLOCK ############

# Perform input validation for case number
$casenum = $casenum.ToUpper()
if (-not ($casenum -match "$TicketRegex")) {
    throw "Invalid case number provided. This should match the following regex " + $TicketRegex + " Please enter a valid case number."
    Exit
}

# self-elevate privileges and pass through SIR number and SkipCheck
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        if($skipcheck -eq $true){
            $CommandLine = "-File " + $MyInvocation.MyCommand.Path + " -casenum $casenum -skipcheck"
        } else {
            $CommandLine = "-File " + $MyInvocation.MyCommand.Path + " -casenum $casenum"
        }
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

############ END PARAMETER BLOCK ############

############ FUNCTION DEF BLOCK ############
function local:requestMutex($mtx_id) {

    # creating the mutex without taking ownership
    $mtx = New-Object System.Threading.Mutex($false, $mtx_id)
    $mtx_handle = $mtx.Handle

    # requesting ownership
    if ($mtx.WaitOne(10)) {
        Write-Output "[x] mutex ownership of '$mtx_id' (handle $mtx_handle) taken"

    } else { # terminate if takeover fails
        Write-Error "mutex ownership of '$mtx_id' DENIED"
        Read-Host -Prompt "Press Enter to exit"
        throw "Parallel execution of script detected. Please terminate process or tidy up mutex."
    }

    return $mtx
}

function local:releaseMutex($mtx) {
    $mtx_handle = $mtx.Handle
    $mtx.ReleaseMutex
    Write-Output "[x] mutex handle $mtx_handle released"
}

function local:Encrypt-ArtifactFolder($ArtifactPath) {
    $ArtifactFolder = Split-Path -Path "$ArtifactPath" -Leaf
    $HostName = Split-Path -Path "$ArtifactPath\.." -Leaf
    $casenum = Split-Path -Path "$ArtifactPath\..\.." -Leaf

    # Check if folder follows defined directory structure
	# This prevents accidental uploads of plaintext files
    if (-not ($casenum -match "$TicketRegex") -or
        -not ($HostName -eq $env:COMPUTERNAME) -or
        -not ($ArtifactFolder -match "^[0-9]{8}T[0-9]{6}Z_.*$")) {
        throw 'Encryption Failed: Folder not following expected directory structure'
    }
    
	# Generate symmetric key and seal it with GSO public key
	$SYMM_KEY = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    Protect-CmsMessage -Content $SYMM_KEY -To "$PubCert" -OutFile "$ArtifactPath\..\$ArtifactFolder.key"

	# Encrypt and compress artifact folder:
    .\7za.exe a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhe=on -p"$SYMM_KEY" "$ArtifactPath\..\$ArtifactFolder.7z" "$ArtifactPath"

	# Remove plaintext files after encryption
    cmd /c RMDIR "$ArtifactPath" /S /Q
}

function local:Upload-EncryptedArtifactFolder ($ArtifactPath) {
    $Artifact = Split-Path -Path "$ArtifactPath" -Leaf
    $HostName = Split-Path -Path "$ArtifactPath\.." -Leaf
    $casenum = Split-Path -Path "$ArtifactPath\..\.." -Leaf        
    $ArchivePath = "$ArtifactPath\..\" + "$Artifact.7z"
    $KeyPath = "$ArtifactPath\..\" + "$Artifact.key"

    # Check if folder follows the defined directory structure
	# This prevents accidental uploads of plaintext files
    if (-not ($casenum -match "$TicketRegex") -or
        -not ($HostName -eq $env:COMPUTERNAME) -or
        -not (Test-Path -Path "$ArchivePath") -or
        -not (Test-Path -Path "$KeyPath")) {
        throw 'Upload failed: Folder not following expected directory structure'
    }

    try {
	    # Upload encrypted artifact folder
	    Write-S3Object -BucketName "$BucketName" -UseAccelerateEndpoint `
        -AccessKey "$AccessKey" -SecretKey "$SecretKey" `
        -File "$ArchivePath" -Key "$casenum/$HostName/$Artifact.7z"

        # Upload sealed symmetric key
	    Write-S3Object -BucketName "$BucketName" -UseAccelerateEndpoint `
        -AccessKey "$AccessKey" -SecretKey "$SecretKey" `
        -File "$KeyPath" -Key "$casenum/$HostName/$Artifact.key" 
    } catch { 
        # Output error if upload fails
        Write-Error "Upload failed: Connectivity issues" 
        Rename-Item -Path $ArchivePath -NewName "$casenum%$HostName%$Artifact.7z"
        Rename-Item -Path $KeyPath -NewName "$casenum%$HostName%$Artifact.key"
        # Output full path for identification to export
        return
    }

    # Delete files if upload successful
    Remove-Item -Path "$ArchivePath" -Force
    Remove-Item -Path "$KeyPath" -Force
}

function local:CheckDiskSpace () {
    $SizeRamMB   = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum / 1mb
    $FreeSpaceMB = (Get-CimInstance -Class Win32_LogicalDisk | Where-Object DeviceID -EQ $env:SystemDrive).FreeSpace / 1mb

    if (2*$SizeRamMB -gt $FreeSpaceMB) {
        Write-Error "Not enough space left on disk"
        Read-Host -Prompt "Press Enter to exit"
        throw "Not enough space left on disk"
    }
}

############ END FUNCTION BLOCK ############

############### SCRIPT BLOCK ###############

if ($skipcheck -ne $true) {
    CheckDiskSpace
}

# mutex name
$mtx = requestMutex('GSO')

# prevent windows from sleep
Powercfg /x -standby-timeout-ac 0

Set-Location "$PSScriptRoot"

# Import AWS Modules that are required for the S3 upload
Import-Module ".\AWS.Tools.4.1.13.0\AWS.Tools.Common\AWS.Tools.Common.psd1"
Import-Module ".\AWS.Tools.4.1.13.0\AWS.Tools.S3\AWS.Tools.S3.psd1"

# Prepare output folder for memory capture, then collect memory
if ($skipmem -ne $true) {
    $TimeUTC = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    $SurgePath = ".\Output\$casenum\$env:COMPUTERNAME\"+$TimeUTC+"_SurgeMem\"
    New-Item -Type Directory -Path "$SurgePath" 
    .\surge-collect.exe "$SurgePass" "$SurgePath"
}

# Prepare output folder for triage collection
$TimeUTC = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$KapePath = ".\Output\$casenum\$env:COMPUTERNAME\"+$TimeUTC+"_KapeTriage\"
New-Item -Type Directory -Path "$KapePath"

# collect triage image, optional browser artifact collection with -browser flag.  Special thanks to DPO for this
if($browser -eq $false -and $browseronly -eq $false){
    .\kape.exe --tsource "$env:SystemDrive" --tdest "$KapePath" --target SAP-IR-Collect --zv false
}
elseif($browser -eq $true){
    .\kape.exe --tsource "$env:SystemDrive" --tdest "$KapePath" --target SAP-IR-Collect,WebBrowsers --zv false
}
elseif($browseronly -eq $true){
    .\kape.exe --tsource "$env:SystemDrive" --tdest "$KapePath" --target WebBrowsers --zv false
}
# compress, encrypt & upload triage image
Encrypt-ArtifactFolder("$KapePath")
Upload-EncryptedArtifactFolder("$KapePath")

# compress, encrypt & upload memory image
if ($skipmem -ne $true) {
    Encrypt-ArtifactFolder("$SurgePath")
    Upload-EncryptedArtifactFolder("$SurgePath")
}

# relase mutex
releaseMutex($mtx)

#Read-Host -Prompt "Press Enter to exit"
