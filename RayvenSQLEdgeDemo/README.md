# Rayven DB Edge Demo

## Requirements
- Visual Studio Code (required extensions are outlined in the VS Code environment setup section).
- Azure Data Studio.
- .NET Core runtime.
- Docker Community Edition.
- Git & Git LFS.
- Azure Subscription. You can set up a [trial account](https://azure.microsoft.com/en-us/free/search/) here.

## Clone the Rayven DB Edge Demo Repository

Git will be used to copy all the files for the demo to your local computer.  

1. Install Git from [here](https://git-scm.com/download).
1. Install Git LFS from [here](https://help.github.com/en/github/managing-large-files/installing-git-large-file-storage).
    > IMPORTANT: Ensure you have Git LFS installed before cloning the repo or large files will be corrupt. If you find you have corrupt files, you can run `git lfs pull` to download files in LFS.
1. Open a command prompt and navigate to a folder where the repo should be downloaded.
1. Issue the command `git clone https://github.com/microsoft/sqlsourabh.git`.
1. The root of the demo files is the **RayvenDBEdgeDemo** folder.

## Azure Resource Deployment

An Azure Resource Manager (ARM) template will be used to deploy all the required resources in the solution.  Click on the link below to start the deployment. Note that you may need to register Azure Resource Providers in order for the deployment to complete successfully.  If you get an error that a Resource Provider is not registered, you can register the Resource Provider by following the steps in this [link](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types).

Click on the link below to start the deployment.

[![homepage](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fzarmada.blob.core.windows.net%2Farm-deployments-public%2Farm-template-rded.json "Deploy template")

### Deployment of resources

Follow the steps to deploy the required Azure resources:

**BASICS**  

   - **Subscription**: Select the Subscription.
   - **Resource group**:  Click on 'Create new' and provide a unique name for the Resource Group.
   - **Location**: Select the Region where to deploy the resources. Keep in mind that all resources will be deployed to this region, so make sure it supports all of the required services.

        > **NOTE**: The template has been confirmed to work in West US 2 region.
   - **Environment**: The template will generate a unique ID or you can enter your own prefix for resources.

1. Click **Review + create**.
1. Click **Create** and wait for the deployment to finish.

## Post Deployment Configuration

Some resources require some additional configuration.

### Upload SQL DACPAC 

The Edge Module will require access the DACPAC package in order to setup the database.

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
1. Select the **Storage account** resource from the list.
1. Click the **Containers** option in the left menu under **Blob service**.
1. Click the **files** container.
1. Click the **Upload** button.
1. Click the **Select a file** input and select the file under the project folder: `sql/RealtimeSensorData.zip`.
1. Click the **Upload** button.
1. Once the file is uploaded, click on it. 
1. Click **Generate SAS** tab.
1. Update the **Expiry** year to 2100.
1. Click **Generate SAS token and URL**
1. Copy the value in **Blob SAS URL** and save it for later in the setup.

### Upload ONNX Model

The Edge Module will require access the ONNX model to detect issues.

>**IMPORTANT!** The below steps allow you to upload a **pre-trained model** to save time. If you would like to train your own model, please refer to the **Notebook setup and creating the model** in the **Optional Steps** section and use that one instead.

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
1. Select the **Storage account** resource from the list.
1. Click the **Containers** option in the left menu under **Blob service**.
1. Click the **files** container.
1. Click the **Upload** button.
1. Click the **Select a file** input and select the file under the project folder: `ml/model.onnx`.
1. Click the **Upload** button.
1. Once the file is uploaded, click on it. 
1. Click **Generate SAS** tab.
1. Update the **Expiry** year to 2100.
1. Click **Generate SAS token and URL**
1. Copy the value in **Blob SAS URL** and save it for later in the setup.

#### SQL Security Setup Information

> **IMPORTANT!**: The following is a **review only** to observe the security setup in the DACPAC package. There are also some example queries to test the security rules in the **Optional Steps** section at the end of the README. 

1. Create users without a login for simpler testing:
    ```sql
    /* Create users using the logins created */
    CREATE USER OperatorUser WITHOUT LOGIN;
    CREATE USER SensorUser WITHOUT LOGIN;
    CREATE USER Tech01User WITHOUT LOGIN;
    CREATE USER Tech02User WITHOUT LOGIN;
    CREATE USER Tech03User WITHOUT LOGIN;
    CREATE USER Tech04User WITHOUT LOGIN;
    ```

1. Assigned permissions for each user:
    ```sql
    /* Grant permissions to users */
    GRANT SELECT ON RealtimeSensorRecord TO Tech01User;
    GRANT SELECT ON RealtimeSensorRecord TO Tech02User;
    GRANT SELECT ON RealtimeSensorRecord TO Tech03User;
    GRANT SELECT ON RealtimeSensorRecord TO Tech04User;
    GRANT SELECT ON RealtimeSensorRecord TO OperatorUser;
    GRANT SELECT, INSERT ON RealtimeSensorRecord TO SensorUser;
    ```
    > **NOTE**: All users can SELECT, however the SensorUser can also INSERT to the table.

1. For privacy reasons, mask the last 4 digits of the SensorId for the Operator user:
    ```sql
    /* Mask the last four digits of the serial number (Sensor ID) for the Operator User */
    ALTER TABLE RealtimeSensorRecord
    ALTER COLUMN SensorId varchar(50) MASKED WITH (FUNCTION = 'partial(34,"XXXX",0)');
    DENY UNMASK TO OperatorUser;
    GO
    ```

1. Add a policy using a filter predicate and a function to manage access to data events:
    *  We updated the Owner column as it is required in our function then created a new schema to store it.
    ```sql
    ALTER TABLE RealtimeSensorRecord
    ALTER COLUMN Owner sysname
    GO

    CREATE SCHEMA Security;
    GO
    ```

    *  Add the function that will ensure each query is authorized based on Sensor Type/User.       
    ```sql
    /**
    * Operator: Can see all events
    * Tech01User: Can ONLY see the events that they own
    * Tech02User: Can ONLY see the events that they own
    * Tech03User: Can ONLY see the events that they own
    * Tech04User: Can ONLY see the events that they own
    */
    CREATE FUNCTION Security.fn_securitypredicate(@Owner AS sysname)
    RETURNS TABLE
    WITH SCHEMABINDING
    AS
    RETURN SELECT 1 AS fn_securitypredicate_result
        WHERE
            USER_NAME() = 'OperatorUser' OR USER_NAME() = 'dbo' OR
            (USER_NAME() = 'Tech01User' AND @Owner = 'TECH-01') OR
            (USER_NAME() = 'Tech02User' AND @Owner = 'TECH-02') OR
            (USER_NAME() = 'Tech03User' AND @Owner = 'TECH-03') OR
            (USER_NAME() = 'Tech04User' AND @Owner = 'TECH-04');
    ```

    * Add a filter to to use the function.
    ```sql
    CREATE SECURITY POLICY SensorsDataFilter
    ADD FILTER PREDICATE Security.fn_securitypredicate(Owner)
    ON dbo.RealtimeSensorRecord
    WITH (STATE = ON);
    ```

    *  Add the function that will ensure each query is authorized based on Sensor Type/User.       
    ```sql
    /**
    * Operator: Can see all events
    * Tech01User: Can ONLY see the events that they own
    * Tech02User: Can ONLY see the events that they own
    * Tech03User: Can ONLY see the events that they own
    * Tech04User: Can ONLY see the events that they own
    */
    CREATE FUNCTION Security.fn_securitypredicate(@Owner AS sysname)
    RETURNS TABLE
    WITH SCHEMABINDING
    AS
    RETURN SELECT 1 AS fn_securitypredicate_result
        WHERE
            USER_NAME() = 'OperatorUser' OR USER_NAME() = 'dbo' OR
            (USER_NAME() = 'Tech01User' AND @Owner = 'TECH-01') OR
            (USER_NAME() = 'Tech02User' AND @Owner = 'TECH-02') OR
            (USER_NAME() = 'Tech03User' AND @Owner = 'TECH-03') OR
            (USER_NAME() = 'Tech04User' AND @Owner = 'TECH-04');
    ```

### Device Setup

In this section, we will set up an Edge device within our IoT Hub instance. 

#### Create a new Edge device

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
1. Select the **IoT Hub** resource.
1. Click on **IoT Edge** from the left navigation.
1. Click **+ Add an IoT Edge Device**.
1. Enter a **Device ID**, for example `ventilator-hub`, and leave all other fields as default.
1. Click **Save**.
1. Once the device has been created, select the device and copy the **Primary Connection String** for later in this setup.

#### Setup Edge device as a VM

1. Click on the link below to start the deploy to Azure:

    [![homepage](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazure%2Fiotedge-vm-deploy%2Fmaster%2FedgeDeploy.json "Deploy device")

1. On the newly launched window, fill in the available form fields:

    * **Subscription**: Your subscription.
    * **Resource group**: Select the resource group you created earlier.
    * **Region**: This will default to the one you used in the ARM deployment.
    * **DNS Label Prefix**: Your initials and birth year.
    * **Admin Username**: Enter `microsoft` as default.
    * **Device Connection String**: The device connection string that you got from previous section.
    * **VM Size**: The size of the virtual machine to be deployed.
    * **Ubuntu OS Version**: The version of the Ubuntu OS to be installed on the base virtual machine.
    * **Location**: The geographic region to deploy the virtual machine into, this value defaults to the location of the selected Resource Group.
    * **Authentication Type**: Choose the **password** option.
    * **Admin Password or Key**: Enter `M1cr0s0ft2020`.

1. Select **Review + create**.
1. Select **Create** to start the deployment.
1. Wait for the deployment to finish before continuing.

#### Create inbound rule to allow SQL Server connection

We need to create a new inbound rule to allow the connection to our SQL DB Edge Instance.

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
1. Select the **Virtual Machine** resource.
1. Copy the **DNS name** value that will be use for later access to the VM using SSH and SQL server connection.
1. Click the **Networking** option in the left menu.
1. Click the **Add inbound port rule** button.
1. For the **Destination port ranges** input enter the **31433** value.
1. Change the **Name** value to **Port_31433**.
1. Click the **Add** button.
1. Wait for the process to finish, you should be able to see the new rule in the list after a few seconds.
> **NOTE**: This rule allows the connection from all sources.

#### Setup Visual Studio Code Development Environment

1. Install [Visual Studio Code](https://code.visualstudio.com/Download) (VS Code).
1. Install [Docker Community Edition (CE)](https://docs.docker.com/install/#supported-platforms). Don't sign in to Docker Desktop after Docker CE is installed.
1. Install the following extensions for VS Code:
    * [Azure Machine Learning](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.vscode-ai) ([Azure Account](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account) will be automatically installed)
    * [Azure IoT Hub Toolkit](https://marketplace.visualstudio.com/items?itemName=vsciot-vscode.azure-iot-toolkit)
    * [Azure IoT Edge](https://marketplace.visualstudio.com/items?itemName=vsciot-vscode.azure-iot-edge)
    * [Docker Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)
1. Restart VS Code.
1. Select **[View > Command Palette…]** to open the command palette box, then enter **[Python: Select Interpreter]** command in the command palette box to select your Python interpreter.
1. Enter **[Azure: Sign In]** command in the command palette box to sign in Azure account and select your subscription.

#### Build and deploy container image to device

1. Launch Visual Studio Code, and select File > Open Workspace... command to open the `edge\sensor-solution.code-workspace`.
1. Update the .env file with the values for your container registry.
    - In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
    - Select the **Container Registry** resource.
    - Select **Access Keys** from the left navigation.
    - Update the following in `edge/SensorSolution/.env` with the following values from  **Access Keys** within the Container Registry:

        CONTAINER_REGISTRY_SERVER=`<Login server>`

        CONTAINER_REGISTRY_USER_NAME=`<Username>`

        CONTAINER_REGISTRY_PASSWORD=`<Password>`

        SQL_PACKAGE=`<SQL Package Blob URL>` (the one you obtained earlier in the setup)

    - Save the file.
1. Sign in to your Azure Container Registry by entering the following command in the Visual Studio Code integrated terminal (replace <REGISTRY_USER_NAME>, <REGISTRY_PASSWORD>, and <REGISTRY_SERVER> with your container registry values set in the .env file IN THE PREVIOUS STEP).

    `docker login -u <CONTAINER_REGISTRY_USER_NAME> -p <CONTAINER_REGISTRY_PASSWORD> <CONTAINER_REGISTRY_SERVER>`

    > **IMPORTANT**: Ensure you have `amd64` selected as the architecture in the bottom navigation bar of VS Code.

1. Right-click on `edge/SensorSolution/deployment.debug.template.json` and select the **Build and Push IoT Edge Solution** command to generate a new `deployment.debug.json` file in the config folder, build a module image, and push the image to the specified ACR repository.
    > **IMPORTANT:** If you have amended code in your module, you will need to increment the version number in `module.json` so the new version will get deployed to the device in the next steps.

    > **NOTE**: Some red warnings "/usr/bin/find: '/proc/XXX': No such file or directory" and "debconf: delaying package configuration, since apt-utils is not installed" displayed during the building process can be ignored.

1. Ensure you have the correct Iot Hub selected in VS Code.
    - In the Azure IoT Hub extension, click **Select IoT Hub** from the hamburger menu. (Alternatively, select `Azure IoT Hub: Select IoT Hub` from the  **Command Palette**)
    - Select your **Subscription**.
    - Select the **IoT Hub** you created earlier in the setup.
1. Right-click `config\deployment.debug.json` and select **Create Deployment for a Single Device**.
1. Select the device you created earlier.
1. Wait for deployment to be completed.
1. After a few minutes you should be able to see the list of IoT Edge Modules running on you device via the Azure Iot Hub VS Code extension. 

### SQL Edge Server Streaming Job setup

Initially we will see how to connect to the SQL Edge Server from Azure Data Studio. 

>**NOTE**: The setup of the VM device and deployment of modules are required before this section.

1. Open **Azure Data Studio**.
1. Click the **Connections** icon in the left menu.
1. Click the **New connection** icon.
1. Enter the following information in the input fields:
   * Server: DNS or IP address of the device vm created + the port 31433. For example: `<your intials and birthdate>.westus2.cloudapp.azure.com,31433`.
   * Authentication Type: SQL Login
   * User name: `sa`
   * Password: `Microsoft2020$`
1. Click the **Connect** button.

Now that we can connect to our SQL Edge DB, we can setup the Streaming Job to check for temperature anomalies.

1. In **Azure Data Studio** click the **File** option in the menu.
1. Select the **Open File...** option.
1. Search for the file in your project folder at `sql/streaming-job.sql`.
1. Select the `RealTimeSensorData` database from the list in the top navigation dropdown.
1. Click **Run** from the top navigation.
      > NOTE: You may need to click **Connect** to select the database for the script to run against.
1. You can run the following script to view the generated data from the job.
    ```sql
    SELECT TOP 1000 *
    FROM [RealtimeSensorData].[dbo].[TemperatureAnomaliesData]
    ORDER BY [Timestamp] DESC
    GO
    ``` 

### Apply ONNX Model to device

Next we will apply our ONNX Model to the device to trigger anomalies. The below uses a simple console app to update the module properties for simplicity purposes. However, you can use the Azure Portal or any another method if you prefer. 

1. Open Visual Studio Code and Open the `device-update-app` folder.
1. Open a new terminal and run the following command: `dotnet run`
1. You will be prompted for 2 values:
    * **IoTHubConnectionString**. To obtain this value, do the following:
       1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
       1. Select the **IoT Hub** resource.
       1. Click the **Shared access policies** option in the left menu.
       1. Click the **iothubowner** policy from the list.
       1. Copy the **Connection string—primary key** from the new panel.
    * **DeviceId**. This is the ID that you used to create the IoT Edge device earlier in the setup.
1. The following commands will now be available:
    * **status**: Will return the reported properties by the device.
    * **set-onnx-url**: Apply the ONNX SAS URL you created earlier in the setup.
    * **exit**: Stop the app.
1. Once you have updated the ONNX SAS URL. You will be able to see that issues are being detected in the module logs. To access the logs, follow the **SSH into the VM** section and run the command `iotedge logs -f SensorModule`.

### Setting up Data Sync

Azure SQL DB Edge is fully compatible with SQL Data Sync. To sync your DB Edge data to an Azure SQL Database, follow the [tutorial](https://docs.microsoft.com/en-us/azure/azure-sql-edge/tutorial-sync-data-sync).

## Optional Steps

This section describe steps that allow us to see extra features of the resources as a reference only.

### SSH into the VM

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier. 
1. Select the **Virtual Machine** resource.
    > **NOTE**: Take note of the machine name, this should be in the format vm-0000000000000. Also, take note of the associated DNS Name, which should be in the format `<dnsLabelPrefix>.<location>.cloudapp.azure.com`.
    The DNS Name can be obtained from the Overview section of the newly deployed virtual machine within the Azure portal.

1. If you want to SSH into this VM, use the associated DNS Name with the command: `ssh <adminUsername>@<DNS_Name>` and the password you entered when creating the Virtual Machine. 

### SQL Security testing

Here we will see a few SQL queries that allow you to test the security setup on our database that was setup as part of the DACPAC deploy and describe in previous sections.

1. Testing operation permissions, Operator User can select but can't delete events.
    ```sql
    EXECUTE AS USER = 'OperatorUser';
    SELECT * FROM RealtimeSensorRecord;
    DELETE FROM RealtimeSensorRecord WHERE SensorType = 'Peep';
    REVERT;
    ```

1. Testing the data masking for Operator User that should not see the latest 4 digits (XXXX).
    ```sql
    EXECUTE AS USER = 'OperatorUser';
    SELECT TOP 10 RecordId, SensorId FROM RealtimeSensorRecord;
    REVERT;
    ```

1. Testing Row-Level Security policy with Operator that can see all the events.
    ```sql
    EXECUTE AS USER = 'OperatorUser';
    SELECT TOP 10 * FROM RealtimeSensorRecord;
    REVERT;
    ```

1. Testing Row-Level Security policy with Tech01User that can see ONLY the events that they own.
    ```sql
    EXECUTE AS USER = 'Tech01User';
    SELECT TOP 10 * FROM RealtimeSensorRecord;
    REVERT;
    ```

1. Testing Row-Level Security policy with Tech02User that can see ONLY the events that they own.
    ```sql
    EXECUTE AS USER = 'Tech02User';
    SELECT TOP 10 * FROM RealtimeSensorRecord;
    REVERT;
    ```

### Notebook setup and creating the model

In this section, we will generate a model using an Azure ML Notebook. 

#### Upload training data files

1. In the [Azure portal](https://portal.azure.com/) select the **Resource Group** you created earlier.
1. Select the **Storage account** resource.
1. Click the **Containers** option in the left menu under **Blob service**.
1. Click the **azureml-blobstore-GUID** container.
1. Click the **Upload** button in the top.
1. Click the **Select a file** input and select all the files in the `ml\data\` folder from your repo.
1. Click the **Upload** button and wait for the upload to finish.

#### Dataset setup

1. Go back to the **Resource Group** you created earlier into the Azure Portal.
1. Select the **Machine Learning** resource.
1. Click the **Launch studio** button to open the Machine Learning workspace.
1. Click the **Datasets** option in the left menu.
1. Click the **+ Create dataset** option in the main panel.
1. Click the **From datastore** option from the list.
1. Enter the **Name** `predictive_maintenance`.
1. Leave **Dataset type** as `Tabular` and click the **Next** button.
1. Select the **Previously created datastore** if it's not selected.
1. Select the **workspaceblobstore (Default)** option from the list.
1. Click the **Select datastore** button.
1. For the **Path** input enter the value `/*.parquet`.
1. Click the **Next** button and wait for the preview of data to load.
1. Click the **Next** button.
1. Leave all the schema definition as it is and click the **Next** button.
1. Click the **Create** button.

#### Notebook files upload

1. Still in the machine learning studio.
1. Click the **Notebooks** option in the left menu under **Author**.
1. Click the **Upload files** button.
1. Select the following file inside the `ml` folder:
    * `ml\notebook\Rayven_training.ipynb`
1. Select your username folder from the target directory list if required.
1. Select the **Overwrite if already exists** option.
1. Select the **I trust contents of this file** option.
1. Click the **Upload** button.

#### Notebook configuration

We need configure values within the notebook before being able to execute it:

1. Click the `Rayven_training.ipynb` in the **My files** navigation:
1. Click the **New Compute** button.
1. Select **CPU (Central Processing Unit)** from the **Virtual machine type** dropdown.
1. Select the virtual machine size **Standard_D2_v2** and click next.
1. Enter the **Compute name** `compute-{your-initials}`.
1. Click the **Create** button and wait for the compute to be created.
    > **NOTE**: This process can take several minutes; wait until the status of **compute** is **Running**.
1. Click the **Edit** dropdown and select the **Edit in Jupyter** option.
    > **NOTE**: If required, login with your Azure credentials.
1. Replace the following values within the **Setup Azure ML** cell.
    ```
    subscription_id = '<azure-subscription-id>'
    resource_group = '<resource-group>'
    workspace_name = '<ml-workspace-name>'
    ```
1. Click **File** > **Save and Checkpoint** from the menu.
1. Select the **Setup Azure ML** cell and click **Run** from the menu.
    > **IMPORTANT**: Observe the output to **authenticate** via the URL provided (https://microsoft.com/devicelogin).  
1. From here, **Run** the remaining cells sequentially until you have executed the notebook. 
    > **IMPORTANT**: Remember to wait for each cell to execute before continuing.
1. After you have finished, you will see the `model.onnx` file be created within your **User files**. Click **Refresh** if you do not see the file. 
