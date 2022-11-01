import requests
import json # Note: Not a dependency. Built-in to Python.

def Verify_vCenter_VM_Name(context, inputs):
##  STAGE 1: Obtain Requested Name
    """Set a name for a machine
    :param inputs
    :param inputs.resourceNames: Contains the original name of the machine.
           It is supplied from the event data during actual provisioning
           or from user input for testing purposes.
    :param inputs.newName: The new machine name to be set.
    :return The desired machine name.
    """
    oldName = inputs["resourceNames"][0]
    newName = inputs["customProperties"]["newName"]

    
##  STAGE 2: Verify Uniqueness with vCenter     
    
    # Step 0: Create a vCenter login session token and use for subsequent API calls.
    #    --  Ref URL: https://developer.vmware.com/apis/vsphere-automation/latest/cis/api/session/post/
    #    --  -- NOTE: Includes: vCenter authorization credentials in Base64 as 'username:password'
    #    --  -- ** APPROACH IS NOT SAFE FOR PRODUCTION USECASES **
    requestUrl = "https://vcsa-01a.corp.tanzu/api/session"
    auth = "Basic YWRtaW5pc3RyYXRvckB2c3BoZXJlLmxvY2FsOlZNd2FyZTEh"
    headers = {"Authorization": auth}
    response = requests.post(requestUrl, headers = headers, verify = False)
    jsonResponse = response.json()
    
    vmware_api_session_id = jsonResponse
    print('_Request response code is (expected:201): ' + str(response.status_code))
    print('_Request session id is : ' + vmware_api_session_id)
    
    # Step 1: Define REST request URL (Example below is for VM list): 
    #    -- Ref URL: https://developer.vmware.com/apis/vsphere-automation/v7.0U3/vcenter/
    requestUrl = "https://vcsa-01a.corp.tanzu/api/vcenter/vm?names=" + newName
    print(requestUrl)
    # Step 2: Provide REST Header
    headers = {"vmware-api-session-id": vmware_api_session_id}
    
    # Step 3: Execute GET request
    response = requests.get(requestUrl, headers = headers, verify = False)
    print('_Request response code is (expected: 200): ' + str(response.status_code))
    
    # Step 4: Extract response body as JSON (i.e. List of VMs if successful)
    jsonResponse = response.json()
    
    # Step 5: If list contains elements, then VM name is NOT unique. Adjust name.
    if (jsonResponse):
        print("VM name is already taken! Adjusting name with add-on.")
        newName = newName + "-DUPLICATEDNAME"
        
## STAGE 3:  Return Output Name
    outputs = {}
    # Note: Input is of type array (e.g. ["oldFirstName","oldSecondName"] )
    outputs["resourceNames"] = inputs["resourceNames"]
    # Note: Replacement of first element (e.g. ["newName","oldSecondName"] )
    outputs["resourceNames"][0] = newName

    return outputs
