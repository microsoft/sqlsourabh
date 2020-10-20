# Iron Ore Silica prediction with Azure SQL Edge

The sample code in this repo provides a simple demostration of the Data Streaming and the ML inferencing capabilities of Azure SQL Edge on Azure IoT Edge. The main objective of the sample is to predict the silica impurities (or Iron Concentration) in the output from the iron ore floatation process. 

The sample code includes the following components 

1. Iron Ore flotation data generation module - The sample C# IoT Edge project simulates data points from an iron ore floatation process. The data attribute definition is inspired from the [quality-prediction-in-a-mining-process](https://www.kaggle.com/edumagalhaes/quality-prediction-in-a-mining-process) on kaggle.
2. SQL Scripts - The sample scripts to create the database, underlying tables and the Data Streaming objects for data ingestion. 
3. Python Notebook - For training an ML model using Azure AutoML for predicting the percentage of silica imprurties in the output. 

## Building and Deploying the Data Generator IoT Edge module

### Prerequisites 

1. Visual Studio 2019 with 
  - Azure IoT Edge Tools
  - .Net Core Cross-platform development 
  - Container Development Tools
2. Docker
3. Setup your environment to debug, run, and test your IoT Edge solution by installing the [Azure IoT EdgeHub Dev Tool](https://pypi.org/project/iotedgehubdev/).

### Key Components

1. The solution uses a default interval of 500 milliseconds between each message sent to the Edge Hub. This can be changed in the Program.cs file. 
```csharp
TimeSpan messageDelay = configuration.GetValue("MessageDelay", TimeSpan.FromMilliseconds(500));
```

2. The solution generated a message, with the following attributes. Add or remove the attributes as per requirements. 
```json
{
    timestamp 
    cur_Iron_Feed
    cur_Silica_Feed 
    cur_Starch_Flow 
    cur_Amina_Flow 
    cur_Ore_Pulp_pH
    cur_Flotation_Column_01_Air_Flow
    cur_Flotation_Column_02_Air_Flow
    cur_Flotation_Column_03_Air_Flow
    cur_Flotation_Column_04_Air_Flow
    cur_Flotation_Column_01_Level
    cur_Flotation_Column_02_Level
    cur_Flotation_Column_03_Level
    cur_Flotation_Column_04_Level
    cur_Iron_Concentrate
}
```

### Build, Push and deploy the Data Generator Module

1. Clone the Project files locally to you machine. 
2. Open the solution file **IronOre_Silica_Predict.sln** using Visual Studio 2019.
3. Update the container registry details in **deployment.template.json**
  ```json
  "registryCredentials": {
              "RegistryName": {
                "username": "",
                "password": "",
                "address": ""
              }
            }
  ```
4. Update the modules.json file to specify the target container registery (or repository for the module).
  ```json
  "image": {
        "repository": "samplerepro.azurecr.io/ironoresilicapercent",
        "tag": {

  ```
5. Execute the project in either debug or release mode to ensure that the project runs without any issues. 
6. Push the project to your container register by right clicking on the project name and then selecting **Build and Push IoT Edge Modules**
7. Deploy the Data Generator module as an IoT Edge module to your Edge device. The instructions for deploying an edge module to an Edge device are described in the article [Deploy and run the solution](https://docs.microsoft.com/azure/iot-edge/tutorial-csharp-module#deploy-and-run-the-solution). 

> [!IMPORTANT]
> The default module name used in the project is **IronOreSilicaPercent**. In case you plan to change the module name, please make a note of the new name. This would be used while setting up the routes for your IoT Edge deployment. 


## Deploy Azure SQL Edge through IoT Edge. 

Deploy Azure SQL Edge using the instructions in the article [Deploy Azure SQL Edge](https://docs.microsoft.com/azure/azure-sql-edge/deploy-portal). 

## Set the IoT Edge Routes

On the routes page of the Set modules on device page, add the routes as described below. Make sure to update the name of the data generator module and the Azure SQL Edge Module.

```json
FROM /messages/modules/<*your_data_generator_module*>/outputs/IronOreMeasures INTO BrokeredEndpoint("/modules/<*your_azure_sql_edge_module*>/inputs/IronOreMeasures")
```

## Connect to SQL Edge and create database Objects

After deploying SQL Edge, connect to the SQL Edge instance using either SQL Server Management Studio or using Azure Data Studio, as described in the article [Connect to Azure SQL Edge](https://docs.microsoft.com/azure/azure-sql-edge/connect). 

Open the script **/DeploymentScripts/Create_Database_Schema_IoTEdge.sql** in SSMS or ADS and make the changes as mentioned below. 

- Change the Master key encryption password to specify a complex password. 
  ```sql
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MyStr0ng3stP@ssw0rd';
  Go
  ```
- Change the database scoped credential definition to specify the SQL SA (or another login) password. 
  ```sql
  If NOT Exists (select name from sys.database_scoped_credentials where name = 'SQLCredential')
  Begin
    CREATE DATABASE SCOPED CREDENTIAL SQLCredential
    WITH IDENTITY = 'sa', SECRET = '<MySQLSAPassword>'
  End 
  Go
  ```

At this point, you should see the iron ore floatation data landing in the SQL Table **[dbo].[IronOreMeasurements]**. Verify this by running the query below. 
```sql
Select top 10 * from [dbo].[IronOreMeasurements]
order by timestamp desc
```

If you do not see any data in the table, then make sure the following are correct
1. Data Generation module is up and running.
2. The routes are configured correctly as mentioned above. 
3. The streaming job is running. You can check the docker logs output for Azure SQL Edge to see if there are any errors in the streaming job.

## Train, deploy and test the ML model. 

### Prerequisites 

- Azure Data Studio or Visual Studio Code with notebook dependencies installed.
- Azure Machine Learning Workspace

1. Copy and Extract the DeploymentScripts\MiningProcess_Flotation_Plant_Database.zip file.

2. Open the **/DeploymentScripts/MiningProcess_ONNX.ipynb** file in either Azure Data Studio or VS Code. Make sure that you have updated the cells with the actual paths/names from your deployment. 







