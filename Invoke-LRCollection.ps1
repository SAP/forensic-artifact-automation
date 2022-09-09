<#
.SYNOPSIS
	MDE Live Response Triage Collection script.
.DESCRIPTION
	This script was designed to be used from a Microsoft Defender for Endpoint Live Response terminal on a suspected compromised host.
    
    This will download all required files to the target machine, extract and run "Invoke-LRCollection.ps1" script, which collects triage artifacts and memory images that are useful for IR investigations. 

    All flags passed with the execution script will also be passed in the "Invoke-LRCollection.ps1" script. By default, "Invoke-LRCollection.ps1" will not collect browser artifacts. Use -browser flag to collect web browser artifacts with collection.
.PARAMETER casenum
	Ticket number for case identification.
.PARAMETER skipcheck
    Skip available drive space verification prior to collection.
.PARAMETER skipmem
    Skip memory collection.
.PARAMETER browseronly
    Only collects web browser artifacts.  If additional artifacts are also desired, use -browser flag instead.
.PARAMETER browser
    Additional flag to collect browser artifacts. If only browser artifacts are desired, use -browseronly flag instead.
.EXAMPLE
	PS> ./Invoke-LRCollection.ps1 -casenum SIR0000000 

    Memory acquisition and triage collection without browser artifacts.
.EXAMPLE   
    PS> ./Invoke-LRCollection.ps1 -casenum SIR0000000 -browser

    Memory acquisition and triage collection with browser artifacts.
.EXAMPLE
    PS> ./Invoke-LRCollection.ps1 -casenum SIR0000000 -skipmem -browser

    Triage collection, with browser artifacts. No memory acquisition.
.EXAMPLE
    PS> ./Invoke-LRCollection.ps1 -casenum SIR0000000 -browseronly
    
    Only collect browser artifacts
.LINK
	Will be released shortly.
.NOTES
	Authors: Lukas Klein and Jason Ballard 
#>

param( 
    [Parameter(Mandatory=$true, HelpMessage="Specify the incident number.")] $casenum,
    [Parameter(Mandatory=$false, HelpMessage="Set if you want to skip the storage check")] [Switch]$skipcheck,
    [Parameter(Mandatory=$false, HelpMessage="Set if you want to skip the memory collection")] [Switch]$skipmem,
    [Parameter(Mandatory=$false, HelpMessage="Set if you only want to collect web browser artifacts")] [Switch]$browseronly,
    [Parameter(Mandatory=$false, HelpMessage="Set if you want to collect web browser artifacts")] [Switch]$browser  
    )

# Perform input validation for SIR number
$casenum = $casenum.ToUpper()
if (-not ($casenum -match "^SIR[0-9]{7}$")) {
    throw "Invalid SIR number provided"
    Exit
}

# Make directory for collection
New-Item -Path "$env:SystemDrive\Windows\FAA\$casenum" -ItemType Directory
$outputpath = "$env:SystemDrive\Windows\FAA\$casenum" 
Set-Location "$outputpath"

# Download triage_kit.zip
Invoke-WebRequest -Uri "http://gso-image-collection-dependencies.s3-website.eu-central-1.amazonaws.com/ArtifactCollector.zip" -OutFile ArtifactCollector.zip

# Exit if file hash of downloaded archive doesn't match our expectation
if (! ((Get-FileHash -Algorithm SHA256 .\ArtifactCollector.zip).Hash -eq "1E63D1CC97B277BA942A0359507B320AD387A4A9156800A9BBF302F90E22CAC2") ) {
    Write-Output "Integrity Error: Unexpected File Hash"
    exit
}

# unzip triage kit
Expand-Archive -Path .\ArtifactCollector.zip -DestinationPath .\
Remove-Item .\ArtifactCollector.zip

# invoke image collection process
Set-Location .\ArtifactCollector\
$flag = "-casenum $casenum"

if ($skipcheck -eq $true){ $flag = $flag + " -skipcheck"}
if ($skipmem -eq $true){ $flag = $flag + " -skipmem"}
if ($browser -eq $true -and $browseronly -ne $true){ $flag = $flag + " -browser"}
if ($browseronly -eq $true -and $browser -ne $true){ $flag = $flag + " -browseronly"}
if ($browseronly -and $browser -eq $true){ 
    throw "Both browser options '-browser' and '-browseronly' can not be used concurrently. Please select either option or see Get-Help menu for details."
    Exit
    }

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ".\Invoke-TriageCollection.ps1 $flag"

# Check for artifacts that couldn't be uploaded
$RemainingArtifacts = Get-ChildItem -Recurse -Path "$outputpath" `
    | foreach-object { $_.FullName } `
    | Select-String -Pattern "\.(7z|key)$"

# Delete entire working dir if upload successful
if (($RemainingArtifacts | Measure-Object).Count -eq 0) {
    Set-Location "$env:SystemDrive\"
    cmd /c RMDIR "$env:SystemDrive\Windows\FAA" /S /Q
} 
# Show paths of artifacts that couldn't be uploaded
else {
    Write-Output "Upload of the following artifacts failed:"
    $RemainingArtifacts
}
