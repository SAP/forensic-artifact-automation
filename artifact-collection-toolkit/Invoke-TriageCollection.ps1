<#
.SYNOPSIS
    Invokes the artifact collection on the machine itself (called by the script from Microsoft Defender Live Response). This script can also be called directly.
.PARAMETER Case
    Related case from the case management
.PARAMETER CaseFolderPath
    Path where the collection results should be stored
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
.PARAMETER Offline
    Sets the script to offline mode
.PARAMETER UploadOnly
    Uploads a previously created artifact collection
.PARAMETER MachineName
    Name of the machine to which the artifacts belong (only considered in combination with UploadOnly)
.EXAMPLE
    PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number>

    Runs the artifact collection linked to the case <Case number> including memory (excluding browser data)
.EXAMPLE
    PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number> -Browser

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
    [Parameter(HelpMessage="Path where the collection results should be stored", Mandatory=$false)][string]$CaseFolderPath,
    [Parameter(HelpMessage="Set if you want to collect web browser artifacts", Mandatory=$false)][Switch]$Browser,
    [Parameter(HelpMessage="Set if you only want to collect web browser artifacts", Mandatory=$false)][Switch]$BrowserOnly,
    [Parameter(HelpMessage="Set if you want to skip the memory collection", Mandatory=$false)][Switch]$SkipMemory,
    [Parameter(HelpMessage="Set if you want to skip the storage check", Mandatory=$false)][Switch]$SkipStorageCheck,
    [Parameter(HelpMessage="Set if you want to encrypt the upload", Mandatory=$false)][Switch]$EncryptUpload,
    [Parameter(HelpMessage="Sets the script to offline mode", Mandatory=$false)][Switch]$Offline,
    [Parameter(HelpMessage="Uploads a previously created artifact collection", Mandatory=$false)][Switch]$UploadOnly,
    [Parameter(HelpMessage="Name of the machine to which the artifacts belong (only considered in combination with UploadOnly)", Mandatory=$false)][string]$MachineName
)

### START SETTINGS AREA ###

# Please note: The settings should be provided as build variable and set via Build-ArtifactCollectionToolkit.ps1, if possible

### END SETTINGS AREA ###

# Import AWS Modules that are required for the S3 upload
Import-Module "##build_var.psModuleAWS.Tools.Common.psd1"
Import-Module "##build_var.psModuleAWS.Tools.S3.psd1"

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
    Compresses and encrypts artifacts.
.PARAMETER CaseFolderPath
    Path where the collection results are stored
.PARAMETER MachineName
    Name of the machine to which the artifacts belong
.PARAMETER EncryptUpload
    Set if you want to encrypt the upload
#>
function Compress-Artifacts() {
    param(
        [Parameter(HelpMessage="Path where the collection results are stored", Mandatory=$true, ValueFromPipeline=$true)][string]$CaseFolderPath,
        [Parameter(HelpMessage="Name of the machine to which the artifacts belong", Mandatory=$false)][string]$MachineName,
        [Parameter(HelpMessage="Set if you want to encrypt the upload", Mandatory=$false)][Switch]$EncryptUpload
    )

    # Validate case folder path
    if (![System.IO.DirectoryInfo]::new("$CaseFolderPath").Exists) {
        Write-Output ("Case folder '{0}' does not exist!" -f $CaseFolderPath) | Log-Error
        return $false
    }

    # Set to true (by the build variables) if encryption is mandatory
    $encryptionMandatory = "##build_var.encryptionMandatory"

    # Prepare time variables
    $dateTime = $([System.DateTime]::Now)
    $timeUTC = "$($dateTime.ToUniversalTime().ToString("##build_var.dateTimeFormat"))".Replace(":", "-").Replace(".", "-")
    $timeLocal = "$($dateTime.ToString("##build_var.dateTimeFormat"))".Replace(":", "-").Replace(".", "-")

    # Path for the artifact zip
    $artifactsArchivePath = "$([System.IO.Path]::Combine("$CaseFolderPath", "##build_var.artifactArchiveName"))"

    # Prepare process start information
    $7ZipExecutablePath = "##build_var.7ZipExecutablePath"
    $ReadableProcessName = "7Zip"
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "$7ZipExecutablePath"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = "$CaseFolderPath"

    # Gather list of artifacts
    $artifacts = Get-ChildItem -Path "$CaseFolderPath" -Recurse -File

    # Prepare arguments for 7zip
    $flags = "a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhe=on -sdel"

    # Check encryption and prepare preconditions
    if ($encryptionMandatory -eq $true -or $EncryptUpload) {
        $encryptionPublicCertificatePath = "##build_var.encryptionPublicCertificatePath"

        # Check whether encryption certificate is available
        if ([System.IO.File]::Exists("$encryptionPublicCertificatePath")) {
            [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
            $random = [System.Web.Security.Membership]::GeneratePassword("##build_var.encryptionPasswordLength", 2)
            $flags += " -p$($random)"
            Protect-CmsMessage -Content "$random" -To "$encryptionPublicCertificatePath" -OutFile "$($artifactsArchivePath).key"
        } else {
            Write-Output ("Unable to encrypt output due to missing encryption certificate") | Log-Error
            return $false
        }
    }

    # Loop artifacts
    $artifactCounter = 0
    foreach ($artifact in $artifacts) {
        # Configure process start information
        $argumentList = "$flags `"$($artifactsArchivePath)`" `"$($artifact.FullName)`""
        $psi.Arguments = "$ArgumentList"

        $proc = [System.Diagnostics.Process]::new()
        $proc.StartInfo = $psi

        Write-Output ("[{0}] Adding {1} to archive" -f $ReadableProcessName, $artifact.FullName) | Log-Info

        [void]($proc.Start())
        $proc.WaitForExit()

        # Printing error messages
        while (!$proc.StandardError.EndOfStream) {
            $line = $proc.StandardError.ReadLine()
            Write-Output ("[{0}] {1}" -f $ReadableProcessName, $line) | Log-Warning
            return $false
        }

        $artifactsCounter += 1
    }
    
    # Printing summary
    $summary = ""
    if ($artifactsCounter -eq 1) {
        $summary = "1 artifact to '$artifactsArchivePath'"
    } else {
        $summary = "$artifactsCounter artifacts to '$artifactsArchivePath'"
    }
    if ($encryptionMandatory -eq $true -or $EncryptUpload) {
        Write-Output ("Compressed and encrypted {0} " -f $summary) | Log-Success
    } else {
        Write-Output ("Compressed " -f $summary) | Log-Success
    }

    return $true
}

<#
.SYNOPSIS
    Invokes the artifact collection on the machine.
.PARAMETER Case
    Related case from the case management
.PARAMETER CaseFolderPath
    Path where the collection results should be stored
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
.PARAMETER Offline
    Sets the script to offline mode
.EXAMPLE
    PS> Invoke-ArtifactCollection -Case <Case number>

    Runs the artifact collection linked to the case <Case number> including memory (excluding browser data)
.EXAMPLE
    PS> Invoke-ArtifactCollection -Case C<Case number> -Browser

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
        [Parameter(HelpMessage="Path where the collection results should be stored", Mandatory=$false)][string]$CaseFolderPath,
        [Parameter(HelpMessage="Set if you want to collect web browser artifacts", Mandatory=$false)][Switch]$Browser,
        [Parameter(HelpMessage="Set if you only want to collect web browser artifacts", Mandatory=$false)][Switch]$BrowserOnly,
        [Parameter(HelpMessage="Set if you want to skip the memory collection", Mandatory=$false)][Switch]$SkipMemory,
        [Parameter(HelpMessage="Set if you want to skip the storage check", Mandatory=$false)][Switch]$SkipStorageCheck,
        [Parameter(HelpMessage="Set if you want to encrypt the upload", Mandatory=$false)][Switch]$EncryptUpload,
        [Parameter(HelpMessage="Sets the script to offline mode", Mandatory=$false)][Switch]$Offline
    )

    # Validate case number
    $validCaseNumberProvided = Check-CaseNumber -Case "$Case"
    if ($validCaseNumberProvided) {
        $Case = $Case.ToUpper()
        Write-Output ("Investigation assigned to case {0}" -f $Case) | Log-Info
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

    # Validate case folder path
    if ([string]::IsNullOrEmpty("$CaseFolderPath")) {
        $storagePath = [System.IO.DirectoryInfo]::new("$PSScriptRoot").Parent.FullName
        $CaseFolderPath = "$([System.IO.Path]::Combine("$storagePath", "Collection", "$Case"))"
    }

    # Self-elevate privileges and pass arguments
    if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        Write-Output ("Script is not running with elevated permissions, restart with higher privileges") | Log-Info

        # Prepare command line
        $flags = "-Case $Case -CaseFolderPath `"$CaseFolderPath`""

        if ($Browser) { $flags += " -Browser" }
        if ($BrowserOnly) { $flags += " -BrowserOnly" }
        if ($SkipMemory) { $flags += " -SkipMemory" }
        if ($SkipStorageCheck) { $flags += " -SkipStorageCheck" }
        if ($EncryptUpload) { $flags += " -EncryptUpload" }
        if ($Offline) { $flags += " -Offline" }

        $commandLine = "$PSCommandPath $flags"

        # Start artifact collection
        try {
            Start-Process -FilePath "PowerShell.exe" -ArgumentList "$commandLine" -Verb "RunAs" -ErrorAction Stop
            Write-Output ("Successfully started elevated process for the following command line 'PowerShell.exe {0}'" -f $commandLine) | Log-Success
            return $true
        } catch {
            Write-Output ("Unable to start elevated process for the command line 'PowerShell.exe {0}' due to the following reason: {1}" -f $commandLine, $Error[0].Exception.Message) | Log-Error
            return $false
        }
    }

    # Request mutex
    $mutex = $null
    try {
        $mutex = Request-Mutex -MutexID "##build_var.mutexID"
    } catch {
        Write-Output ("Unable to start elevated process for the command line 'PowerShell.exe {0}' due to the following reason: {1}" -f $commandLine, $Error[0].Exception.Message) | Log-Error
        return $false
    }

    # Prepare path where the collections for the case are stored
    if (![System.IO.DirectoryInfo]::new("$CaseFolderPath").Exists) {
        try {
            [void](New-Item -Path "$CaseFolderPath" -ItemType Directory -ErrorAction Stop)
            Write-Output ("Created case folder for collection at '{0}'" -f $CaseFolderPath) | Log-Info
        } catch {
            Write-Output ("Unable to create case folder for collection at '{0}' due to the following reason: {1}" -f $CaseFolderPath, $Error[0].Exception.Message) | Log-Error

            # Perform cleanup
            [void](Remove-ArtifactCollectionToolkit -Mutex $mutex)

            return $false
        }
    }

    # Read current power configuration
    try {
        $previousPowerConfigurationID = (powercfg -getactivescheme) -replace '^.+([-0-9a-f]{36}).+$', '$1'
    } catch {
        Write-Output ("Unable to read current power configuration due to the following reason: {0}" -f $Error[0].Exception.Message) | Log-Error

        # Perform cleanup
        [void](Remove-ArtifactCollectionToolkit -Mutex $mutex -CaseFolderPath "$CaseFolderPath")

        return $false
    }

    # Install and activate DFIR power configuration
    try {
        [void](powercfg -duplicatescheme $previousPowerConfigurationID "##build_var.powerConfigSchemeID")
        [void](powercfg -changename "##build_var.powerConfigSchemeID" "##build_var.powerConfigSchemeName" "##build_var.powerConfigSchemeDescription")
        [void](powercfg -setactive "##build_var.powerConfigSchemeID")

        $settings = 'disk-timeout-ac', 'disk-timeout-dc', 'standby-timeout-ac', 'standby-timeout-dc', 'hibernate-timeout-ac', 'hibernate-timeout-dc'
        foreach ($setting in $settings) {
            [void](powercfg -change $setting 0) # 0 == Never
        }

        Write-Output ("Successfully installed and activated power configuration '{0}'" -f "##build_var.powerConfigSchemeName") | Log-Success
    } catch {
        Write-Output ("Unable to create DFIR power configuration due to the following reason: {0}" -f $Error[0].Exception.Message) | Log-Error

        # Perform cleanup
        [void](Remove-ArtifactCollectionToolkit -Mutex $mutex -CaseFolderPath "$CaseFolderPath")

        return $false
    }

    # Perform artifact collection and upload
    $result = $false
    try {
        # Prepare path where KAPE is stored
        $kapePath = [System.IO.Path]::Combine("$PSScriptRoot", "KAPE")
        $kapeExePath = [System.IO.Path]::Combine("$kapePath", "kape.exe")

        # Prepare KAPE collection folder
        $kapeCollectionFolderPath = [System.IO.Path]::Combine("$CaseFolderPath", "KAPE")

        # Prepare KAPE targets
        $targets = @()
        if (!$BrowserOnly) { $targets += "BasicArtifactCollection" }
        if ($Browser -or $BrowserOnly) { $targets += "WebBrowsers" }

        # Run KAPE
        $kapeArgumentList = "--tsource `"##build_var.driveLetter`" --tdest `"$kapeCollectionFolderPath`" --target $($targets -join ',') --vhdx `"##build_var.kapeVhdxFileName`""
        Write-Output "Starting KAPE collection" | Log-Info
        Start-SupervisedProcess -FilePath "$kapeExePath" -ArgumentList "$kapeArgumentList" -WorkingDirectory "$kapePath" -ReadableProcessName "KAPE"
        Write-Output ("Completed KAPE collection ({0})" -f $kapeCollectionFolderPath) | Log-Success

        # ----- Please add further collections here -----

        Write-Output ("Completed artifact collection") | Log-Success

        # Compress (and encrypt) artifacts
        if (Compress-Artifacts -CaseFolderPath "$CaseFolderPath" -EncryptUpload:$EncryptUpload -MachineName "$([Environment]::MachineName)") {
            # Upload data to S3
            if ($Offline) {
                $result = $true
            } else {
                $result = Upload-Artifacts -Case "$Case" -CaseFolderPath "$CaseFolderPath" -MachineName "$([Environment]::MachineName)"
            }
        } else {
            $result = $false
        }
    } catch {
        Write-Output ("Unable to collect and upload the artifacts due to the following reason: {0}" -f $Error[0].Exception.Message) | Log-Error
        $result = $false
    } finally {
        # Remove folder content
        if ($Offline) {
            Write-Output ("You can find the artifact collection results here: '{0}'" -f $CaseFolderPath)  | Log-Info
            Write-Output ("This folder is not deleted automatically! In case you copied it, please make sure to delete all sensitive information on the machine afterwards.")  | Log-Warning

            # Perform cleanup
            [void](Remove-ArtifactCollectionToolkit -Mutex $mutex -PreviousPowerConfigurationID $previousPowerConfigurationID -SkipArtifactCollectionToolkitRemoval)
        } else {
            # Perform cleanup
            [void](Remove-ArtifactCollectionToolkit -Mutex $mutex -CaseFolderPath "$CaseFolderPath" -PreviousPowerConfigurationID $previousPowerConfigurationID)
        }
    }

    return $result
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

<#
.SYNOPSIS
    Removes the Artifact Collection Toolkit incl. everything around.
.PARAMETER CaseFolderPath
    Path to the case folder which should be cleaned
.PARAMETER PreviousPowerConfigurationID
    Identifier of the previous power configuration which should be restored
.PARAMETER Mutex
    Mutex to release
.PARAMETER SkipArtifactCollectionToolkitRemoval
    Set if you want to skip the removal of the Artifact Collection Toolkit
#>
function Remove-ArtifactCollectionToolkit() {
    param(
        [Parameter(HelpMessage="Path to the case folder which should be cleaned", Mandatory=$false)][string]$CaseFolderPath,
        [Parameter(HelpMessage="Identifier of the previous power configuration which should be restored", Mandatory=$false)][string]$PreviousPowerConfigurationID,
        [Parameter(HelpMessage="Mutex to release", Mandatory=$false)][System.Threading.Mutex]$Mutex,
        [Parameter(HelpMessage="Set if you want to skip the removal of the Artifact Collection Toolkit", Mandatory=$false)][Switch]$SkipArtifactCollectionToolkitRemoval
    )

    # Remove artifacts from case folder
    if (![string]::IsNullOrEmpty("$CaseFolderPath")) {
        [void](Remove-Item -Path "$([System.IO.Path]::Combine("$CaseFolderPath", "*"))" -Recurse -Force)
    }

    # Remove mutex
    if ($Mutex -ne $null) {
        $mtxHandle = $Mutex.Handle
        $Mutex.ReleaseMutex()

        Write-Output ("Released mutex handle '{0}'" -f $mtxHandle) | Log-Info
    }

    # Restore power configuration
    if (![string]::IsNullOrEmpty("$PreviousPowerConfigurationID")) {
        try {
            [void](powercfg -setactive $PreviousPowerConfigurationID)
            [void](powercfg -delete "##build_var.powerConfigSchemeID")

            Write-Output ("Successfully reverted power configuration to '{0}'" -f $PreviousPowerConfigurationID)  | Log-Info
        } catch {
            Write-Output ("Unable to revert power configuration due to the following reason: {0}" -f $Error[0].Exception.Message) | Log-Error
        }
    }

    # Remove Artifact Collection Toolkit
    if (!$SkipArtifactCollectionToolkitRemoval) {
        [void](Remove-Item -Path "$PSScriptRoot" -Recurse -Force)
    }
}

<#
.SYNOPSIS
    Requests a mutex with the given identifier.
.PARAMETER MutexID
    Identifier of the mutex to request
.EXAMPLE
    PS> Request-Mutex -MutexID "MyFunnyMutex"
#>
function Request-Mutex() {
    param(
        [Parameter(HelpMessage="Identifier of the mutex to request", Mandatory=$true, ValueFromPipeline=$true)][string]$MutexID
    )

    # creating the mutex without taking ownership
    $mtx = [System.Threading.Mutex]::new($false, $MutexID)
    $mtxHandle = $mtx.Handle

    # requesting ownership
    if ($mtx.WaitOne(10)) {
        Write-Output ("Got ownership of mutex '{0}' (handle: '{1}')" -f $MutexID, $mtxHandle) | Log-Info
    } else {
        Write-Output ("Unable to get ownership of mutex '{0}'" -f $MutexID) | Log-Error
        throw "Parallel execution of script detected. Please terminate process or tidy up mutex."
    }

    return $mtx
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

    # Gather information about running tool
    $programInfo = [System.IO.FileInfo]::new("$FilePath")

    if (!$programInfo.Exists) {
        throw "File '$($programInfo.FullName)' does not exist!"
    }

    if ([string]::IsNullOrEmpty("$ReadableProcessName")) {
        $ReadableProcessName = $programInfo.BaseName
    }

    # Prepare process start information
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

    # Summarize everything
    while (!$proc.StandardError.EndOfStream) {
        $line = $proc.StandardError.ReadLine()
        Write-Output ("[{0}] {1}" -f $ReadableProcessName, $line) | Log-Warning
    }
    
    Write-Output ("Program '{0}' exited with status {1}" -f $ReadableProcessName, $proc.ExitCode) | Log-Info
}

<#
.SYNOPSIS
    Uploads the data from the given path.
.PARAMETER Case
    Related case from the case management
.PARAMETER CaseFolderPath
    Path where the collection results are stored
.PARAMETER MachineName
    Name of the machine to which the artifacts belong
#>
function Upload-Artifacts() {
    param(
        [Parameter(HelpMessage="Related case from the case management", Mandatory=$true, ValueFromPipeline=$true)][string]$Case,
        [Parameter(HelpMessage="Path where the collection results are stored", Mandatory=$true)][string]$CaseFolderPath,
        [Parameter(HelpMessage="Name of the machine to which the artifacts belong", Mandatory=$true)][string]$MachineName
    )

    # Validate case number
    $validCaseNumberProvided = Check-CaseNumber -Case "$Case"
    if ($validCaseNumberProvided) {
        $Case = $Case.ToUpper()
    } else {
        Write-Output ("Invalid case number '{0}' provided" -f $Case) | Log-Error
        return $false
    }
    
    # Validate case folder path
    if ([string]::IsNullOrEmpty("$CaseFolderPath")) {
        $CaseFolderPath = "$([System.IO.Path]::Combine("$PSScriptRoot", "Collection", "$Case"))"
    }
    if (![System.IO.DirectoryInfo]::new("$CaseFolderPath").Exists) {
        Write-Output ("Case folder '{0}' does not exist!" -f $CaseFolderPath) | Log-Error
        return $false
    }

    # Prepare information from bucket
    $bucketName = "##build_var.bucketName"
    $bucketUploadPath = "##build_var.bucketUploadPath"

    Write-Output ("Starting artifact upload") | Log-Info

    # Loop artifacts within the case folder
    $artifacts = Get-ChildItem -Path "$CaseFolderPath" -Recurse -File
    $artifactCounter = 0
    $artifactsMaxUploadRetries = [System.Int32]::Parse("##build_var.artifactUploadMaxRetries")

    foreach ($artifact in $artifacts) {
        # Remove leading slash from upload path (if present)
        if ("$bucketUploadPath".StartsWith("/")) {
            $bucketUploadPath = "$bucketUploadPath".Substring(1)
        }

        # Prepare the artifact path in the bucket
        $bucketArtifactPath = "$($artifact.FullName)".Replace("$CaseFolderPath", "$bucketUploadPath")
        $bucketArtifactPath = "$bucketArtifactPath".Replace("\", "/").Replace("//","/")

        # Prepare upload retry information
        $artifactsActualUploadRetries = 0
        $artifactsUploadRetryWaitTime = [System.Int32]::Parse("##build_var.artifactUploadRetryAfter")
        $artifactsUploadRetryLoopStep = [System.Int32]::Parse("##build_var.artifactUploadRetryLoopStep")

        # Try to upload the artifact incl. retry
        while ($artifactsActualUploadRetries -le $artifactsMaxUploadRetries) {
            try {
                Write-S3Object -BucketName "$bucketName" -UseAccelerateEndpoint -AccessKey "##build_var.bucketAccessKey" -SecretKey "##build_var.bucketSecretKey" -File "$($artifact.FullName)" -Key "$bucketArtifactPath" -ErrorAction Stop
    
                Write-Output ("Uploaded artifact '{0}' to the S3 bucket '{1}' (path: '{2}')" -f $artifact.FullName, "$bucketName", $bucketArtifactPath) | Log-Info

                $artifactCounter += 1
                break
            } catch {
                if ($artifactsActualUploadRetries -lt $artifactsMaxUploadRetries) {
                    Write-Output ("Unable to upload artifact '{0}' to the S3 bucket '{2}' (path: '{3}') due to the following reason: {4}" -f $artifact.FullName, $artifactsActualUploadRetries, $bucketName, $bucketArtifactPath, $Error[0].Exception.Message) | Log-Warning
 
                    # Wait for retry
                    for ($i = $artifactsUploadRetryWaitTime; $i -gt 0; $i -= $artifactsUploadRetryLoopStep) {
                        Write-Output ("{0} seconds remaining until retry #{1} of artifact upload for '{2}'" -f $i, $($artifactsActualUploadRetries + 1), $artifact.FullName) | Log-Info

                        if ($i -lt $artifactsUploadRetryLoopStep) {
                            Start-Sleep -Seconds $i
                        } else {
                            Start-Sleep -Seconds $artifactsUploadRetryLoopStep
                        }
                    }

                    # Update counter and time
                    $artifactsActualUploadRetries += 1
                    $artifactsUploadRetryWaitTime += $artifactsUploadRetryWaitTime

                    Write-Output ("Retrying upload of artifact {0}" -f $artifact.FullName) | Log-Info
                } else {
                    Write-Output ("Unable to upload artifact '{0}' after {1} retries to the S3 bucket '{2}' (path: '{3}') due to the following reason: {4}" -f $artifact.FullName, $artifactsActualUploadRetries, $bucketName, $bucketArtifactPath, $Error[0].Exception.Message) | Log-Error
                    return $false
                }
            }
        }
    }

    # Print success message
    if ($artifactCounter -eq 1) {
        Write-Output ("Successfully uploaded 1 artifact to the S3 bucket '{0}'" -f "$bucketName") | Log-Success
    } else {
        Write-Output ("Successfully uploaded {0} artifacts to the S3 bucket '{1}'" -f "$artifactCounter", "$bucketName") | Log-Success
    }

    return $true
}

# Set current working directory for .NET
[System.IO.Directory]::SetCurrentDirectory("$PSScriptRoot")

# Call the relevant function with all required parameters
if ($UploadOnly) {
    if ([string]::IsNullOrEmpty($MachineName)) {
        Write-Output ("Please provide the machine name where the artifacts were collected") | Log-Error
        return $false
    }
    
    Upload-Artifacts -Case "$Case" -CaseFolderPath "$CaseFolderPath" -MachineName "$MachineName"
} else {
    Invoke-ArtifactCollection -Case "$Case" -CaseFolderPath "$CaseFolderPath" -Browser:$Browser -BrowserOnly:$BrowserOnly -SkipMemory:$SkipMemory -SkipStorageCheck:$SkipStorageCheck -EncryptUpload:$EncryptUpload -Offline:$Offline
}
