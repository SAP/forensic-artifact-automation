# Triggering Live Response Triggering Like a Pro

This notebook is showing how to trigger the Live Response Triage Image Collection through API (SOAR-ready).


## Creating a Service Account

A new service account should be created for triggering the Live Response in an automated manner.

For this, visit [portal.azure.com](https://portal.azure.com) and create a new *application account* featuring the following privileges:

* `MicrosoftGraph > User.Read`
* `WindowsDefenderATP > Machine.LiveResponse`

In case you'd like to upload and modify the Live Response library through API e.g. for using customized scripts per investigation or even host, you need an yet another privilege:

* `WindowsDefenderATP > Library.Manage`

Note that all `WindowsDefenderATP` privileges need Azure AD admin approvals to become active.

## Getting a Session Token

The very first thing we need to do is creating a session token.


```python
import json
import urllib.request
import urllib.parse
```


```python
tenantId = 'xxx'
appId = 'xxx'
appSecret = 'xxx'
```


```python
url = 'https://login.microsoftonline.com/{}/oauth2/token'.format(tenantId)
resourceAppIdUri = 'https://api.securitycenter.microsoft.com'

body = {
    'resource' : resourceAppIdUri,
    'client_id' : appId,
    'client_secret' : appSecret,
    'grant_type' : 'client_credentials'
}

data = urllib.parse.urlencode(body).encode('utf-8')
req = urllib.request.Request(url, data)
response = urllib.request.urlopen(req)
aadToken = json.loads(response.read())['access_token']
```

## Triggering the API Call

Now it's time to select the machine and start deploying our little ps1 helper.


```python
machine_id = 'xxx'
lr_api_endpoint = '{}/api/machines/{}/runliveresponse'.format(resourceAppIdUri, machine_id)

headers = { 
    'Content-Type' : 'application/json',
    'Accept' : 'application/json',
    'Authorization' : 'Bearer {}'.format(aadToken)
}
```


```python
collect_query = query = {
   "Commands":[
      {
         "type":"RunScript",
         "params":[
            {
               "key":"ScriptName",
               "value":"Invoke-LRCollection.ps1"
            },
            {
               "key":"Args",
               "value":"-casenum SIR0001337 -skipmem"
            },
         ],
      },
   ],
   "Comment":"Trigging the magic through API"
}
```

This is where the different commands and instructions are kept. The list will be executed from top to bottom. Note that the script takes a while to be executed so start with quick commands first and have the long running one as last entry.


```python
request = urllib.request.Request(url=lr_api_endpoint, data=json.dumps(collect_query).encode('utf-8'), headers=headers)
response = urllib.request.urlopen(request)
jsonResponse = json.loads(response.read())
job_id = jsonResponse['id']
```

The response will look similar to this:

```
    {'@odata.context': 'https://api.securitycenter.microsoft.com/api/$metadata#MachineActions/$entity',
     'id': '7d7b92c8-4ac8-4aa5-b222-9f91ca0bf8d9',
     'type': 'LiveResponse',
     'title': None,
     'requestor': '4af2e1ae-893f-415b-ba4e-cc3de20146e3',
     'requestorComment': 'Trigging the magic through API',
     'status': 'Pending',
     'machineId': None,
     'computerDnsName': None,
     'creationDateTimeUtc': '2022-06-23T13:19:10.5284096Z',
     'lastUpdateDateTimeUtc': '2022-06-23T13:19:10.5284096Z',
     'cancellationRequestor': None,
     'cancellationComment': None,
     'cancellationDateTimeUtc': None,
     'errorHResult': 0,
     'scope': None,
     'externalId': None,
     'requestSource': 'PublicApi',
     'relatedFileInfo': None,
     'commands': [],
     'troubleshootInfo': None}
```


## Check Status 


```python
status_endpoint = 'https://api.securitycenter.microsoft.com/api/machineactions/{}'.format(job_id)

req = urllib.request.Request(url=status_endpoint, headers=headers)
response = urllib.request.urlopen(req)
jsonResponse = json.loads(response.read())
```

The output will be something similar to this:

```
    {'@odata.context': 'https://api.securitycenter.microsoft.com/api/$metadata#MachineActions/$entity',
     'id': '7d7b92c8-4ac8-4aa5-b222-9f91ca0bf8d9',
     'type': 'LiveResponse',
     'title': None,
     'requestor': '4af2e1ae-893f-415b-ba4e-cc3de20146e3',
     'requestorComment': 'Trigging the magic through API',
     'status': 'InProgress',
     'machineId': '5f5542aadc79bb40ee7878777dc931fb49f56cd6',
     'computerDnsName': 'first2022-demo',
     'creationDateTimeUtc': '2022-06-23T13:19:09.7003031Z',
     'lastUpdateDateTimeUtc': '2022-06-23T13:19:36.719902Z',
     'cancellationRequestor': None,
     'cancellationComment': None,
     'cancellationDateTimeUtc': None,
     'errorHResult': 0,
     'scope': None,
     'externalId': None,
     'requestSource': 'PublicApi',
     'relatedFileInfo': None,
     'commands': [{'index': 0,
       'startTime': None,
       'endTime': None,
       'commandStatus': 'Created',
       'errors': [],
       'command': {'type': 'RunScript',
        'params': [{'key': 'ScriptName', 'value': 'Invoke-LRCollection.ps1'},
         {'key': 'Args', 'value': '-casenum SIR0001337'}]}}}],
     'troubleshootInfo': None}
```
