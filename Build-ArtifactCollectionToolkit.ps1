<#
.SYNOPSIS
    Downloads the latest version of KAPE and builds the artifact collection toolkit.
.EXAMPLE
    PS> Build-ArtifactCollectionToolkit.ps1
.NOTES
#>

### START SETTINGS AREA ###

# Name of the collection toolkit archive
$artifactCollectionToolkitArchiveName = "ArtifactCollectionToolkit.zip"

# Path to the build folder
$buildFolderPath = [System.IO.Path]::Combine("$PSScriptRoot", "build")

# Name of the 7zip executable
$7ZipExecutableName = "7zr.exe"

# URL to download the 7zip executable
$7ZipDownloadURL = "https://7-zip.org/a/$7ZipExecutableName"

# Name of the KAPE archive
$kapeArchiveName = "kape.zip"

# URL from which KAPE can be downloaded
$kapeDownloadURL = "<URL to download KAPE. Should be acquired from KROLL'S Webpage>"

# URL from which the KAPE-files can be downloaded
$kapeFilesDownloadURL = "https://github.com/EricZimmerman/KapeFiles/archive/master.zip"

# Name of the AWS-Tools
$psModulesAwsArchiveName = "AWS.Tools.zip"

# URL from which the AWS Tools can be downloaded
$psModulesAwsURL = "https://sdk-for-net.amazonwebservices.com/ps/v4/latest/$psModulesAwsArchiveName"

### END SETTINGS AREA ###

### START BUILD VARIABLES ###

# Build variables for other PowerShell scripts
# -----
# !!!! Please remind the escaping of characters here to avoid variables being taken from your local machine!
# -----
$buildVariables = @{
    # Path to the 7zip executable
    "7ZipExecutablePath" = "`$([System.IO.Path]::Combine(`"`$PSScriptRoot`", `"$7ZipExecutableName`"))";

    # Name of the archive which contains the artifacts for uploading
    "artifactArchiveName" = "`$(`$timeUTC)_`$(`$MachineName)_Artifacts.7z";

    # Name of the collection toolkit archive
    "artifactCollectionToolkitArchiveName" = "$artifactCollectionToolkitArchiveName";

    # SHA256-file hash for the artifact collection archive
    "artifactCollectionToolkitArchiveHash" = "## is calculated dynamically by Update-BuildVariables!";

    # URL to the archive of the collection toolkit
    "artifactCollectionToolkitArchiveURL" = "<to-be-defined>";

    # Name of the artifact collection script which is part of the downloaded toolkit
    "artifactCollectionToolkitScriptName" = "Invoke-TriageCollection.ps1";

    # Number of retries for the artifact uploads
    # Please note: The combination of "artifactUploadMaxRetries" and "artifactUploadRetryAfter" can delay the whole upload a lot!
    # Default: artifactUploadMaxRetries = 5 and artifactUploadRetryAfter = 30, the last retry will happen after 32 minutes (for one artifact)
    # Example #1: If you set artifactUploadMaxRetries = 10 and artifactUploadRetryAfter = 30, the last retry will happen after 8 hours and 32 minutes (for one artifact)
    # Example #2: If you set artifactUploadMaxRetries = 5 and artifactUploadRetryAfter = 60, the last retry will happen after 31 minutes (for one artifact)
    "artifactUploadMaxRetries" = 5;

    # Seconds after which the first retry is made. All further attempts double the previous time.
    # Please note: The combination of "artifactUploadMaxRetries" and "artifactUploadRetryAfter" can delay the whole upload a lot!
    # Default: artifactUploadMaxRetries = 5 and artifactUploadRetryAfter = 30, the last retry will happen after 32 minutes (for one artifact)
    # Example #1: If you set artifactUploadMaxRetries = 10 and artifactUploadRetryAfter = 30, the last retry will happen after 8 hours and 32 minutes (for one artifact)
    # Example #2: If you set artifactUploadMaxRetries = 5 and artifactUploadRetryAfter = 60, the last retry will happen after 31 minutes (for one artifact)
    "artifactUploadRetryAfter" = 30;

    # Seconds per loop step (just used for output of remaining seconds)
    "artifactUploadRetryLoopStep" = 10;

    # Access key for the user to access the AWS S3 bucket
    "bucketAccessKey" = "<to-be-defined>";

    # Name of the AWS S3 bucket
    "bucketName" = "<to-be-defined>";

    # Secret key for the user to access the AWS S3 bucket
    "bucketSecretKey" = "<to-be-defined>";

    # Path format for the upload location of the files in the Amazon S3 bucket (Please note: the file/folder structure of the collection will be added to this path)
    "bucketUploadPath" = "`$Case/`$MachineName/";

    # Regex to validate the case numbers
    "checkCaseNumberPattern" = "<to-be-defined>";

    # Drive letter from which the artifacts should be collected
    "driveLetter" = "`$(`$env:SystemDrive)";

    # Format for DateTime-objects (globally used) - available options can be found here: https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings
    # "o" somehow follows the ISO 8601 standard and includes everything
    "dateTimeFormat" = "o";

    # Storage path where the artifact collection toolkit on the machine should be placed
    "storagePath" = "`$([System.IO.Path]::Combine(`"`$(`$env:windir)`", `"AAC`"))";

    # Storage path where the Artifact Collection Toolkit on the machine should be placed
    "artifactCollectionToolkitRootPath" = "`$([System.IO.Path]::Combine(`"`$storagePath`", `"ACT`"))";

    # Storage path where the collections on the machine should be placed
    "collectionRootPath" = "`$([System.IO.Path]::Combine(`"`$storagePath`", `"Collection`"))";

    # Indicates whether the encryption of the artifacts is mandatory before uploading or not
    "encryptionMandatory" = $false;

    # Path to the certificate which is used for encrypting the data uploads
    "encryptionPublicCertificatePath" = "## is updated dynamically by Build-ArtifactCollectionToolkit!";

    # Length of the random password which is used for encryption
    "encryptionPasswordLength" = 64;

    # Name of the KAPE VHDX-file (.vhdx is attached by KAPE)
    "kapeVhdxFileName" = "KapeArtifacts";

    # Name of the script which is uploaded to the Microsoft Defender Live Response library
    "liveResponseScriptName" = "Invoke-ArtifactCollection.ps1";

    # Identifier of the used mutex
    "mutexID" = "DFIRCollection";

    # Identifier of the temporary power configuration scheme for the artifact collection
    "powerConfigSchemeID" = "$([System.Guid]::NewGuid().ToString())";

    # Name of the temporary power configuration scheme for the artifact collection
    "powerConfigSchemeName" = "Temporary power configuration";

    # Description of the temporary power configuration scheme for the artifact collection
    "powerConfigSchemeDescription" = "Temporary profile which is active during the collection";

    # Path to the PowerShell-module "AWS.Tools.Common.psd1"
    "psModuleAWS.Tools.Common.psd1" = "## path is updated dynamically by Build-ArtifactCollectionToolkit!";

    # Path to the PowerShell-module "AWS.Tools.S3.psd1"
    "psModuleAWS.Tools.S3.psd1" = "## path is updated dynamically by Build-ArtifactCollectionToolkit!";

    ### if more PowerShell-modules from "AWS.Tools" are required, just add them here with the format "psModule<name-of-the-psd1-file>"
}

### END BUILD VARIABLES ###

<#
.SYNOPSIS
    Downloads the latest version of KAPE and builds the artifact collection toolkit.
.EXAMPLE
    PS> Build-ArtifactCollectionToolkit
#>
function Build-ArtifactCollectionToolkit() {
    # Read build variables
    $result = Read-BuildVariables
    if ($result -eq $false) {
        Write-Output ("Please fill the missing build variables before running the script") | Log-Error
        return $false
    }

    # Get full path of folders
    $buildFolderPath = "$([System.IO.DirectoryInfo]::new("$buildFolderPath").FullName)"
    $artifactCollectionToolkitSrcFolderPath = "$([System.IO.DirectoryInfo]::new("$([System.IO.Path]::Combine("$PSScriptRoot", "artifact-collection-toolkit"))").FullName)"
    $artifactCollectionToolkitBuildFolderPath = "$([System.IO.Path]::Combine("$buildFolderPath", "act"))"
    $artifactCollectionToolkitArchivePath = "$([System.IO.Path]::Combine("$buildFolderPath", "$artifactCollectionToolkitArchiveName"))"

    # Check whether build folder exists
    try {
        $file = [System.IO.FileInfo]::new("$artifactCollectionToolkitArchivePath")
        if ($file.Exists) {
            Write-Output ("Removing previous build from {0}" -f $file.LastWriteTime.ToString($buildVariables["dateTimeFormat"])) | Log-Info
            [void](Remove-Item -Path "$buildFolderPath" -Recurse -Force -ErrorAction Stop)
        } elseif ([System.IO.DirectoryInfo]::new("$buildFolderPath").Exists) {
            Write-Output ("Removing previous incomplete build") | Log-Info
            [void](Remove-Item -Path "$buildFolderPath" -Recurse -Force -ErrorAction Stop)
        }

        # Create required folders
        try {
            [void](New-Item -Path "$artifactCollectionToolkitBuildFolderPath" -ItemType Directory -ErrorAction Stop)
            Write-Output ("Created build folder path '{0}'" -f $buildFolderPath) | Log-Info
        } catch {
            Write-Output ("Unable to build folder path '{0}' due to the following reason: {1}" -f $buildFolderPath, $Error[0].Exception.Message) | Log-Error
            return $false
        }
    } catch {
        Write-Output ("Unable to remove previous build folder path '{0}' due to the following reason: {1}" -f $buildFolderPath, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Copy artifact collection toolkit folder and invokation script for the Live Response library to build folder 
    Copy-Item -Path "$([System.IO.Path]::Combine("$artifactCollectionToolkitSrcFolderPath", "*"))" -Destination "$artifactCollectionToolkitBuildFolderPath" -Recurse
    Copy-Item -Path "$([System.IO.Path]::Combine("$PSScriptRoot", "$($buildVariables["liveResponseScriptName"])"))" -Destination "$buildFolderPath" -Force
    Write-Output ("Copied required files and folder to '{0}'" -f $buildFolderPath) | Log-Info

    # Check whether certificate is present
    $certificateFiles = Get-ChildItem -Path "$artifactCollectionToolkitBuildFolderPath" -Filter "*.cer" -File -Recurse
    foreach ($file in $certificateFiles) {
        $cerFilePath = $file.FullName.Replace("$artifactCollectionToolkitBuildFolderPath","")
        if ($cerFilePath.StartsWith("\")) {
            $cerFilePath = $cerFilePath.Substring(1)
        }

        $buildVariables["encryptionPublicCertificatePath"] = "`$([System.IO.Path]::Combine(`"`$PSScriptRoot`", `"$cerFilePath`"))";

        Write-Output ("Using '{0}' as encryption certificate for encrypted artifact upload" -f $file.FullName) | Log-Info
    }

    # Download latest version of KAPE and KAPE files
    $kapeArchivePath = "$([System.IO.DirectoryInfo]::new("$([System.IO.Path]::Combine($buildFolderPath, $kapeArchiveName))").FullName)"
    try {
        Write-Output ("Downloading latest version of KAPE from {0}" -f $kapeDownloadURL) | Log-Info
        Invoke-WebRequest -Uri "$kapeDownloadURL" -OutFile "$kapeArchivePath" -MaximumRedirection 0 -ErrorAction Stop

        Write-Output ("Completed download of latest version of KAPE to {0}" -f "$kapeArchivePath") | Log-Success
    } catch {
        Write-Output ("Unable to download latest version of KAPE from '{0}' due to the following reason: {1}" -f $kapeDownloadURL, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Download latest version of KAPE files
    $kapeFilesFileName = "kapeFiles.zip"
    $kapeFilesArchivePath = "$([System.IO.Path]::Combine($buildFolderPath, "$kapeFilesFileName"))"
    try {
        Write-Output ("Downloading latest version of the KAPE files from {0}" -f $kapeFilesDownloadURL) | Log-Info
        Invoke-WebRequest -Uri "$kapeFilesDownloadURL" -OutFile "$kapeFilesArchivePath" -ErrorAction Stop

        Write-Output ("Completed download of latest version of the KAPE files to {0}" -f "$kapeFilesArchivePath") | Log-Success
    } catch {
        Write-Output ("Unable to download latest version of the KAPE files from '{0}' due to the following reason: {1}" -f $kapeFilesDownloadURL, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Update custom KAPE files in original ZIP (workaround to avoid KAPE moving the custom targets/modules to the !Local-folder)
    [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    $zip = [System.IO.Compression.ZipFile]::Open("$kapeFilesArchivePath", "Update")

    $kapeFilesSrcFolder = "$([System.IO.Path]::Combine("$artifactCollectionToolkitSrcFolderPath", "KAPE"))"
    $kapeFilesZipExtension = "KapeFiles-master"
    $kapeFilesSrcFiles = Get-ChildItem -Path "$kapeFilesSrcFolder" -Attributes !Directory -Recurse

    foreach($file in $kapeFilesSrcFiles) {
        $zipPath = "$($file.FullName.Replace("$kapeFilesSrcFolder", "$kapeFilesZipExtension"))"

        try {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, "$($file.FullName)", $zipPath, "Optimal") | Out-Null
        } catch {
            Write-Output ("Unable to add file '{0}' to the zip '{1}' due to the following reason: {2}" -f $file.FullName, $kapeFilesArchivePath, $Error[0].Exception.Message) | Log-Error
        }
    }
    $zip.Dispose()

    # Extract KAPE archive
    $kapeBuildFolderPath = "$([System.IO.Path]::Combine("$artifactCollectionToolkitBuildFolderPath", "KAPE"))"
    try {
        Expand-Archive -Path "$kapeArchivePath" -DestinationPath "$artifactCollectionToolkitBuildFolderPath" -Force -ErrorAction Stop
        Write-Output ("Successfully extracted latest version of KAPE to {0}" -f $buildFolderPath) | Log-Success
    } catch {
        Write-Output ("Unable to extract latest version of KAPE ({0}) to {1} due to the following reason: {2}" -f $kapeArchivePath, $buildFolderPath, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Run KAPE Update
    try {
        Write-Output ("Running KAPE Update") | Log-Info

        $kapeUpdateScriptPath = "$([System.IO.Path]::Combine("$kapeBuildFolderPath", "Get-KAPEUpdate.ps1"))"
        $psExePath = Get-Command "powershell" | Select-Object -ExpandProperty Source
        Start-SupervisedProcess -FilePath "$psExePath" -ArgumentList "$kapeUpdateScriptPath" -ReadableProcessName "KAPE Update" -WorkingDirectory "$kapeBuildFolderPath"
    } catch {
        Write-Output ("Unable to run KAPE Update due to the following reason: {0}" -f $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Run KAPE Sync
    try {
        Write-Output ("Running KAPE Sync") | Log-Info

        $kapeExePath = "$([System.IO.Path]::Combine("$kapeBuildFolderPath", "kape.exe"))"
        Start-SupervisedProcess -FilePath "$kapeExePath" -ArgumentList "--sync $kapeFilesArchivePath" -ReadableProcessName "KAPE Sync" -WorkingDirectory "$kapeBuildFolderPath"
    } catch {
        Write-Output ("Unable to run KAPE Sync due to the following reason: {0}" -f $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Delete KAPE archive files
    try {
        Remove-Item -Path "$kapeArchivePath" -Force -ErrorAction Stop
        Write-Output ("Successfully deleted KAPE archive file {0}" -f $kapeArchivePath) | Log-Info
    } catch {
        Write-Output ("Unable to delete KAPE archive file ({0}) due to the following reason: {1}" -f $kapeArchivePath, $Error[0].Exception.Message) | Log-Error
        return $false
    }
    try {
        Remove-Item -Path "$kapeFilesArchivePath" -Force -ErrorAction Stop
        Write-Output ("Successfully deleted KAPE files archive file {0}" -f $kapeFilesArchivePath) | Log-Info
    } catch {
        Write-Output ("Unable to delete KAPE files archive file ({0}) due to the following reason: {1}" -f $kapeFilesArchivePath, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Download 7zip (console application)
    $7ZipExecutablePath = "$([System.IO.DirectoryInfo]::new("$([System.IO.Path]::Combine($artifactCollectionToolkitBuildFolderPath, $7ZipExecutableName))").FullName)"
    try {
        Write-Output ("Downloading 7zip console application from {0}" -f $7ZipDownloadURL) | Log-Info
        Invoke-WebRequest -Uri "$7ZipDownloadURL" -OutFile "$7ZipExecutablePath" -MaximumRedirection 0 -ErrorAction Stop

        Write-Output ("Completed download of 7zip console application to {0}" -f "$7ZipExecutablePath") | Log-Success
    } catch {
        Write-Output ("Unable to download of 7zip console application from '{0}' due to the following reason: {1}" -f $7ZipDownloadURL, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Download latest version of AWS PowerShell-modules
    $psModulesAwsArchivePath = "$([System.IO.DirectoryInfo]::new("$([System.IO.Path]::Combine($buildFolderPath, $psModulesAwsArchiveName))").FullName)"
    try {
        Write-Output ("Downloading latest version of AWS-Tools (for PowerShell) from {0}" -f $psModulesAwsURL) | Log-Info
        Invoke-WebRequest -Uri "$psModulesAwsURL" -OutFile "$psModulesAwsArchivePath" -MaximumRedirection 0 -ErrorAction Stop

        Write-Output ("Completed download of latest version of AWS-Tools (for PowerShell) to {0}" -f "$psModulesAwsArchivePath") | Log-Success
    } catch {
        Write-Output ("Unable to download latest version of AWS-Tools (for PowerShell) from '{0}' due to the following reason: {1}" -f $psModulesAwsURL, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Extract AWS PowerShell-modules archive
    $psModulesAwsBuildFolderPath = "$([System.IO.Path]::Combine("$artifactCollectionToolkitBuildFolderPath", "AWS-Tools"))"
    try {
        Expand-Archive -Path "$psModulesAwsArchivePath" -DestinationPath "$psModulesAwsBuildFolderPath" -Force -ErrorAction Stop
        Write-Output ("Successfully extracted latest version of AWS-Tools (for PowerShell) to {0}" -f $psModulesAwsBuildFolderPath) | Log-Success
    } catch {
        Write-Output ("Unable to extract latest version of AWS-Tools (for PowerShell) ({0}) to {1} due to the following reason: {2}" -f $psModulesAwsArchivePath, $psModulesAwsBuildFolderPath, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Delete AWS PowerShell-modules archive
    try {
        Remove-Item -Path "$psModulesAwsArchivePath" -Force -ErrorAction Stop
        Write-Output ("Successfully deleted AWS PowerShell-modules archive file {0}" -f $psModulesAwsArchivePath) | Log-Info
    } catch {
        Write-Output ("Unable to delete AWS PowerShell-modules archive file ({0}) due to the following reason: {1}" -f $psModulesAwsArchivePath, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Identify required AWS PowerShell-modules
    $requiredPsModulePaths = @{}
    foreach ($var in $buildVariables.Keys) {
        if ("$var".StartsWith("psModule")) {
            $moduleFileName = "$var".Replace("psModule","")
            $moduleFiles = Get-ChildItem -Path "$psModulesAwsBuildFolderPath" -Recurse -Filter "*$moduleFileName" -File
            $moduleFound = $false

            foreach ($file in $moduleFiles) {
                $requiredPsModulePaths["$var"] = "$($file.Directory.FullName)"

                Write-Output ("Found AWS PowerShell-module '{0}' in the following path: {1}" -f $moduleFileName, $file.Directory.FullName) | Log-Info
                $moduleFound = $true
            }

            if (!$moduleFound) {
                Write-Output ("Unable to find unique PowerShell-module '{0}' in the latest version of the AWS-Tools (for PowerShell) ({1})" -f $moduleFileName, $psModulesAwsBuildFolderPath) | Log-Error
                return $false
            }
        }
    }

    # Update build variables
    foreach ($var in $requiredPsModulePaths.Keys) {
        $moduleName = "$var".Replace("psModule","")
        $modulePath = "$($requiredPsModulePaths["$var"])".Replace("$artifactCollectionToolkitBuildFolderPath", "`$PSScriptRoot")
        $buildVariables["$var"] = "$([System.IO.Path]::Combine($modulePath, $moduleName))"
    }

    # Remove unused AWS PowerShell-modules
    $psModuleFolders = Get-ChildItem -Path "$psModulesAwsBuildFolderPath" -Directory
    foreach ($folder in $psModuleFolders) {
        $isRequiredFolder = $false

        foreach ($requiredFolder in $requiredPsModulePaths.Values) {
            if ("$requiredFolder".StartsWith("$($folder.FullName)")) {
                $isRequiredFolder = $true
                break
            }
        }

        if (!$isRequiredFolder) {
            try {
                Remove-Item -Path "$($folder.FullName)" -Recurse -Force -ErrorAction Stop
                Write-Output ("Deleted unused AWS PowerShell-module '{0}'" -f $folder.FullName) | Log-Info
            } catch {
                Write-Output ("Unable to delete unused AWS PowerShell-module ({0}) due to the following reason: {1}" -f $folder.FullName, $Error[0].Exception.Message) | Log-Error
                return $false
            }
        }
    }
    Write-Output ("Successfully cleaned up AWS PowerShell-modules in folder {0}" -f $psModulesAwsBuildFolderPath) | Log-Success

    # Fill variables (except the hash of the archive)
    Update-BuildVariables -Path "$buildFolderPath"
    Write-Output ("Updated build variables in the PowerShell-files within the build folder") | Log-Info

    # Compress archive
    try {
        Write-Output ("Building archive for artifact collection toolkit") | Log-Info

        Compress-Archive -Path "$([System.IO.Path]::Combine("$artifactCollectionToolkitBuildFolderPath", "*"))" -DestinationPath "$artifactCollectionToolkitArchivePath" -CompressionLevel Optimal -Force

        Write-Output ("Successfully created archive for artifact collection toolkit at {0}" -f $artifactCollectionToolkitArchivePath) | Log-Success
    } catch {
        Write-Output ("Unable to create artifact collection toolkit archive at '{0}' due to the following reason: {1}" -f $artifactCollectionToolkitArchivePath, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Delete temporary artifact collection folder
    try {
        Remove-Item -Path "$artifactCollectionToolkitBuildFolderPath" -Recurse -Force -ErrorAction Stop
        Write-Output ("Successfully deleted temporary artifact collection folder {0}" -f $artifactCollectionToolkitBuildFolderPath) | Log-Info
    } catch {
        Write-Output ("Unable to delete temporary artifact collection folder ({0}) due to the following reason: {1}" -f $artifactCollectionToolkitBuildFolderPath, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Fill variables (including the hash of the latest artifact collection toolkit archive)
    Update-BuildVariables -Path "$buildFolderPath" -FillArtifactCollectionToolkitHash -ArtifactCollectionToolkitArchivePath "$artifactCollectionToolkitArchivePath"
    Write-Output ("Updated SHA256 hash ({0}) of the artifact collection toolkit in the script '{1}' within the build folder" -f "$(Get-FileHash -Path "$artifactCollectionToolkitArchivePath" -Algorithm SHA256 | Select-Object -ExpandProperty Hash)", "$($buildVariables["liveResponseScriptName"])") | Log-Info

    # Write final message
    Write-Output ("Successfully created relevant files for automated artifact collection") | Log-Success
    Write-Output ("Please note the following open points: ") | Log-Warning
    Write-Output ("[ ] Upload and replace the following script in the Microsoft Defender Live Response library: '{0}'" -f $([System.IO.Path]::Combine("$buildFolderPath", "$($buildVariables["liveResponseScriptName"])"))) | Log-Info
    Write-Output ("[ ] Make the artifact collection toolkit archive ({0}) available for downloads at '{1}'" -f $artifactCollectionToolkitArchivePath, "$($buildVariables["artifactCollectionToolkitArchiveURL"])") | Log-Info

    # Show notice about missing encryption certificate
    if ("$($buildVariables["encryptionPublicCertificatePath"])".StartsWith("##")) {
        Write-Output ("Additionally note, that no certificate was found for encrypting the data upload. Therefore, this function is missing in the script! To generate a certificate, please have a look at the script 'Create-SelfSignedCertificate.ps1'") | Log-Warning
    }

    return $true
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
    $dateTimeFormat = $buildVariables["dateTimeFormat"]
    Write-Error "[$([System.DateTime]::Now.ToString("$dateTimeFormat"))] [E] $Message"
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
    $dateTimeFormat = $buildVariables["dateTimeFormat"]
    Write-Host "[$([System.DateTime]::Now.ToString("$dateTimeFormat"))] [I] $Message"
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
    $dateTimeFormat = $buildVariables["dateTimeFormat"]
    Write-Host -ForegroundColor Yellow "[$([System.DateTime]::Now.ToString("$dateTimeFormat"))] [W] $Message"
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
    $dateTimeFormat = $buildVariables["dateTimeFormat"]
    Write-Host -ForegroundColor Green "[$([System.DateTime]::Now.ToString("$dateTimeFormat"))] [S] $Message"
}

<#
.SYNOPSIS
    Reads the build variables based on a .env-file (which should be located next to this script) or environment variables set in the format "ACT_<build-var>".
.EXAMPLE
    PS> Read-BuildVariables
#>
function Read-BuildVariables() {
    # Check whether an .env file is present in the directory
    $dotEnvFile = [System.IO.FileInfo]::new("$([System.IO.Path]::Combine("$PSScriptRoot", ".env"))")
    if ($dotEnvFile.Exists) {
        Write-Output ("Using .env-file '{0}'" -f $dotEnvFile.FullName) | Log-Info
        $dotEnvContent = [System.IO.File]::ReadAllLines("$($dotEnvFile.FullName)", [System.Text.Encoding]::UTF8)

        # Loop lines from .env-file
        foreach ($line in $dotEnvContent) {
            $var, $val = "$line".Trim().Split("=")
            $var = "$("$var".Trim())"
            $val = "$("$val".Trim())"

            # check whether already an environment variable exists (which rules out the .env-file)
            $envVar = "ACT_$("$("$var".Trim())")"
            $envVal = [System.Environment]::GetEnvironmentVariable("$envVar")

            if ([string]::IsNullOrEmpty("$envVal")) {
                if ($buildVariables.ContainsKey("$var")) {
                    Write-Output ("Changing value of build variable '{0}' from '{1}' to '{2}' based on .env-file" -f $var, $buildVariables[$var], $val) | Log-Info
                    $buildVariables["$var"] = "$val"
                } else {
                    Write-Output ("Skip variable '{0}' from .env-file as it is no valid build variable" -f $var) | Log-Info
                }
            } else { 
                Write-Output ("Skip variable '{0}' from .env-file as environment variable '{1}' is set" -f $var, $envVar) | Log-Info
            }
        }
    }

    # Loop environment variables and check build variables
    foreach ($envVar in Get-ChildItem -Path env:* | Sort-Object Name) {
        $envVal = $envVar.Value
        
        if ("$($envVar.Key)".Length -gt 4) {
            $var = "$($envVar.Key)".Substring(4)

            if ($buildVariables.ContainsKey("$var")) {
                Write-Output ("Changing value of build variable '{0}' from '{1}' to '{2}' based on environment variable '{3}'" -f $var, $buildVariables[$var], $envVal, $envVar.Key) | Log-Info
                $buildVariables["$var"] = "$envVal"
            }
        }
    }

    # Double-check build variables
    $result = $true
    foreach ($var in $buildVariables.Keys) {
        if ("$($buildVariables[$var])".Contains("<to-be-defined>")) {
            Write-Output ("Value for build variable '{0}' is missing" -f $var) | Log-Warning
            $result = $false
        }
    }

    return $result
}

<#
.SYNOPSIS
    Starts a program and redirects the output to the standard output of this window.
.PARAMETER FilePath
    File name and path of the executable to start
.PARAMETER ArgumentList
    List of arguments to add for process execution
.PARAMETER WorkingDirectory
    Path to the working directory
.PARAMETER ReadableProcessName
    Human readable name of the process used for logging
.EXAMPLE
    PS> Start-SupervisedProcess -FilePath "PowerShell.exe" -ArgumentList "Build-ArtifactCollectionToolkit.ps1" -ReadableProcessName "Build-Script"
#>
function Start-SupervisedProcess() {
    param(
        [Parameter(HelpMessage="File name and path of the executable to start", Mandatory=$true, ValueFromPipeline=$true)][string]$FilePath,
        [Parameter(HelpMessage="List of arguments to add for process execution", Mandatory=$false)][string]$ArgumentList,
        [Parameter(HelpMessage="Path to the working directory", Mandatory=$false)][string]$WorkingDirectory,
        [Parameter(HelpMessage="Human readable name of the process used for logging", Mandatory=$false)][string]$ReadableProcessName
    )

    # gather information about running tool
    $programInfo = [System.IO.FileInfo]::new("$FilePath")

    if (!$programInfo.Exists) {
        throw "File '$($programInfo.FullName)' does not exist!"
    }

    if ([string]::IsNullOrEmpty("$ReadableProcessName")) {
        $ReadableProcessName = $programInfo.BaseName
    }

    # prepare process start information
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $programInfo.FullName
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $startOutput = "Starting execution of command line '{0}'"
    $commandLine = "$($programInfo.FullName)"

    if (![string]::IsNullOrEmpty($ArgumentList)) {
        $psi.Arguments = "$ArgumentList"
        $commandLine = "$($programInfo.FullName) $ArgumentList"
    }

    if (![string]::IsNullOrEmpty($WorkingDirectory)) {
        $workingDirectoryInfo = [System.IO.DirectoryInfo]::new("$WorkingDirectory")

        if (!$workingDirectoryInfo.Exists) {
            throw "Working directory '$($workingDirectoryInfo.FullName)' does not exist!"
        }

        $psi.WorkingDirectory = $workingDirectoryInfo.FullName
        $startOutput += " in working directory '$($workingDirectoryInfo.FullName)'"
    }

    Write-Output ($startOutput -f $commandLine) | Log-Info

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi

    [void]($proc.Start())
    while (!$proc.StandardOutput.EndOfStream) {
        $line = $proc.StandardOutput.ReadLine()
        Write-Output ("[{0}] {1}" -f $ReadableProcessName, $line) | Log-Info
    }

    # summarize everything
    while (!$proc.StandardError.EndOfStream) {
        $line = $proc.StandardError.ReadLine()
        Write-Output ("[{0}] {1}" -f $ReadableProcessName, $line) | Log-Warning
    }
    
    Write-Output ("Program '{0}' exited with status {1}" -f $ReadableProcessName, $proc.ExitCode) | Log-Info
}

<#
.SYNOPSIS
    Fills the build variables based on the values from the top of the Build-ArtifactCollectionToolkit.ps1.
.PARAMETER Path
    Path to the build folder
.PARAMETER ArtifactCollectionToolkitArchivePath
    Path to the artifact collection toolkit archive
.PARAMETER FillArtifactCollectionToolkitHash
    Indicates whether the artifact collection toolkit hash should be replaced.
.EXAMPLE
    PS> Update-BuildVariables -Path "C:\Users\Public\Test"
#>
function Update-BuildVariables() {
    param(
        [Parameter(HelpMessage="Path to the build folder", Mandatory=$true, ValueFromPipeline=$true)][string]$Path,
        [Parameter(HelpMessage="Path to the artifact collection toolkit archive", Mandatory=$false)][string]$ArtifactCollectionToolkitArchivePath,
        [Parameter(HelpMessage="Indicates whether the artifact collection toolkit hash should be replaced. If not set, the field is explicitly excluded!", Mandatory=$false)][switch]$FillArtifactCollectionToolkitHash
    )

    # Read list of available PowerShell scripts
    $files = Get-ChildItem -Path "$Path" -Filter *.ps1 -Recurse

    # Check whether artifact collection toolkit hash should be updated
    if ($FillArtifactCollectionToolkitHash) {
        if ([string]::IsNullOrEmpty("$ArtifactCollectionToolkitArchivePath")) {
            throw ("Unable to locate artifact collection toolkit archive from empty path")
        }

        $fileInfo = [System.IO.FileInfo]::new("$ArtifactCollectionToolkitArchivePath")
        if (!$fileInfo.Exists) {
            throw ("Artifact collection toolkit archive does not exist at $($fileInfo.FullName)")
        }
    }

    # Loop files and fill build variables
    foreach ($file in $files) {
        $content = Get-Content -Path "$($file.FullName)" -Raw

        foreach ($key in $buildVariables.Keys) {
            if ($key -eq "artifactCollectionToolkitArchiveHash") {
                if ($FillArtifactCollectionToolkitHash) {
                    $hash = Get-FileHash -Path "$artifactCollectionToolkitArchivePath" -Algorithm SHA256 | Select-Object -ExpandProperty Hash
                    $content = $content.Replace("##build_var.$key", "$hash")
                }
            } else {
                $content = $content.Replace("##build_var.$key", "$($buildVariables[$key])")
            }
        }

        $content | Set-Content -Path "$($file.FullName)"
    }
}

# Set current working directory for .NET
[System.IO.Directory]::SetCurrentDirectory("$PSScriptRoot")

# Run the build script immediately
Build-ArtifactCollectionToolkit