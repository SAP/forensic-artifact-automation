# Installation and Setup
This section shows how to install and configure your environment to be able to use this Artifact Collection Toolkit in detail.

[[_TOC_]]

## Create AWS subscription
Based on the architecture, the artifacts are uploaded to an AWS S3 bucket for post-processing. Therefore, the whole environment is built in AWS.

As soon as you have created your subscription, you can follow the steps below to configure the environment.

## Prepare AWS IAM users
To get everything working, it requires two users to be setup in your AWS subscription:
1. Create the following IAM user accounts:
    * **IAM user for configuration**, which is taken by Terraform to manage the subscription and implement all required changes
    * **IAM user for Artifact Collection Toolkit**, which is used by the scripts of the Artifact Collection Toolkit to upload the artifacts
1. Open the user page for both users and navigate to `Security Credentials` and click on `Add Access Key` (Select `Application running outside AWS` on the first page and follow the instructions of the other pages). On the last page it shows the access key and the secret key. Please copy both information and store them securely as they are required for steps below or during the configuration process.
1. In the user page of the `IAM user for configuration` select the `Permissions` tab and click on `Add permission`. Select `Attach policies directly` from the list on top and search for `AdministratorAccess` and select the policy. Confirm the actions of the assignment. The policy should now show up in the list of permissions for the user.

## Setup AWS environment
The whole AWS environment can be configured using Terraform. It is an open-source infrastructure-as-code software tool created by HashiCorp. Users define and provide data center infrastructure using a declarative configuration language (More information on the [official homepage](https://www.terraform.io/)).

For the installation, you can follow the instructions [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

### Configure AWS subscription using Terraform
After the installation of Terraform on your machine, the automatic configuration can be started.

1. Review the [configuration.tf](/terraform/configuration.tf) and create environment variables to set the values for the setup process. The format for these variables is `TV_VAR_<name-of-the-var-in-configuration.tf>` as described in the [official documentation](https://developer.hashicorp.com/terraform/cli/config/environment-variables#tf_var_name).
1. Open a terminal in the folder [terraform](/terraform/) and run the command for initialization
    ```bash
    terraform init
    ```
1. After the initialization is completed, you can review the changes and create an initial state with terraform using the command
    ```bash
    terraform plan
    ```
1. To finally configure your AWS environment as required, you can run the command
    ```bash
    # Command with confirmation
    terraform apply

    # Command which skips the confirmation
    terraform apply -auto-approve
    ```

### Gather information about AWS environment
For the configuration of the PowerShell-script, you need to know the URL of the CloudFront-instance which was created by Terraform in the previous steps.
1. Open the [AWS Console](https://console.aws.amazon.com/console/home)
1. Select the Service [CloudFront](https://console.aws.amazon.com/cloudfront/v3/home)
1. Navigate to the available [distributions](https://console.aws.amazon.com/cloudfront/v3/home#/distributions) and copy the URL of the CloudFront distribution from the column `Domain name` for the configuration of the Artifact Collection Toolkit afterwards

## Generate certificate (optional)
If you want to use the encryption of the uploads, you need to provide a certificate file (*.cer) somewhere in the folder [artifact-collection-toolkit](/artifact-collection-toolkit/). To create a certificate you can use the script [Create-SelfSignedCertificate.ps1](/Create-SelfSignedCertificate.ps1). It allows you to create a self-signed certificate. The usage is shown in the examples below:

* Creates a certificate with the name (and CN) "Artifact collection" and stores the private key there "C:\Users\forensics\Desktop\Artifact collection.pfx" (without password) and the public key (Artifact collection.cer) next to it. The temporary generated certificate is then deleted from your own certificate store.
    ```PowerShell
    PS> .\Create-SelfSignedCertificate.ps1 -CertName "Artifact collection" -CertPath "C:\Users\forensics\Desktop\"
    ```
* Creates a certificate with the name (and CN) "Artifact collection" and stores the private key there "C:\Users\forensics\Desktop\Artifact collection.pfx" (using the password "asdf") and the public key (Artifact collection.cer) next to it. The temporary generated certificate is not deleted from your certificate store afterwards.
    ```PowerShell
    PS> .\Create-SelfSignedCertificate.ps1 -CertName "Artifact collection" -CertPath "C:\Users\forensics\Desktop\" -PrivateKeyPassword "asdf" -SkipRemoveFromCertificateStore
    ```

## Build Artifact Collection Toolkit
The Artifact Collection Toolkit uses a build script ([Build-ArtifactCollectionToolkit.ps1](/Build-ArtifactCollectionToolkit.ps1)) for generating the required files.

### Build variables
To be flexible in the configuration, it also provides build variables, which are used as placeholders in other files and replaced by the build script during it's execution. 

Before the first execution in your environment, you should review and adopt the variables to your requirements. One example would be the name of the AWS S3 bucket:

```PowerShell
# [...]

# Build variables for other PowerShell scripts
# -----
# !!!! Please remind the escaping of characters here to avoid variables being taken from your local machine!
# -----
$buildVariables = @{

    # [...]

    # URL to the archive of the collection toolkit
    "artifactCollectionToolkitArchiveURL" = "<to-be-defined>";

    # [...]

}

# [...]
```

There are three ways to set or update the build variables:
1. **Environment variables:** Build variables can be set as environment variables and follow the format `ACT_<build-variable-name>` (e.g. `ACT_bucketName` for the build variable `bucketName`)
1. **.env-file:** If the value is not set as environment variable it would be taken from a .env-file which is located in the same folder than the build script ([Build-ArtifactCollectionToolkit.ps1](/Build-ArtifactCollectionToolkit.ps1)). To use the .env-file, just add one build variable (incl. it's value) per line in the format `<build-variable>=<value>`.
1. **Update of build script ([Build-ArtifactCollectionToolkit.ps1](/Build-ArtifactCollectionToolkit.ps1)):** If the first two ways do not set/update the value of a build variable, the default setting from the build script ([Build-ArtifactCollectionToolkit.ps1](/Build-ArtifactCollectionToolkit.ps1)) is taken. To modify those values, just replace the values directly.
To be able to understand which value is taken from which way (if they are specified multiple times), the script shows the source (and the taken value) at the beginning of the build.

**Please note:** 
* All `<to-be-defined>`-values need to be filled before the Artifact Collection Toolkit can be built. 
* You can use PowerShell-variables in those build variables as well, but if you want them to be executed/taken on the target machine and not during the build process, you need to escape them! If you want to use `$env:MachineName` for instance (from the target machine), you need to put `` `$env:MachineName`` instead.

The further usage of the build variables is shown in the [configuration guide](/docs/config.md).

#### Example `artifactCollectionToolkitArchiveURL`
The build variable `artifactCollectionToolkitArchiveURL` should be a combination of the CloudFront-URL, you copied in the step before and the path to the Artifact Collection Toolkit archive in the AWS S3 bucket.

If the CloudFront URL would be `https://a2hfh58wjfgeird.cloudfront.net` and the archive is placed at `/act/ArtifactCollectionToolkit.zip` within the AWS S3 bucket (for download), the build variable `artifactCollectionToolkitArchiveURL` should have the value `https://a2hfh58wjfgeird.cloudfront.net/act/ArtifactCollectionToolkit.zip`.

### Required tools
For the usage of the Artifact Collection Toolkit multiple tools are required. All tools are downloaded and configured based on the instructions given in the build script ([Build-ArtifactCollectionToolkit.ps1](/Build-ArtifactCollectionToolkit.ps1)). 

## Finalize setup
The final step of the setup is the upload of all built files to their target location. Where they should be available is shown in the last lines of the output from the build script which are marked as to dos.

To upload the built PowerShell-script to the Microsoft Defender Live Response library. It is accessible after starting a Live Response session to some client machine and upload the PowerShell-script. Please select the option that the script uses parameters when uploading and if there is already a previous version available in the library also select the override option.

**Please note:** Due to replication by CloudFront, it can take a while until your newly built Artifact Collection Toolkit archive is available at your download location. If you download the old one using the new script via Microsoft Defender Live Response, it will fail due to different file hash values!

## What's next
As you successfully configured the environment now, you can continue with the [configuration guide](/docs/config.md) and the [usage](/docs/usage.md).

# Deinstallation and removal
To clean up the whole setup, the following steps are required to be done in the same order as shown below:
1. Remove all files and folders from the AWS S3 buckets that they are empty
1. Open a terminal in the folder [terraform](/terraform/) and run the command for removal
    ```bash
    # Command with confirmation
    terraform destroy

    # Command which skips the confirmation
    terraform destroy -auto-approve
    ```
    **Please note:** Due to a known issue in destroying a replicated lambda function using terraform, a workaround is implemented which requires waiting for 20 minutes without any activity.
1. Remove the uploaded script from the Microsoft Defender Live Response library by connecting to a device and executing the commands:
    ```
    # Show all files uploaded to the library
    MS Defender LR-Console> library

    # Delete the specific file from the library
    MS Defender LR-Console> library delete <filename>
    ```