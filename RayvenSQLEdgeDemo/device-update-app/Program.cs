using System;
using System.Configuration;
using System.CommandLine;
using System.CommandLine.Invocation;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.Devices;
using Microsoft.Azure.Devices.Client;
using Microsoft.Azure.Devices.Common.Exceptions;
using Microsoft.Azure.Devices.Shared;
using Newtonsoft.Json;


namespace DeviceUpdateApp
{
  class Program
  {
    private static string _ownerConnectionString;
    private static string _deviceId;
    private static string _moduleId;
    private static RegistryManager _registryManager;

    static void Main(string[] args)
    {
      _moduleId = ConfigurationManager.AppSettings["ModuleId"];
      Setup();
      string commandString = string.Empty;
      Console.ForegroundColor = ConsoleColor.White;
      Console.WriteLine("");
      Console.WriteLine("");
      Console.WriteLine("***********************************************************");
      Console.WriteLine("*         TwinModule Desired Properties Updates           *");
      Console.WriteLine("*                                                         *");
      Console.WriteLine("*             Type commands to get started                *");
      Console.WriteLine("*                                                         *");
      Console.WriteLine("***********************************************************");
      Console.WriteLine("");

      // main command cycle
      while (!commandString.Equals("Exit"))
      {
        Console.ResetColor();
        Console.WriteLine("Enter command (set-onnx-url | status | help | exit) >");
        commandString = Console.ReadLine();

        switch (commandString.ToUpper())
        {
          case "STATUS":
            PrintStatus().Wait();
            break;
          case "SET-ONNX-URL":
            SetOnnxUrl().Wait();
            break;
          case "HELP":
            Help();
            break;
          case "EXIT":
            Console.WriteLine("Bye!");
            return;
          default:
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("Invalid command.");
            break;
        }
      }

      Console.WriteLine("\n\nPress any key to exit");
      Console.ReadKey();
    }

    private static void Setup()
    {
      Console.WriteLine("");
      Console.WriteLine("Enter the IoT Hub Connection String:");
      _ownerConnectionString = Console.ReadLine();
      Console.WriteLine("Enter the Device Id:");
      _deviceId = Console.ReadLine();
      Console.WriteLine("");
      Console.WriteLine("App will use the following setup:");
      Console.WriteLine($"  IoTHubConnectionString: {_ownerConnectionString}");
      Console.WriteLine($"  DeviceId: {_deviceId}");
      Console.WriteLine($"  ModuleId: {_moduleId}");
      Console.WriteLine("");
    }

    private static void Help()
    {
      Console.ForegroundColor = ConsoleColor.Green;
      Console.WriteLine("");
      Console.WriteLine("SET-ONNX-URL     - Update the model onnx url file to trigger this feature.");
      Console.WriteLine("STATUS           - Print the current status of the device");
      Console.WriteLine("HELP             - Displays this page");
      Console.WriteLine("EXIT             - Closes this program");
      Console.WriteLine("");
      Console.ResetColor();
    }

    private static void ConnectRegistryManager()
    {
      if (_registryManager != null)
      {
        return;
      }

      _registryManager = RegistryManager.CreateFromConnectionString(_ownerConnectionString);
    }

    private static async Task<Twin> ConnectModuleTwin()
    {
      ConnectRegistryManager();
      try
      {
        return await _registryManager.GetTwinAsync(_deviceId, _moduleId);
      }
      catch (Exception e)
      {
        throw e;
      }
    }

    private static async Task SetDesiredProperty(string property, string value)
    {
      var twin = await ConnectModuleTwin();
      twin.Properties.Desired[property] = value;
      await _registryManager.UpdateTwinAsync(twin.DeviceId, twin.ModuleId, twin, twin.ETag);
    }

    private static async Task SetOnnxUrl()
    {
      Console.WriteLine("Enter the url (SAS must be included in url):");
      var url = Console.ReadLine();
      Console.WriteLine($"Setting OnnxUrl to: {url}");
      await SetDesiredProperty("OnnxModelUrl", url);
    }

    private static async Task OnDesiredPropertyChanged(TwinCollection desiredProperties, object userContext)
    {
      Console.WriteLine("Desired property change:");
      Console.WriteLine(JsonConvert.SerializeObject(desiredProperties));
    }

    private static async Task PrintStatus()
    {
      var twin = await ConnectModuleTwin();
      Console.WriteLine($"Device Reported Properties Model {twin.Properties.Reported.ToJson()}");
      var device = JsonConvert.DeserializeObject<DeviceModel>(twin.Properties.Reported.ToJson());

      Console.ForegroundColor = ConsoleColor.Green;
      Console.WriteLine("");
      Console.WriteLine($"Properties:");
      Console.WriteLine($"Onnx Model File Url: {device.OnnxModelUrl}");
      Console.WriteLine("");
      Console.ResetColor();
    }
  }

  public class DeviceModel
  {
    public string OnnxModelUrl { get; set; }
  }
}
