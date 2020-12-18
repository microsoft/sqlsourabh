# Deploy Azure SQL Edge with Azure IoT Edge on K8s

The samples included in the folder can be used to deploy Azure SQL Edge and Azure IoT Edge on a K8s cluster. For the purpose of this sample, Azure Kubernetes Service (AKS) based kubernetes server is being used. 

> [!IMPORTANT] 
> Azure IoT Edge on Kubernetes is currently in preview and should only be used for dev/test deployments. For more information see [Deploy Azure IoT Edge on Kubernetes (preview)](https://microsoft.github.io/iotedge-k8s-doc/introduction.html).

## Prerequisites 

1. K8s Cluster. For the purposes of this sample, an Azure Kubernetes cluster is used. 
2. A dev machine with Kubectl, Helm Charts and Visual Studio Code installed and configured. 

## Steps 

1. Register and IoT Edge device and note down the device connection string. 

2. Connect to your AKS cluster. 

3. Create a new namespace for your IoT Edge deployment. For the purpose of this sample, we will create a new namespace called **iotedge**.

4.  Create the Storage Class and Persistent Volume claims (as mentioned in step 4 and 5) use the **storage.yaml** file. This creates the following storage classes and persistent volume claims in the iotedge namespace.
    - Storage Class - azure-disk
        a. mssql-data - Persistent volume Claim to be used for SQL Edge
        b. edgehub - Persistent volume Claim to be used for the EdgeHub. 
    - Storage Class - azure-file
        a. iotedged - Persistent volume Claim to be used for the iotedge deamon. 

    ```powershell
    kubectl apply -f <path to the storage.yaml file> -n iotedge
    ```

    You can see the details of the PVC's using the command 

    ```powershell
     kubectl describe pvc <name of the pvc> -n <namespace name>
    ```

5. Install the iotedged using the command below. Note that the persistent volume claim name should match the pvc created above. 

    ```powershell
    # Install IoT Edge CRD, if not already installed
    helm install --repo https://edgek8s.blob.core.windows.net/staging edge-crd edge-kubernetes-crd

    # Store the device connection string in a variable (enclose in single quotes)
    $connStr='replace-with-device-connection-string-from-step-1'

    # Install
    helm install --repo https://edgek8s.blob.core.windows.net/staging pv-iotedged-example edge-kubernetes --namespace iotedge --set "iotedged.data.persistentVolumeClaim.name=iotedgefile" --set "provisioning.deviceConnectionString=$connStr" --set "edgeAgent.env.portMappingServiceType=LoadBalancer"
    ```

    This will create the iotedged and the edgeAgent pods in the namespace.

    ```powershell

    PS C:\WINDOWS\system32> kubectl get pods -n iotedge
    NAME                        READY   STATUS    RESTARTS   AGE
    edgeagent-65ff77b6b-sp4db   2/2     Running   0          2m21s
    iotedged-6cdf8d4596-s7kwv   1/1     Running   1          2m46s
    ```

6. Deploy the EdgeHub and SQL Edge modules. In the Visual Studio Code command palette (View menu -> Command Palette...), search for and select Azure IoT Edge: New IoT Edge Solution. Follow the prompts and use the following values to create your solution:

    | Field | Value |
    |--------|--------|
    | Select folder	| Choose the location on your development machine for VS Code to create the solution files. |
    | Provide a solution name	| Enter a descriptive name for your solution or accept the default EdgeSolution.| 
    | Select module template	| Choose Empty solution.| 

    Replace the contents of deployment.template.json file with the contents from **deployment.template.json** available in this sample. 

7. Generate the workload deployment config by right-clicking the deployment.template.json in the left navigation pane and selecting Generate IoT Edge Deployment Manifest. This will generate the minified deployment.amd64.json under the config directory.

8. Update the configuration for the device by right-clicking deployment.amd64.json and selecting Create Deployment for Single Device. In the displayed list, choose the device created in step 1 to complete the operation.

9. In a few minutes, you'll see a the new EdgeHub and the Azure SQL Edge pods up and running. You'll also notice that the external services mapping to the EdgeHub and the SQL Edge deployment created. 

    ```powershell

    PS C:\WINDOWS\system32> kubectl get pods -n iotedge
    NAME                            READY   STATUS             RESTARTS   AGE
    azuresqledge-5cb86fdd68-v2s2d   2/2     Running            0          5m
    edgeagent-65ff77b6b-sp4db       2/2     Running            0          2m
    edgehub-78959f9b55-glb2f        2/2     Running            0          5m
    iotedged-6cdf8d4596-s7kwv       1/1     Running            1          2m
   
    PS C:\WINDOWS\system32> kubectl get services -n iotedge
    NAME           TYPE           CLUSTER-IP     EXTERNAL-IP        PORT(S)                                       AGE
    azuresqledge   LoadBalancer   10.0.153.5     2xx.xxx.xxx.xxx    1600:31894/TCP                                5m
    edgehub        LoadBalancer   10.0.138.238   2xx.xxx.xxx.xxx    5671:30724/TCP,8883:31099/TCP,443:32112/TCP   5m
    iotedged       ClusterIP      10.0.69.59     <none>             35000/TCP,35001/TCP                           2m

    ```



