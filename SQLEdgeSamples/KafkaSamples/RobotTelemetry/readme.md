# Iron Ore Silica prediction with Azure SQL Edge

The sample code in this repo provides a simple demostration of the T-SQL Streaming capabilities of Azure SQL Edge using Kafka as the streaming source. The main objective of the sample is to define and test the streaming pipeline from a Kafka source.

The sample code includes the following components 

1. Robot and Ambient Telemetry Data Generator- The sample C# project simulates telemetry data points from an Industrial Robot and the surrounding ambient telemetry data.
2. SQL Scripts - The sample scripts to create the database, underlying tables and the T-SQL Streaming objects for data ingestion. 
4. docker-compose.yml file for deploying the various components (Kafka, Zookeeper, SQL Edge and the Data Generator module)

## Building and Publishing the Data Generator container Image

### Prerequisites 

1. Visual Studio 2019 with 
  - .Net Core Cross-platform development 
  - Container Development Tools
2. Docker

### Key Components

1. The solution uses the following default values. This can be changed either in the Program.cs file or specified as environment variables during deployment. Before executing the project, please make sure to change the Kafka server details. 

> [!IMPORTANT]
> To avoid any deployment issues, its recommended that you do not change the Kafka Topic Names.

```csharp
  int threadcount = 5;
  int messageInterval = 1000;
  int messageperthread = 100;
  int partitions_per_topic = 10;
  string kafkaTopic1Name = "RobotTelemetry";
  string kafkaTopic2Name = "AmbientTelemetry";
  string kafkaHostString = "";
```

2. The solution generated a message, with the following attributes for Robot telemetry and Ambient Telemetry. Add or remove the attributes as per requirements. 
```json
{
    RobotID 
    timestamp
    CapacitiveDisplacementSensor
    EngineTemperatureData
    EngineFanSpeed
    TorqueSensorData
    GripRobustness
}
{
    timestamp
    outsideTemperature
    Humidity 
}
```

### Build, Push and deploy the Data Generator Module

1. Clone the Project files locally to you machine. 
2. Open the solution file **RobotTelemetryKafka.sln** using Visual Studio 2019.
3. Update the Kafka Server details and other defaults as mentioned above. 
4. Build and Execute the project in either debug or release mode to ensure that the project runs without any issues. 
5. Push the project to your container register by right clicking on the project name and then selecting **Publish**

## Deploy Modules

This sample uses a docker-compose file to deploy the following components. 
1. ZooKeeper
2. Kafka
3. The Data Generator Module
4. SQL Edge 

Open the docker-compose.yml file in VS Code and update the following components 

- Under Service Kafka 
  - Update the KAFKA_ADVERTISED_HOST_NAME field to use the IP address of your test device where Kafka will be deployed.
- Under Service SQL  
  - Update the SA_PASSWORD to use a strong SQL Password
- Under Service ironoredatagen
  - Update the image tag to use the image URL for the data generator module published above.
  - Update the KAFKA_HOST field to use the IP:PortNumber for your Kafka server. Since all the components are deployed on the same machine, this field will be <MachineIP:9092>


## Connect to SQL Edge and create database Objects

After deploying SQL Edge, connect to the SQL Edge instance using either SQL Server Management Studio or using Azure Data Studio, as described in the article [Connect to Azure SQL Edge](https://docs.microsoft.com/azure/azure-sql-edge/connect). 

> [!NOTE]
> In the deployment above, SQL is configured to listen on Port 1600 on the host.

Open the script **/DeploymentScripts/Create_Database_Schema_IoTEdge.sql** in SSMS or ADS and make the changes as mentioned below. 

- Change the Kafka Server details
```sql
If NOT Exists (select name from sys.external_data_sources where name = 'KafkaInput')
Begin
	Create EXTERNAL DATA SOURCE [KafkaInput] 
	With(
		LOCATION = N'kafka://IP:Port'
	)
End 
Go
```

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

At this point, you should see the iron ore floatation data landing in the SQL Table **[dbo].[RobotSensors]** or **[dbo].[AmbientSensors]**. Verify this by running the query below. 
```sql
Select top 10 * from [dbo].[AmbientSensors]
order by timestamp desc

Select top 10 * from [dbo].[RobotSensors]
order by timestamp desc

```

If you do not see any data in the table, then make sure the following are correct
1. Data Generation module is up and running and sending data to the Kafka. You can verfiy this using the Kafka Extension in VS Code.
2. The streaming job is running. You can check the docker logs output for Azure SQL Edge to see if there are any errors in the streaming job.







