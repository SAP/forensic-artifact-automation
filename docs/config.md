# Configuration guide
The configuration guide shows the common scenarios and settings provided by the Artifact Collection Toolkit. Most of the configuration options are available in the build script ([Build-ArtifactCollectionToolkit.ps1](/Build-ArtifactCollectionToolkit.ps1)) as build variable.

[[_TOC_]]

## Overall configurations
This section shows the available configuration options which are provided by the Artifact Collection Toolkit itself.

### Use of specific case folder
Specifying the root path where the cases and the results for artifact collections are stored, can be set using the parameter `-CaseFolderPath <path-to-folder>` when calling the script `Invoke-ArtifactCollection.ps1` either via Microsoft Defender Live Response or in the direct call.

If you want to change the default behavior, the build variable can be adjusted to meet your requirements:

```PowerShell
# [...]

# Build variables for other PowerShell scripts
# -----
# !!!! Please remind the escaping of characters here to avoid variables being taken from your local machine!
# -----
$buildVariables = @{

    # [...]

    # Indicates whether the encryption of the artifacts is mandatory before uploading or not
    "collectionRootPath" = "`$([System.IO.Path]::Combine(`"`$storagePath`", `"Collection`"))";

    # [...]

}

# [...]
```

### Encrypting uploaded files
If you want to encrypt the artifacts before uploading them, you can use the switch `-EncryptUpload` when triggering the artifact collection either via Microsoft Defender Live Response or in the direct call. The following example shows the usage:
```PowerShell
PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number> -EncryptUpload
```

In case you always want to encrypt files before uploading them, you can also update the related build variable. Set `encryptionMandatory` to `$true` to activate it per default or `$false` to only have encryption on demand:
```PowerShell
# [...]

# Build variables for other PowerShell scripts
# -----
# !!!! Please remind the escaping of characters here to avoid variables being taken from your local machine!
# -----
$buildVariables = @{

    # [...]

    # Indicates whether the encryption of the artifacts is mandatory before uploading or not
    "encryptionMandatory" = $false; 

    # [...]
}

# [...]
```
**Please note:** The precondition to use the encryption is to have a certificate to encrypt the data. A description how to create a certificate and where to place it can be found in the [installation instructions](/docs/setup.md).

### Extension of build variables
If you want to add build variables for your purposes, feel free to add them to the dictionary `$buildVariables` within the build script ([Build-ArtifactCollectionToolkit.ps1](/Build-ArtifactCollectionToolkit.ps1)). After that, you can just add `##build_var.<name-of-build-variable>` somewhere in other PowerShell-scripts. As the build variables are heavily used by the scripts already in place, you can have a look at those for usage details. Please remind to escape variables (if required).

## Third party applications
As the Artifact Collection Toolkit also uses third party applications, the following chapters show possible ways to configure them.

### Kroll Artifact Parser and Extractor (Kape)
The application [Kroll Artifact Parser and Extractor (Kape)](https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape) is used for gathering the artifacts from the target machine. 

To be able to use this application, you need to register on the site first and you will receive a download link for the KAPE archive. Please put this link to the following variable in the build script ([Build-ArtifactCollectionToolkit.ps1](/Build-ArtifactCollectionToolkit.ps1)):

```PowerShell
# [...]

# URL from which KAPE can be downloaded
$kapeDownloadURL = "<to-be-defined>"

# [...]
```

#### Extension of KAPE targets and modules
KAPE allows the generation of custom targets and modules. To learn more about the architecture of KAPE, please check out the [documentation of KAPE](https://ericzimmerman.github.io/KapeDocs/). If you want to use your custom targets and modules as part of this Artifact Collection Toolkit, you can place the relevant files in the [KAPE-folder](/artifact-collection-toolkit/KAPE/) in the correct folders. To inspect the available folder structure, you can review the structure in the previously fetched KAPE archive.

After the extension of the KAPE targets and modules, you may need to adjust the switches and conditions for the script execution. Therefore, you need to change or extend a couple of functions:

* **[Microsoft Defender Live-Response script (Invoke-ArtifactCollection.ps1)](/Invoke-ArtifactCollection.ps1):** In this script you should adjust the parameters at the very beginning as well as the parameters of the function `Invoke-ArtifactCollection`. Furthermore at the end of the function `Invoke-ArtifactCollection` there is a check for switches and the call of the second script which also needs to be adjusted. The last adjustment in this script is the function call at the end of the whole PowerShell-script file.
* **[Artifact collection script (Invoke-TriageCollection.ps1)](/artifact-collection-toolkit/Invoke-ArtifactCollection.ps1):** For this script you also should update the overall parameters and the parameters of the function `Invoke-ArtifactCollection`. Additionally to that, within the `Invoke-ArtifactCollection` function is a self-elevating section to adjust as well and at the end there is the function call which also needs some update.

### AWS PowerShell-Tools
Additionally to KAPE, the Artifact Collection Toolkit uses the AWS PowerShell-Tools. By default, the build script fetches the latest minor version of version 4 from the AWS-tools directly from their website. In case you need a specific version, host the version within your own environment or want to update the version somewhen in the future, you can adjust the download URL in the build script ([Build-ArtifactCollectionToolkit.ps1](/Build-ArtifactCollectionToolkit.ps1)):

```PowerShell
# [...]

# Name of the AWS-Tools
$psModulesAwsArchiveName = "AWS.Tools.zip"

# URL from which the AWS Tools can be downloaded
$psModulesAwsURL = "https://sdk-for-net.amazonwebservices.com/ps/v4/latest/$psModulesAwsArchiveName"

# [...]
```

The default setup includes PowerShell-modules required for the upload of the artifacts to AWS S3. If you want to use more modules for other activities, you can do so very easily:

1. Add one build variable in the format `psModule<name-of-the-psd1-file>` (e.g. `psModuleAWS.Tools.S3.psd1` for the PowerShell-module `AWS.Tools.S3.psd1`)
    ```
    [...]

    # Build variables for other PowerShell scripts
    # -----
    # !!!! Please remind the escaping of characters here to avoid variables being taken from your local machine!
    # -----
    $buildVariables = @{
        [...]

        # Path to the PowerShell-module "AWS.Tools.Common.psd1"
        "psModuleAWS.Tools.Common.psd1" = "## path is updated dynamically by Build-ArtifactCollectionToolkit!";

        # Path to the PowerShell-module "AWS.Tools.S3.psd1"
        "psModuleAWS.Tools.S3.psd1" = "## path is updated dynamically by Build-ArtifactCollectionToolkit!";

        ### if more PowerShell-modules from "AWS.Tools" are required, just add them here with the format "psModule<name-of-the-psd1-file>"

        [...]
    }

    [...]
    ```
1. Add the import statement to the required file like shown below:
    ```
    [...]

    Import-Module "##build_var.<your-build-variable-from-step-1>"
    
    # Example for "AWS.Tools.S3.psd1"
    Import-Module "##build_var.psModuleAWS.Tools.S3.psd1"

    [...]
    ```