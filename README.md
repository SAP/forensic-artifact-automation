[[_TOC_]]

# Automated Artifact Collection
The target of this project is to automatically collect artifacts from (Windows based) machines using the Microsoft Defender Live Response and AWS.

## Preparation
To setup the environment, please follow the [setup instructions](/docs/setup.md). After the setup is completed, you can review the [configuration guide](/docs/config.md) for further options. The whole removal is also covered in the [setup instructions](/docs/setup.md).

## Usage
There are two ways to gather artifacts using the Artifact Collection Toolkit. The following steps show two examples. More versions are shown in the [usage manual](/docs/usage.md).

### Microsoft Defender Live Response
After the environment was prepared, the scripts can be triggered using the following steps:
1. Login to the [Microsoft 365 Security Center](https://security.microsoft.com)
1. Navigate to the device you want to get the artifacts from
1. Start a Live Response-session to this device
1. Run the uploaded start script with several command line switches or using the basic command
    ```
    MS Defender LR-Console> run Invoke-ArtifactCollection.ps1 -parameters "-Case <Case number>"
    ```

### Direct call
If you don't want to use the Microsoft Defender Live Response, you can also invoke the commands directly using the same script:
```PowerShell
PS> .\Invoke-ArtifactCollection.ps1 -Case <Case number>
```

### Processing artifacts
After the collection has been completed and the artifacts are uploaded, you will find them online in the AWS S3 bucket. To make use of them, please follow the steps below:
1. Download both files, the *.7z and the *.key
1. Decrypt the password to the *.7z file from the *.key file using the following command
    ```PowerShell
    PS> Get-Content -Path "<path-to-the-key-file>" | Unprotect-CmsMessage -To <path-to-the-private-key>
    ```
1. Now you can use the password shown with the previous command can be used to extract the *.7z file

## Support, Feedback, Contributing

This project is open to feature requests/suggestions, bug reports etc. via [GitHub issues](https://github.com/SAP/forensic-artifact-automation/issues). Contribution and feedback are encouraged and always welcome. For more information about how to contribute, the project structure, as well as additional contribution information, see our [Contribution Guidelines](CONTRIBUTING.md).

## Code of Conduct

We as members, contributors, and leaders pledge to make participation in our community a harassment-free experience for everyone. By participating in this project, you agree to abide by its [Code of Conduct](CODE_OF_CONDUCT.md) at all times.

## Licensing

Copyright 2022 SAP SE or an SAP affiliate company and forensic-artifact-automation contributors. Please see our [LICENSE](LICENSE) for copyright and license information. Detailed information including third-party components and their licensing/copyright information is available [via the REUSE tool](https://api.reuse.software/info/github.com/SAP/forensic-artifact-automation).

These scripts utilize third-party software.  Usage of this software requires adherence to each End User License Agreement (EULA) and/or purchased licenses.
