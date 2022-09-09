<#
.SYNOPSIS
	Upload collections that encountered network issues during upload process and were transferred to another machine.
.DESCRIPTION
	This script is designed for ease of uploading a collection that encountered an error during the collection process while running either 'Invoke-TriageCollection.ps1' or 'Invoke-LRCollection.ps1'.  

    When uploading a collection during this process fails, it will be renamed for this script. If multiple collections fail, transfer all collections to a single directory on a machine that has network connectivity, then run this script.  It will recursively upload all files in the selected directory.

.PARAMETER path
	The directory containing triage collections.  These should have been transferred to a machine with network connectivity.
.EXAMPLE
	PS> ./Invoke-LocalUpload.ps1 -path "C:\Path\containing\collection"

    Will take collections that had network issues during collection and upload them with proper naming convention to AWS S3.

.LINK
	https://github.wdf.sap.corp/Global-Security-Operations/Forensic-Artifact-Acquisition
.NOTES
	Authors: Lukas Klein and Jason Ballard 
#>

############ PARAMETER DEF BLOCK ############
param( 
    [Parameter(Mandatory=$true, HelpMessage="Enter path containing triage collections. C:\Path\to\directory")] $path
    #[Parameter(Mandatory=$true, HelpMessage="Enter path to extract collection to. C:\Path\to\directory")] $out
    )
############ END PARAMETER BLOCK ############

############ EDIT THIS SECTION ############
$BucketName = "your-bucket-name"
$AccessKey = "YourAWSAccessKey" 
$SecretKey = "YourAWSSecretKey"
############ END VARIABLE BLOCK ############

# Import AWS Modules that are required for the S3 upload
Import-Module ".\AWS.Tools.4.1.13.0\AWS.Tools.Common\AWS.Tools.Common.psd1"
Import-Module ".\AWS.Tools.4.1.13.0\AWS.Tools.S3\AWS.Tools.S3.psd1"

$full = (Get-ChildItem -Recurse $path -Include *.7z,*.key)

foreach($file in $full){
    # Set variables for upload
    $key = $file.Name.Replace('%','/')
    $uploadfile = $file.FullName

    # Upload encrypted artifacts
    try{
        Write-S3Object -BucketName "$BucketName" -UseAccelerateEndpoint `
        -AccessKey "$AccessKey" -SecretKey "$SecretKey" `
        -File "$uploadfile" -Key "$key"

        Remove-Item -Path "$uploadfile" -Force  
    }catch{
        Write-host "Upload failed.  Check connection and naming convention in specified directory."
    }
}