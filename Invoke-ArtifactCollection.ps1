<#
.SYNOPSIS
    Prepares the machine for the artifact collection based on the Microsoft Defender Live Response.
.PARAMETER Case
    Related case from the case management
.PARAMETER ArtifactCollectionToolkitArchivePath
    Path to the Artifact Collection Toolkit archive which is already present on the machine
.PARAMETER Browser
    Set if you want to collect web browser artifacts
.PARAMETER BrowserOnly
    Set if you only want to collect web browser artifacts
.PARAMETER SkipMemory
    Set if you want to skip the memory collection
.PARAMETER SkipStorageCheck
    Set if you want to skip the storage check
.PARAMETER EncryptUpload
    Set if you want to encrypt the upload
.EXAMPLE
    PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number>

    Runs the artifact collection linked to the case <Case number> including memory (excluding browser data)
.EXAMPLE
    PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number>-Browser

    Runs the artifact collection linked to the case <Case number> including memory and browser data
.EXAMPLE
    PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number> -BrowserOnly

    Runs the artifact collection linked to the case <Case number> for the browser data only
.EXAMPLE
    PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number> -SkipMemory

    Runs the artifact collection linked to the case <Case number> without memory and browser data
.EXAMPLE
    PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number> -SkipStorageCheck

    Runs the artifact collection linked to the case <Case number> including memory (excluding browser data) without a prior check of the required disk space. This command may fails in case not enough disk space is available.
.NOTES
#>
param(
    [Parameter(HelpMessage="Related case from the case management", Mandatory=$true, ValueFromPipeline=$true)][string]$Case,
    [Parameter(HelpMessage="Path to the Artifact Collection Toolkit archive")][string]$ArtifactCollectionToolkitArchivePath,
    [Parameter(HelpMessage="Set if you want to collect web browser artifacts", Mandatory=$false)][Switch]$Browser,
    [Parameter(HelpMessage="Set if you only want to collect web browser artifacts", Mandatory=$false)][Switch]$BrowserOnly,
    [Parameter(HelpMessage="Set if you want to skip the memory collection", Mandatory=$false)][Switch]$SkipMemory,
    [Parameter(HelpMessage="Set if you want to skip the storage check", Mandatory=$false)][Switch]$SkipStorageCheck,
    [Parameter(HelpMessage="Set if you want to encrypt the upload", Mandatory=$false)][Switch]$EncryptUpload
)

### START SETTINGS AREA ###

# Please note: The settings should be provided as build variable and set via Build-ArtifactCollectionToolkit.ps1, if possible

# Storage path where the artifact collection toolkit on the machine should be placed
$storagePath = "##build_var.storagePath"

### END SETTINGS AREA ###

<#
.SYNOPSIS
    Checks whether the given case number is valid.
.PARAMETER Case
    Related case from case management
.EXAMPLE
    PS> Check-CaseNumber -Case <Case number>
#>
function Check-CaseNumber() {
    param(
        [Parameter(HelpMessage="Related case from the case management", Mandatory=$true, ValueFromPipeline=$true)][string]$Case
    )

    $regex = [System.Text.RegularExpressions.Regex]::new("##build_var.checkCaseNumberPattern", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    if ($regex.IsMatch($Case)) {
        Write-Output ("Investigation assigned to case {0}" -f $Case) | Log-Info
        return $true
    } else {
        Write-Output ("Provided case number '{0}' is invalid" -f $Case) | Log-Error
        return $false
    }
}

<#
.SYNOPSIS
    Checks whether the free disc space is enough for a memory dump.
.EXAMPLE
    PS> Check-DiskSpace
#>
function Check-DiskSpace() {
    # Gather disk space
    $systemDrive = [System.IO.DriveInfo]::new("##build_var.driveLetter")
    $freeSpaceGiB = [System.Math]::Round($systemDrive.AvailableFreeSpace / 1024 / 1024 / 1024, 2)
    $totalSpaceGiB = [System.Math]::Round($systemDrive.TotalSize / 1024 / 1024 / 1024, 2)

    # Gather memory size
    $totalMemorySizeGiB = [System.Math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum / 1024 / 1024 / 1024, 2)
    
    # Log information
    Write-Output ("Free space for drive {0}: {1}/{2} GiB" -f "##build_var.driveLetter", $freeSpaceGiB, $totalSpaceGiB) | Log-Info
    Write-Output ("Installed memory: {0} GiB" -f $totalMemorySizeGiB) | Log-Info

    # Check disk space
    $requiredSpace = $totalMemorySizeGiB * 2
    if ($requiredSpace -lt $freeSpaceGiB) {
        Write-Output ("Enough free space for memory collection available") | Log-Info
        return $true   
    } else {
        Write-Output ("Insufficient disk space available as memory collection requires {0} GiB." -f $requiredSpace) | Log-Error
        return $false
    }
}

<#
.SYNOPSIS
    Validates the integrity of the Artifact Collection Toolkit archive.
.PARAMETER Path
    Path of the artifact collection toolkit archive
.EXAMPLE
    PS> Check-ArtifactCollectionToolkitArchiveIntegrity -Path "C:\Users\Public\Test.zip"
#>
function Check-ArtifactCollectionToolkitArchiveIntegrity() {
    param(
        [Parameter(HelpMessage="Path of the artifact collection toolkit archive", Mandatory=$true, ValueFromPipeline=$true)][string]$Path
    )

    $hash = (Get-FileHash -Algorithm SHA256 "$Path").Hash
    if ("$hash".ToUpper() -eq "##build_var.artifactCollectionToolkitArchiveHash".ToUpper().Trim()) {
        return $true
    } else {
        return $false
    }
}

<#
.SYNOPSIS
    Downloads, validates and extracts the artifact collection toolkit.
.PARAMETER Path
    Path where the artifact collection toolkit should be stored
.PARAMETER ArtifactCollectionToolkitArchivePath
    Path to the Artifact Collection Toolkit archive which is already present on the machine
.EXAMPLE
    PS> Get-ArtifactCollectionToolkit -Path "C:\Users\Public\Test"
#>
function Get-ArtifactCollectionToolkit() {
    param(
        [Parameter(HelpMessage="Path where the artifact collection toolkit should be stored", Mandatory=$true, ValueFromPipeline=$true)][string]$Path,
        [Parameter(HelpMessage="Path to the Artifact Collection Toolkit archive")][string]$ArtifactCollectionToolkitArchivePath
    )

    # Prepare folders
    $actArchivePath = [System.IO.Path]::Combine($Path, "##build_var.artifactCollectionToolkitArchiveName")
    if (![System.IO.DirectoryInfo]::new("$Path").Exists) {
        try {
            [void](New-Item -Path "$Path" -ItemType Directory -ErrorAction Stop)
            Write-Output ("Created path for Artifact Collection Toolkit '{0}'" -f $Path) | Log-Info
        } catch {
            Write-Output ("Unable to create path for Artifact Collection Toolkit '{0}' due to the following reason: {1}" -f $Path, $Error[0].Exception.Message) | Log-Error
            return $false
        }
    }

    # Check path of already present file
    if (![string]::IsNullOrEmpty("$ArtifactCollectionToolkitArchivePath")) {
        $artifactCollectionToolkitArchive = [System.IO.FileInfo]::new("$ArtifactCollectionToolkitArchivePath")
        if ($artifactCollectionToolkitArchive.Exists) {
            try {
                Write-Output ("Taking Artifact Collection Toolkit from '{0}'" -f $artifactCollectionToolkitArchive.FullName) | Log-Info
                [void](Copy-Item -Path "$ArtifactCollectionToolkitArchivePath" -Destination "$actArchivePath" -Force -ErrorAction Stop)
            } catch {
                Write-Output ("Unable to copy the existing Artifact Collection Toolkit archive from '{0}' to '{1}' due to the following reason: {2}" -f $artifactCollectionToolkitArchive.FullName, $actArchivePath, $Error[0].Exception.Message) | Log-Error
            }
        } else {
            Write-Output ("The specified Artifact Collection Toolkit archive at '{0}' is not existing" -f $artifactCollectionToolkitArchive.FullName) | Log-Warning
        }
    }

    # Check whether file already exists
    $downloadRequired = $true
    if ([System.IO.FileInfo]::new("$actArchivePath").Exists) {
        if ($(Check-ArtifactCollectionToolkitArchiveIntegrity -Path "$actArchivePath")) {
            Write-Output ("Skipped download of Artifact Collection Toolkit archive as there is already a valid version at '{0}'" -f $actArchivePath) | Log-Success
            $downloadRequired = $false
        } else {
            Write-Output ("Local version of Artifact Collection Toolkit archive at '{0}' is corrupt or outdated" -f $actArchivePath) | Log-Warning
            try {
                [void](Remove-Item -Path "$actArchivePath" -Force -ErrorAction Stop)
                $downloadRequired = $true
            } catch {
                Write-Output ("Unable to remove corrupt or outdated artifact collection toolkit from '{0}' due to the following reason: {1}" -f $actArchivePath, $Error[0].Exception.Message) | Log-Error
                [void](Remove-Folder -Path "$Path")
                return $false
            }
        }
    }

    # Downloading artifact collection archive
    if ($downloadRequired) {
        try {
            Write-Output ("Downloading artifact collection toolkit from {0}" -f "##build_var.artifactCollectionToolkitArchiveURL") | Log-Info
            Invoke-WebRequest -Uri "##build_var.artifactCollectionToolkitArchiveURL" -OutFile "$actArchivePath" -MaximumRedirection 0 -ErrorAction Stop

            Write-Output ("Completed download of artifact collection toolkit to {0}" -f $actArchivePath) | Log-Success
        } catch {
            Write-Output ("Unable to download artifact collection toolkit from '{0}' due to the following reason: {1}" -f "##build_var.artifactCollectionToolkitArchiveURL", $Error[0].Exception.Message) | Log-Error
            [void](Remove-Folder -Path "$Path")
            return $false
        }

        # Validating artifact collection archive
        if ($(Check-ArtifactCollectionToolkitArchiveIntegrity -Path "$actArchivePath")) {
            Write-Output ("Successfully verified integrity of artifact collection toolkit") | Log-Info
        } else {
            Write-Output ("Artifact collection toolkit is invalid and does not match the expectations! (Local SHA256: {0}, Expected SHA256: {1})" -f $hash, "##build_var.artifactCollectionToolkitArchiveHash".ToUpper().Trim()) | Log-Error
            [void](Remove-Folder -Path "$Path")
            return $false
        }
    }

    # Extract artifact collection toolkit
    try {
        Expand-Archive -Path "$actArchivePath" -DestinationPath "$Path" -Force -ErrorAction Stop
        Write-Output ("Successfully extracted artifact collection toolkit to {0}" -f $Path) | Log-Success
    } catch {
        Write-Output ("Unable to extract artifact collection toolkit ({0}) to {1} due to the following reason: {2}" -f $actArchivePath, $Path, $Error[0].Exception.Message) | Log-Error
        [void](Remove-Folder -Path "$Path")
        return $false
    }

    # Remove artifact collection archive
    try {
        Remove-Item -Path "$actArchivePath" -Force -ErrorAction Stop
        Write-Output ("Removed artifact collection toolkit archive {0}" -f $actArchivePath) | Log-Info
    } catch {
        Write-Output ("Unable to remove artifact collection toolkit archive {0} due to the following reason: {1}" -f $actArchivePath, $Error[0].Exception.Message) | Log-Error
        [void](Remove-Folder -Path "$Path")
        return $false
    }

    return $true
}

<#
.SYNOPSIS
    Invokes the artifact collection on the machine.
.PARAMETER Case
    Related case from the case management
.PARAMETER ArtifactCollectionToolkitArchivePath
    Path to the Artifact Collection Toolkit archive which is already present on the machine
.PARAMETER Browser
    Set if you want to collect web browser artifacts
.PARAMETER BrowserOnly
    Set if you only want to collect web browser artifacts
.PARAMETER SkipMemory
    Set if you want to skip the memory collection
.PARAMETER SkipStorageCheck
    Set if you want to skip the storage check
.PARAMETER EncryptUpload
    Set if you want to encrypt the upload
.EXAMPLE
    PS> Invoke-ArtifactCollection -Case <Case number>

    Runs the artifact collection linked to the case <Case number> including memory (excluding browser data)
.EXAMPLE
    PS> Invoke-ArtifactCollection -Case <Case number> -Browser

    Runs the artifact collection linked to the case <Case number> including memory and browser data
.EXAMPLE
    PS> Invoke-ArtifactCollection -Case <Case number> -BrowserOnly

    Runs the artifact collection linked to the case <Case number> for the browser data only
.EXAMPLE
    PS> Invoke-ArtifactCollection -Case <Case number> -SkipMemory

    Runs the artifact collection linked to the case <Case number> without memory and browser data
.EXAMPLE
    PS> Invoke-ArtifactCollection -Case <Case number> -SkipStorageCheck

    Runs the artifact collection linked to the case <Case number> including memory (excluding browser data) without a prior check of the required disk space. This command may fails in case not enough disk space is available.
#>
function Invoke-ArtifactCollection() {
    param(
        [Parameter(HelpMessage="Related case from the case management", Mandatory=$true, ValueFromPipeline=$true)][string]$Case,
        [Parameter(HelpMessage="Path to the Artifact Collection Toolkit archive")][string]$ArtifactCollectionToolkitArchivePath,
        [Parameter(HelpMessage="Set if you want to collect web browser artifacts", Mandatory=$false)][Switch]$Browser,
        [Parameter(HelpMessage="Set if you only want to collect web browser artifacts", Mandatory=$false)][Switch]$BrowserOnly,
        [Parameter(HelpMessage="Set if you want to skip the memory collection", Mandatory=$false)][Switch]$SkipMemory,
        [Parameter(HelpMessage="Set if you want to skip the storage check", Mandatory=$false)][Switch]$SkipStorageCheck,
        [Parameter(HelpMessage="Set if you want to encrypt the upload", Mandatory=$false)][Switch]$EncryptUpload
    )

    # Validate case number
    $validCaseNumberProvided = Check-CaseNumber -Case "$Case"
    if ($validCaseNumberProvided) {
        $Case = $Case.ToUpper()
    } else {
        return $false
    }

    # Validate disk space for memory collection
    $includeMemory = $false
    if (!$SkipMemory) {
        if (!$SkipStorageCheck) {
            $includeMemory = Check-DiskSpace

            if (!$includeMemory) {
                Write-Output ("Skipping memory collection due to insufficient storage") | Log-Info
            }
        } else {
            $includeMemory = $true
        }
    }

    # Validate browser collection
    $includeBrowser = $false
    if ($Browser -and $BrowserOnly) {
        Write-Output ("Parameters '-Browser' and '-BrowserOnly' cannot be used together") | Log-Error
        return $false
    }
    if ($Browser -or $BrowserOnly) {
        $includeBrowser = $true
    }

    # Create required folders
    $caseFolderPath = "$([System.IO.Path]::Combine("##build_var.collectionRootPath", "$Case".ToUpper()))"
    if ([System.IO.DirectoryInfo]::new("##build_var.collectionRootPath").Exists) {
        $previousCaseFolders = Get-ChildItem -Path "##build_var.collectionRootPath" -Attributes Directory
        $previousCases = @()

        foreach ($folder in $previousCaseFolders) {
            if (Check-CaseNumber -Case "$($folder.BaseName)") {
                $previousCases += $folder.BaseName
            }
        }

        Write-Output ("Previous artifact collections on this machine done for the following cases: {0}" -f $($previousCases -join ', ')) | Log-Info
    } else {
        Write-Output ("No previous artifact collections done on this machine") | Log-Info
    }

    if ([System.IO.DirectoryInfo]::new("$caseFolderPath").Exists) {
        Write-Output ("Investigation for case {0} already performed ({1}): {2}" -f $Case, [System.IO.DirectoryInfo]::new("$caseFolderPath").LastWriteTime.ToString("##build_var.dateTimeFormat"), $caseFolderPath) | Log-Error
        return $false
    }
    try {
        [void](New-Item -Path "$caseFolderPath" -ItemType Directory -ErrorAction Stop)
        Write-Output ("Created path for case '{0}'" -f $caseFolderPath) | Log-Info
    } catch {
        Write-Output ("Unable to create path for case '{0}' due to the following reason: {1}" -f $caseFolderPath, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Prepare artifact collection toolkit
    if ($(Get-ArtifactCollectionToolkit -Path "##build_var.artifactCollectionToolkitRootPath" -ArtifactCollectionToolkitArchivePath "$ArtifactCollectionToolkitArchivePath") -eq $false) {
        return $false;
    }

    # Prepare command line
    $flags = "-Case $Case -CaseFolderPath `"$CaseFolderPath`""

    if ($Browser) { $flags += " -Browser" }
    if ($BrowserOnly) { $flags += " -BrowserOnly" }
    if ($SkipMemory) { $flags += " -SkipMemory" }
    if ($SkipStorageCheck) { $flags += " -SkipStorageCheck" }
    if ($EncryptUpload) { $flags += " -EncryptUpload" }

    $artifactCollectionToolkitScriptPath = [System.IO.Path]::Combine("##build_var.artifactCollectionToolkitRootPath", "##build_var.artifactCollectionToolkitScriptName")
    $commandLine = "$artifactCollectionToolkitScriptPath $flags"

    # Start artifact collection
    try {
        Start-Process -FilePath "PowerShell.exe" -ArgumentList "$commandLine" -ErrorAction Stop
        Write-Output ("Successfully started artifact collection with the following command line 'PowerShell.exe {0}'" -f $commandLine) | Log-Success
        return $true
    } catch {
        Write-Output ("Unable to start artifact collection with the command line 'PowerShell.exe {0}' due to the following reason: {1}" -f $commandLine, $Error[0].Exception.Message) | Log-Error
        [void](Remove-Folder -Path "$caseFolderPath")
        return $false
    }
}

<#
.SYNOPSIS
    Removes the given folder.
.PARAMETER Path
    Folder path which should be removed
.EXAMPLE
    PS> Remove-Folder -Path "C:\Users\Public\Test"
#>
function Remove-Folder() {
    param(
        [Parameter(HelpMessage="Folder path which should be removed", Mandatory=$true, ValueFromPipeline=$true)][string]$Path
    )

    # Test and clean path
    if (Test-Path -Path "$Path") {
        try {
            Remove-Item "$Path" -Recurse -Force -ErrorAction Stop
            Write-Output ("Cleaned up folder path '{0}'" -f $Path) | Log-Info
        } catch {
            Write-Output ("Unable to cleanup folder path '{0}' due to the following reason: {1}" -f $Path, $Error[0].Exception.Message) | Log-Error
            return $false
        }
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
    Write-Error "[$([System.DateTime]::Now.ToString("##build_var.dateTimeFormat"))] [E] $Message"
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
    Write-Host "[$([System.DateTime]::Now.ToString("##build_var.dateTimeFormat"))] [I] $Message"
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
    Write-Host -ForegroundColor Yellow "[$([System.DateTime]::Now.ToString("##build_var.dateTimeFormat"))] [W] $Message"
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
    Write-Host -ForegroundColor Green "[$([System.DateTime]::Now.ToString("##build_var.dateTimeFormat"))] [S] $Message"
}

# Set current working directory for .NET
[System.IO.Directory]::SetCurrentDirectory("$PSScriptRoot")

# Call the relevant function with all required parameters
Invoke-ArtifactCollection -Case "$Case" -ArtifactCollectionToolkitArchivePath "$ArtifactCollectionToolkitArchivePath" -Browser:$Browser -BrowserOnly:$BrowserOnly -SkipMemory:$SkipMemory -SkipStorageCheck:$SkipStorageCheck -EncryptUpload:$EncryptUpload