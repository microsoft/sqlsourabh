namespace SensorModule
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.IO;
    using System.Runtime.InteropServices;
    using System.Runtime.Loader;
    using System.Security.Cryptography.X509Certificates;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.Azure.Devices.Client;
    using Microsoft.Azure.Devices.Client.Transport.Mqtt;
    using Microsoft.Azure.Devices.Shared;
    using Newtonsoft.Json;
    using SensorModule.Models;
    using SensorModule.Services;
    using SensorModule.Services.Interfaces;

    class Program
    {
        private static IDataGeneratorService _datageneratorservice;
        private static IDataStoreService _datastoreservice;
        private static ModuleClient _ioTHubModuleClient;
        static int PushTimeInterval { get; set; } = 5000;
        static bool BlockedDataGeneration { get; set; } = false;

        static async Task Main(string[] args)
        {
            _datageneratorservice = new DataGeneratorService();
            _datastoreservice = new DataStoreService();

            await Init();

            try
            {
                Console.WriteLine("Truncating sensors table before start pushing data");
                _datastoreservice.TruncateRealtimeSensorRecordTable();
            }
            catch(Exception e)
            {
                Console.WriteLine("Error truncating table: " + e.Message);
            }

            Console.WriteLine($"Starting writing realtime records with {PushTimeInterval} millisecond interval to database...");

            while (true)
            {
                if (!BlockedDataGeneration)
                {
                  var timestamp = DateTime.Now;
                  var records = _datageneratorservice.GenerateRealTimeSensorRecords(timestamp);
                  Console.WriteLine($"[{DateTime.Now}] Writing records to db.");
                  _datastoreservice.WriteSensorRecordsToDB(records);
                  // Loop ventilators
                  _datageneratorservice.GetVentilators().ForEach(ventilator =>
                  {
                    var modelResult = _datastoreservice.GetModelResult(ventilator, timestamp);
                    if (modelResult == 1)
                    {
                      Console.WriteLine($"[{DateTime.Now}] Ventilator [{ventilator.VentilatorGuid}] issue detected.");
                    }
                  });

                  await SendRecordMessage(records);
                }
                await Task.Delay(PushTimeInterval);
            }
        }

        public static async Task SendRecordMessage(List<RealtimeSensorRecord> records)
        {
          foreach (var temperatureRecord in records.Where(elem => string.Equals(elem.SensorType, Constants.Sensors.Temperature, StringComparison.OrdinalIgnoreCase)))
          {
            var record = new TemperatureRecord
            {
              RecordId = Guid.NewGuid(),
              VentilatorId = temperatureRecord.VentilatorId,
              VentilatorNumber = temperatureRecord.VentilatorNumber,
              Temperature = temperatureRecord.SensorValue,
              Timestamp = temperatureRecord.Timestamp,
            };
            var messageString = JsonConvert.SerializeObject(record);
            var message = new Message(Encoding.ASCII.GetBytes(messageString));
            await _ioTHubModuleClient.SendEventAsync("TemperatureSensors", message);
          }
        }

        /// <summary>
        /// Handles cleanup operations when app is cancelled or unloads
        /// </summary>
        public static Task WhenCancelled(CancellationToken cancellationToken)
        {
            var tcs = new TaskCompletionSource<bool>();
            cancellationToken.Register(s => ((TaskCompletionSource<bool>)s).SetResult(true), tcs);
            return tcs.Task;
        }

        /// <summary>
        /// Initializes the ModuleClient and sets up the callback to receive
        /// messages containing temperature information
        /// </summary>
        static async Task Init()
        {
            _ioTHubModuleClient = await ModuleClient.CreateFromEnvironmentAsync();
            _ioTHubModuleClient.SetDesiredPropertyUpdateCallbackAsync(OnDesiredPropertyChanged, null).Wait();
            Console.WriteLine("IoT Hub module client initialized.");

            // Read from the module twin's desired properties
            var moduleTwin = await _ioTHubModuleClient.GetTwinAsync();
            await OnDesiredPropertyChanged(moduleTwin.Properties.Desired, _ioTHubModuleClient);
        }

        static async Task SetReportedProperty(string property, string value)
        {
            Console.WriteLine($"Sending {property} as reported property with value `{value}`.");
            TwinCollection reportedProperties = new TwinCollection
            {
              [property] = value
            };
            await _ioTHubModuleClient.UpdateReportedPropertiesAsync(reportedProperties);
        }

        static async Task OnDesiredPropertyChanged(TwinCollection desiredProperties, object userContext)
        {
            try
            {
                Console.WriteLine("Desired property change:");
                Console.WriteLine(JsonConvert.SerializeObject(desiredProperties));
                await Task.Delay(100);

                if (desiredProperties["SqlConnnectionString"]!=null)
                {
                    var connectionString = desiredProperties["SqlConnnectionString"];
                    Console.WriteLine($"Updating SqlConnectionString: {connectionString}");
                    _datastoreservice.SetSqlConnectionString($"{connectionString}");
                }

                if (desiredProperties["PushTimeInterval"]!=null)
                {
                    var pushTimeInterval = desiredProperties["PushTimeInterval"];
                    Console.WriteLine($"Updating PushTimeInterval to: {pushTimeInterval}");
                    PushTimeInterval = desiredProperties["PushTimeInterval"];
                }

                if (desiredProperties["OnnxModelUrl"]!=null)
                {
                    // Re-Create the Model Table in DB to keep only one record of the model
                    _datastoreservice.DropAndCreateModelTable();
                    var onnxModelUrl = $"{desiredProperties["OnnxModelUrl"]}";
                    if (!string.IsNullOrEmpty(onnxModelUrl))
                    {
                        Console.WriteLine($"Updating OnnxModelUrl: {onnxModelUrl}");
                        // Insert the model into the created table
                        _datastoreservice.InsertModelFromUrl($"{onnxModelUrl}");
                    }
                }
            }
            catch (AggregateException ex)
            {
                foreach (Exception exception in ex.InnerExceptions)
                {
                    Console.WriteLine();
                    Console.WriteLine("Error when receiving desired property: {0}", exception);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine();
                Console.WriteLine("Error when receiving desired property: {0}", ex);
            }
        }
    }
}
