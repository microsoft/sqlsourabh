namespace TelemetryData
{
    using System;
    using System.Globalization;
    using System.IO;
    using System.Net;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.Azure.Devices.Client;
    using Microsoft.Azure.Devices.Client.Transport.Mqtt;
    using Newtonsoft.Json;
    using Microsoft.Extensions.Configuration;

    class Program
    {
        const int RetryCount = 5;
        //const int msgFreq = 0;
        const string MessageCountConfigKey = "MessageCount";
        static readonly ITransientErrorDetectionStrategy TimeoutErrorDetectionStrategy = new DelegateErrorDetectionStrategy(ex => ex.HasTimeoutException());

        static readonly RetryStrategy TransientRetryStrategy =
            new TelemetryData.ExponentialBackoff(RetryCount, TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(60), TimeSpan.FromSeconds(4));

        static readonly Random Rnd = new Random();
        static readonly AtomicBoolean Reset = new AtomicBoolean(false);

        public enum ControlCommandEnum
        {
            Reset = 0,
            Noop = 1
        }

        public static int Main() => MainAsync().Result;

        static async Task<int> MainAsync()
        {
            Console.WriteLine($"[{DateTime.UtcNow.ToString("MM/dd/yyyy hh:mm:ss.fff tt", CultureInfo.InvariantCulture)}] Main()");

            IConfiguration configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("config/appsettings.json", optional: true)
                .AddEnvironmentVariables()
                .Build();

            TimeSpan messageDelay = configuration.GetValue("MessageDelay", TimeSpan.FromMilliseconds(5000));
            int messageCount = configuration.GetValue(MessageCountConfigKey, 5000);
            bool sendForever = messageCount < 0;

            string messagesToSendString = sendForever ? "unlimited" : messageCount.ToString();

            TransportType transportType = configuration.GetValue("ClientTransportType", TransportType.Amqp_Tcp_Only);
            Console.WriteLine($"Using transport {transportType.ToString()}");

            var retryPolicy = new RetryPolicy(TimeoutErrorDetectionStrategy, TransientRetryStrategy);
            retryPolicy.Retrying += (_, args) =>
            {
                Console.WriteLine($"Creating ModuleClient failed with exception {args.LastException}");
                if (args.CurrentRetryCount < RetryCount)
                {
                    Console.WriteLine("Retrying...");
                }
            };
            ModuleClient moduleClient = await retryPolicy.ExecuteAsync(() => InitModuleClient(transportType));

            ModuleClient userContext = moduleClient;
            await moduleClient.SetInputMessageHandlerAsync("control", ControlMessageHandle, userContext);

            (CancellationTokenSource cts, ManualResetEventSlim completed, Option<object> handler)
                = ShutdownHandler.Init(TimeSpan.FromSeconds(5), null);
            await SendEvents(moduleClient, messageDelay, sendForever, messageCount, cts);
            //await cts.Token.WhenCanceled();
            completed.Set();
            handler.ForEach(h => GC.KeepAlive(h));
            return 0;
        }

        static async Task<ModuleClient> InitModuleClient(TransportType transportType)
        {
            ITransportSettings[] GetTransportSettings()
            {
                switch (transportType)
                {
                    case TransportType.Mqtt:
                    case TransportType.Mqtt_Tcp_Only:
                    case TransportType.Mqtt_WebSocket_Only:
                        return new ITransportSettings[] { new MqttTransportSettings(transportType) };
                    default:
                        return new ITransportSettings[] { new AmqpTransportSettings(transportType) };
                }
            }

            ITransportSettings[] settings = GetTransportSettings();

            ModuleClient moduleClient = await ModuleClient.CreateFromEnvironmentAsync(settings);
            await moduleClient.OpenAsync().ConfigureAwait(false);
            await moduleClient.SetMethodHandlerAsync("reset", ResetMethod, null);

            Console.WriteLine("Successfully initialized module client.");
            return moduleClient;
        }

        // Control Message expected to be:
        // {
        //     "command" : "reset"
        // }
        static Task<MessageResponse> ControlMessageHandle(Message message, object userContext)
        {
            byte[] messageBytes = message.GetBytes();
            string messageString = Encoding.UTF8.GetString(messageBytes);

            Console.WriteLine($"Received message Body: [{messageString}]");

            try
            {
                var messages = JsonConvert.DeserializeObject<ControlCommand[]>(messageString);

                foreach (ControlCommand messageBody in messages)
                {
                    if (messageBody.Command == ControlCommandEnum.Reset)
                    {
                        Console.WriteLine("Resetting temperature sensor..");
                        Reset.Set(true);
                    }
                    else
                    {
                        // NoOp
                    }
                }
            }
            catch (JsonSerializationException)
            {
                var messageBody = JsonConvert.DeserializeObject<ControlCommand>(messageString);

                if (messageBody.Command == ControlCommandEnum.Reset)
                {
                    Console.WriteLine("Resetting temperature sensor..");
                    Reset.Set(true);
                }
                else
                {
                    // NoOp
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to deserialize control command with exception: [{ex.Message}]");
            }

            return Task.FromResult(MessageResponse.Completed);
        }

        static Task<MethodResponse> ResetMethod(MethodRequest methodRequest, object userContext)
        {
            Reset.Set(true);
            var response = new MethodResponse((int)HttpStatusCode.OK);
            return Task.FromResult(response);
        }

        static async Task SendEvents(
            ModuleClient moduleClient,
            TimeSpan messageDelay,
            bool sendForever,
            int messageCount,
            //SimulatorParameters sim,
            CancellationTokenSource cts)
        {
            int count = 1;
            while (!cts.Token.IsCancellationRequested && (sendForever || messageCount >= count))
            {
                string dataBuffer = TelemetryData.Telemetry.TelemetryData(1);
                string dataBuffer2 = TelemetryData.Telemetry.TelemetryData(2);
                string dataBuffer3 = TelemetryData.Telemetry.TelemetryData(3);
                string dataBuffer4 = TelemetryData.Telemetry.TelemetryData(4);
                string dataBuffer5 = TelemetryData.Telemetry.TelemetryData(5);

                var eventMessage = new Message(Encoding.UTF8.GetBytes(dataBuffer));
                var eventMessage2 = new Message(Encoding.UTF8.GetBytes(dataBuffer2));
                var eventMessage3 = new Message(Encoding.UTF8.GetBytes(dataBuffer3));
                var eventMessage4 = new Message(Encoding.UTF8.GetBytes(dataBuffer4));
                var eventMessage5 = new Message(Encoding.UTF8.GetBytes(dataBuffer5));

                await moduleClient.SendEventAsync("Machine1", eventMessage);
                Console.WriteLine($"\t{DateTime.Now.ToLocalTime()}> Sending message: {count}, Body: [{dataBuffer}]");

                await moduleClient.SendEventAsync("Machine2", eventMessage2);
                Console.WriteLine($"\t{DateTime.Now.ToLocalTime()}> Sending message: {count}, Body: [{dataBuffer2}]");

                await moduleClient.SendEventAsync("Machine3", eventMessage3);
                Console.WriteLine($"\t{DateTime.Now.ToLocalTime()}> Sending message: {count}, Body: [{dataBuffer3}]");

                await moduleClient.SendEventAsync("Machine4", eventMessage4);
                Console.WriteLine($"\t{DateTime.Now.ToLocalTime()}> Sending message: {count}, Body: [{dataBuffer4}]");

                await moduleClient.SendEventAsync("Machine5", eventMessage5);
                Console.WriteLine($"\t{DateTime.Now.ToLocalTime()}> Sending message: {count}, Body: [{dataBuffer5}]");

                await Task.Delay(messageDelay, cts.Token);

                count++;
            }

            if (messageCount < count)
            {
                Console.WriteLine($"Done sending {messageCount} messages");
            }
        }

        static void CancelProgram(CancellationTokenSource cts)
        {
            Console.WriteLine("Termination requested, closing.");
            cts.Cancel();
        }

        internal class ControlCommand
        {
            [JsonProperty("command")]
            public ControlCommandEnum Command { get; set; }
        }

    }
}
