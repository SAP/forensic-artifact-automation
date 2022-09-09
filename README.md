# Forensic Artifact Automation

## About this project

This is a collection of scripts that allow remote forensic triage acquisition and analysis capabilities at scale, using KAPE and other open-source tools utilizing Microsoft Defender for Endpoint (MDE) and Amazon Web Services (AWS) capabilities.


## Requirements and Setup

All AWS Policies, Users, Roles, and Permissions have been outlined [here](#policies-roles-and-permissions).  AWS S3 Buckets, EC2 instances, and Lambda functions need to be manually created in your respective accounts. The names do not have to be the same, but only left as a placeholder.  Follow your company or personal naming convention as desired.  The only necessary changes to the code are the AWS Bucket name, Access, and Secret keys in each script.

## Table of contents
- [Infrastructure](#infrastructure)
- [Policies, Roles, and Permissions](#policies-roles-and-permissions) 
- [MDE Live Response Collection Usage](#mde-live-response-collection-usage)
- [Local Machine Collection Usage (Invoke-LRCollection.ps1) - Option 1](#local-machine-collection-usage-invoke-lrcollectionps1---option-1)
- [Local Machine Collection Usage (Manual Download) - Option 2](#local-machine-collection-usage-manual-download---option-2)
- [Analysis Usage](#analysis-usage)
- [Contribute](#contribute)


## Infrastructure

![Directory Structure](/_res/Current-Infrastructure-FAA.png)

## Policies, Roles, and Permissions
| User | Policy | Role |
|---|---|---|
| GSO-FAA-ArtifactCollector |	GSO-FAA-Collector | |	
| GSO-FAA-KapeProcessor	| GSO-FAA-Processor	| GSO-FAA-LambdaProcessor |
| GSO-FAA-Downloader	| GSO-FAA-User | |

| Policy | Permissions |
|---|---|
| GSO-FAA-Collector | PutObject to gso-image-collection |
| GSO-FAA-Processor | ListBucket to gso-image-collection |
| | GetObject to gso-image-collection |
| | PutObject to gso-image-working-copy |
| GSO-FAA-User | ListBucket to gso-image-working-copy |
| | GetObject to gso-image-working-copy |

## MDE Live Response Collection Usage
This script is designed to be ran from a Microsoft Defender for Endpoint Live Response Session. 

The **ArtifactCollector** directory has been zipped and uploaded to a public AWS S3 bucket.  This zip file's hash must match the hash in the **Invoke-LRCollection.ps1** script in order to run.

To start a Live Response Session from Microsoft Defender for Endpoint, select the target device from the Device Inventory and click on the ellipsis menu, then "Initiate Live Response Session". 

![Directory Structure](/_res/mde-lr.png)

The **Invoke-LRCollection.ps1** needs to be uploaded to the library so it can be ran in the Live Response Session. Click on **Upload file to library**, choose the file location on your local machine where the **Invoke-LRCollection.ps1** script is saved.  

Ensure that you have the **Overwrite File** option checked, to ensure you have the latest version. Once confirmed, you should see two green pop-ups at the top of your screen. 

![Directory Structure](/_res/lr-script-upload.png)

Now this script can be ran using the following command:

```run Invoke-LRCollection.ps1 -parameters "-casenum SIR1234567"```

This script requires the -casenum parameter.  In this case it is a ServiceNow Incident number corresponding to this triage collection.

Allow some time for this script to run.  There will not be any viewable output until the script completes or has an error.  Upon completion, the script output will be present in the terminal window. This will tell you if there was an network issue, and if so, where the files will need to be downloaded to your local machine, which will need to be uploaded from your device.
## Local Machine Collection Usage (Invoke-LRCollection.ps1) - Option 1

This option is preferred if you are given the **Invoke-LRCollection.ps1** script and have admin rights on the device.

To run this script on a local machine, press and release the Windows key on your keyboard and type "powershell".  Alternatively, you can use the search bar next to the Windows icon in the bottom left corner of your screen, then type "powershell".  Click the option "Run as Administrator". Select "Yes" on the User Account Control pop-up screen.

![Directory Structure](/_res/ps-as-admin.png)

Using the Explorer window, navigate to the location of the **Invoke-LRCollection.ps1** script. Click on the Navigation bar and copy that location.

![Directory Structure](/_res/explorercopy.png)

In Powershell, type "**cd** (paste full path, Right-click + paste, or CTRL + V)"  If there is a space in the full path, enclose the full path in double quotes.

Then type "**.\Invoke-LRCollection.ps1**" and press enter.  You can also use tab completion by typing "**Inv** + TAB.  Both result in the same outcome.  Press enter to run the script.

![Directory Structure](/_res/runlrscript.png)

If you see a prompt to change the Execution Policy, Type "**Y**" and press Enter.

![Directory Structure](/_res/execpol.png)

Next, you will be prompted to enter a "**Case Number**". 

![Directory Structure](/_res/entersir.png)

You should see this file start downloading. 

![Directory Structure](/_res/dlzip.png)

Once the case number is entered, the script will run, collecting memory first, then forensic artifacts. Then, the forensic artifacts will be encrypted and compressed and sent to AWS S3. Then the memory will be encrypted, compressed, and sent to AWS S3.  This is to allow a triage investigation on forensic artifact to begin, due to the potentially lengthy upload time for large memory captures.

**IMPORTANT! Allow this script to run until it completes.**

![Directory Structure](/_res/memcapture.png)

![Directory Structure](/_res/collect_zip.png)

![Directory Structure](/_res/memzip.png)

![Directory Structure](/_res/memup.png)

Once the upload of triage artifacts and memory have completed. The script will delete all files created and close automatically.


## Local Machine Collection Usage (Manual Download) - Option 2 

To run this collection script on a local machine, press and release the Windows key on your keyboard and type "powershell".  Alternatively, you can use the search bar next to the Windows icon in the bottom left corner of your screen, then type "powershell".  Click the option "Run as Administrator". Select "Yes" on the User Account Control pop-up screen.

![Directory Structure](/_res/ps-as-admin.png)

In the blue Powershell screen, type:

```cd ~```

This will be your current user directory. Now copy and paste the following command into the powershell:

```Invoke-WebRequest -Uri "http://your-image-collection-dependencies.s3-website.eu-western-1.amazonaws.com/ArtifactCollector.zip" -OutFile ArtifactCollector.zip```

You should see this file start downloading. 

![Directory Structure](/_res/downloadzip.png)

Once complete, type the following command and ensure there's a space between the word and period.  

 ```explorer .``` 

The **ArtifactCollector.zip** file should be visible. Right-Click on this file, and choose "Extract All..."

![Directory Structure](/_res/explorer.png)

Follow to prompts to export the files.

![Directory Structure](/_res/extract.png)

Once extracted, navigate into the directory until you see the **Invoke-TriageCollection.ps1** file.  Right-Click on the file. In the options menu, click "**Run with Powershell**"

![Directory Structure](/_res/runcollection.png)

Another Powershell window will pop up.  If you see a prompt to change the Execution Policy, Type "**Y**" and press Enter.

![Directory Structure](/_res/execpol.png)

Next, you will be prompted to enter a "**Case Number**". 

![Directory Structure](/_res/entersir.png)

Once the case number is entered, the script will run, collecting memory first, then forensic artifacts. Then, the forensic artifacts will be encrypted and compressed and sent to AWS S3. Then the memory will be encrypted, compressed, and sent to AWS S3.  This is to allow a triage investigation on forensic artifact to begin, due to the potentially lengthy upload time for large memory captures.

**IMPORTANT! Allow this script to run until it completes.**

![Directory Structure](/_res/memcapture.png)

![Directory Structure](/_res/collect_zip.png)

![Directory Structure](/_res/memzip.png)

![Directory Structure](/_res/memup.png)

Once the upload of triage artifacts and memory have completed. The script will close automatically.  The "**ArtifactCollector.zip** and "**ArtifactCollector**" directory can be deleted.

## Analysis Usage

**Prerequisite**  
Install Powershell 7

The MSI can be found here:

https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.1

You will also need to set up AWS credentials in your environment variables.  Details can be found here:

https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html

Now navigate to the "**ArtifactDownloader**" directory in Powershell 7 and execute "**Invoke-ArtifactDownload.ps1**".

When Prompted enter the case number. 

![Directory Structure](/_res/invokedownload.png)

You should now have a decrypted triage package in the "**C:\Cases**" folder.

This can then be added to X-Ways, Kape, or any number of forensic utilities.


## Support, Feedback, Contributing

This project is open to feature requests/suggestions, bug reports etc. via [GitHub issues](https://github.com/SAP/forensic-artifact-automation/issues). Contribution and feedback are encouraged and always welcome. For more information about how to contribute, the project structure, as well as additional contribution information, see our [Contribution Guidelines](CONTRIBUTING.md).

## Code of Conduct

We as members, contributors, and leaders pledge to make participation in our community a harassment-free experience for everyone. By participating in this project, you agree to abide by its [Code of Conduct](CODE_OF_CONDUCT.md) at all times.

## Licensing

Copyright 2022 SAP SE or an SAP affiliate company and forensic-artifact-automation contributors. Please see our [LICENSE](LICENSE) for copyright and license information. Detailed information including third-party components and their licensing/copyright information is available [via the REUSE tool](https://api.reuse.software/info/github.com/SAP/forensic-artifact-automation).

These scripts utilize third-party software.  Usage of this software requires adherence to each End User License Agreement (EULA) and/or purchased licenses.
