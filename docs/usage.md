# Usage
This section shows how to use the Artifact Collection Toolkit in detail.

[[_TOC_]]

## Basic usage
In general, there are two major ways to gather artifacts using the Artifact Collection Toolkit. The following steps show those examples.

### Microsoft Defender Live Response
After the environment was prepared, the scripts can be triggered using the following steps:
1. Login to the [Microsoft 365 Security Center](https://security.microsoft.com)
1. Navigate to the device you want to get the artifacts from
1. Start a Live Response-session to this device
1. Run the uploaded start script with several command line switches or using the basic command
    ```
    Microsoft Defender LR-Console> run Invoke-ArtifactCollection.ps1 -parameters "-Case <Case number>"
    ```
**Please note:** You can also use other systems providing similar functions to push and run PowerShell-scripts on remote machines. The Artifact Collection Toolkit just requires to be triggered somehow.

### Direct call
If you don't want to use the Microsoft Defender Live Response, you can also invoke the commands directly using the same script:
```PowerShell
PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number>
```

## Advanced usage
Apart from the basic usage examples, there are some more advanced ways like shown below.

### Use of specific case folder
The script [Invoke-ArtifactCollection.ps1](/artifact-collection-toolkit/Invoke-ArtifactCollection.ps1) (which is part of the Artifact Collection Toolkit) is able to use a specific path for storing the collection results. You can achieve this using the parameter `-CaseFolderPath <path-to-folder>`. By default, the script creates a folder `Collection` next to the script you are executing. The following example would store the collection results on the Desktop of the user forensics:
```PowerShell
PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number> -CaseFolderPath C:\Users\forensics
```
**Please note:** Configuring the default root path for artifact collections can be done via build variables. Further information can be found in the [configuration guide](/docs/config.md).

### Use Artifact Collection Toolkit archive which is already present
For some cases it could be required to use an Artifact Collection Toolkit archive which is already present on the machine. One example could be, if the network of the target machine is too slow and the Microsoft Defender Live Response is aborting the execution of the first script. You would be able to put the archive somewhere on the machine and specify the name using the parameter `-ArtifactCollectionToolkitArchivePath <path\to\ArtifactCollectionToolkit.zip>`. A whole example where the archive is placed in the folder `C:\temp\ArtifactCollectionToolkit.zip` would look like this:
```
Microsoft Defender LR-Console> run Invoke-ArtifactCollection.ps1 -Case <Case number> -ArtifactCollectionToolkitArchivePath `C:\temp\ArtifactCollectionToolkit.zip`
```

**Please note:** The option is only available in the script you upload to the Microsoft Defender Live Response.

### Offline execution
In case there is a device which is not connected to the internet, you can use the offline mode and upload the files afterwards.
1. Download the Artifact Collection Toolkit archive and extract it on an USB-stick or somewhere else (accessible from the target device) 
1. On the target device run the script [Invoke-ArtifactCollection.ps1](/artifact-collection-toolkit/Invoke-ArtifactCollection.ps1) with administrative permissions from the location of the previous step and add the switch `-Offline` to the command line:
    ```PowerShell
    PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number> -Offline
    ```
1. After the script finished the execution it shows the path where the results are stored. If you did not provide any custom path, the results are stored in a folder called `Collection` next to the script you started in the previous step
1. If you are using an USB-stick, you can unplug it now and take it to a machine with internet access. 
1. On this machine you can upload the artifact collection now using the same script as on the machine you collected the artifacts but with the command below:
    ```PowerShell
    PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number> -UploadOnly -MachineName <Name-of-the-machine-where-the-artifacts-were-collected>
    ```
**Please note:** Do not mix up the two scripts. The script [Invoke-ArtifactCollection.ps1](/Invoke-ArtifactCollection.ps1) you upload to the Microsoft Defender Live Response library does not support the offline function as it requires the Artifact Collection Toolkit to be downloaded first!

### Encrypting uploaded files
If you want to encrypt the artifacts before uploading them, you can use the switch `-EncryptUpload` when triggering the artifact collection. 
```PowerShell
PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number> -EncryptUpload
```

After the collection has been completed and the artifacts are uploaded, you will find them online in the AWS S3 bucket. To make use of them, please follow the steps below:
1. Download both files, the *.7z and the *.key
1. Decrypt the password to the *.7z file from the *.key file using the following command
    ```PowerShell
    PS> Get-Content -Path "<path-to-the-key-file>" | Unprotect-CmsMessage -To <path-to-the-private-key>
    ```
1. Now you can use the password shown with the previous command can be used to extract the *.7z file

**Please note:** 
* In case you always want to encrypt files before uploading them, you can also update the related build variable. Further information can be found in the [configuration guide](/docs/config.md).  
* The precondition to use the encryption is to have a certificate to encrypt the data. A description how to create a certificate and where to place it can be found in the [installation instructions](/docs/setup.md).