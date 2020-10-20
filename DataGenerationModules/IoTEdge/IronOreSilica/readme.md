# Ironore Silica Prediction Data Generator Module 

This sample project generates iron ore floatation data. The main objective of iron ore floatation is to  improve the concentration by removing impurities. The data generated using this IoT Edge module, can be used to used in various machine learning exercises. 

## Prerequisites 

1. Visual Studio 2019 with 
  - Azure IoT Edge Tools
  - .Net Core Cross-platform development 
  - Container Development Tools
2. Docker
3. Setup your environment to debug, run, and test your IoT Edge solution by installing the [Azure IoT EdgeHub Dev Tool](https://pypi.org/project/iotedgehubdev/).

## Using the Project. 

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
4. Execute the project in either debug or release mode to ensure that the project runs without any issues. 
5. Push the project to your container register by right clicking on the project name and then selecting **Build and Push IoT Edge Modules**

## Key Components

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
    cur_Flotation_Column_07_Air_Flow
    cur_Flotation_Column_04_Level
    cur_Flotation_Column_05_Level
    cur_Flotation_Column_06_Level
    cur_Flotation_Column_07_Level
    cur_Iron_Concentrate
}
```



