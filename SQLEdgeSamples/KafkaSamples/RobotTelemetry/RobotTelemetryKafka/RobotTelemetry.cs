using System;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Confluent.Kafka;
using Confluent.Kafka.Admin;
using System.Collections.Generic;

namespace RobotTelemetryKafka
{
    class DataGenerator
    {
        private int MessageInterval;
        private int MessageCountPerThread;
        private string topicName1;
        private string topicName2;
        private string KafkaServerString;
        private int partitions_per_topic;
        public DataGenerator(int interval, int messagecountperthread, int partitions, string topic1, string topic2, string server)
        {
            /// Set default values for the Member variables 
            MessageInterval = interval;
            MessageCountPerThread = messagecountperthread;
            topicName1 = topic1;
            topicName2 = topic2;
            KafkaServerString = server;
            partitions_per_topic = partitions;
        }
        public string ProducerSend()
        {
            Console.WriteLine("Executing on Thread {0}", Thread.CurrentThread.ManagedThreadId);
            //string topicName = "IronOrePredictionData";

            var config = new ProducerConfig
            {
                BootstrapServers = this.KafkaServerString,
                CompressionType = CompressionType.Gzip,
                MessageTimeoutMs = 1000,
                Partitioner = Partitioner.ConsistentRandom,
                RetryBackoffMs = 500
            };
            var p = new ProducerBuilder<Null, string>(config).Build();
            int count = 1;

            /// Send Messages
            while (count <= this.MessageCountPerThread)
            {
                var message1 = new Message<Null, string> { Value = RebotTelemetrySimulation(Thread.CurrentThread.ManagedThreadId) };
                p.Produce(topicName1, message1);
                Console.WriteLine($"\n Produced message #'{count}' to topic {topicName1} on thread '{Thread.CurrentThread.ManagedThreadId}' with value {message1.Value.ToString()}");

                var message2= new Message<Null, string> { Value = GenerateAmbientSensorData() };
                p.Produce(topicName2, message2);
                Console.WriteLine($"\n Produced message #'{count}' to topic {topicName2} on thread '{Thread.CurrentThread.ManagedThreadId}' with value {message2.Value.ToString()}");

                Thread.Sleep(this.MessageInterval);
                count++;
            }
            return "\n Execution Completed on Thread :-" + Thread.CurrentThread.ManagedThreadId.ToString();
        }
        public async void CreateTopic(string topicName)
        {
            var adminClient = new AdminClientBuilder(new AdminClientConfig { BootstrapServers = this.KafkaServerString }).Build();
            TimeSpan ts = new TimeSpan(99999999999);
            Metadata metadata = adminClient.GetMetadata(topicName, ts);

            if(metadata.Topics[0].Error.IsBrokerError && metadata.Topics[0].Error.IsError)
            {
                Console.Write("\n Creating topic {0} as it does not exist", topicName);
                try
                {
                    var createTask = new List<Task>();
                    createTask.Add(Task.Factory.StartNew(() => adminClient.CreateTopicsAsync(
                           new TopicSpecification[] {
                               new TopicSpecification {
                                    Name = topicName,
                                    ReplicationFactor = 1,
                                    NumPartitions = this.partitions_per_topic } })
                    ));
                    DateTime dt = DateTime.Now;
                    await Task.WhenAll(createTask);
                    DateTime de = DateTime.Now;
                    Console.WriteLine($"\n Create Topic Operation Took {0} Milliseconds", de.Subtract(dt).TotalMilliseconds);

                    Console.Write($"\n Created Topic {topicName} with '{this.partitions_per_topic}' partitions!");
                    Thread.Sleep(12000);
                }
                catch (CreateTopicsException e)
                {
                    Console.WriteLine($"\n An error occured creating topic {e.Results[0].Topic}: {e.Results[0].Error.Reason}");
                }
            }
            else if (!metadata.Topics[0].Error.IsBrokerError && !metadata.Topics[0].Error.IsError
                && metadata.Topics[0].Partitions.Count != this.partitions_per_topic)
            {
                Console.Write($"\n Topic {topicName} already present, but does not have '{this.partitions_per_topic}' partitions, Recreating it!!");
                //string[] topics = new string[1] { topicName };
                try
                {
                    //await adminClient.DeleteTopicsAsync(topics, null);
                    var deleteTask = new List<Task>();
                    deleteTask.Add(Task.Factory.StartNew(() => DeleteTopic(adminClient, topicName)));

                    await Task.WhenAll(deleteTask);

                    var createTask = new List<Task>();
                    createTask.Add(Task.Factory.StartNew(() => adminClient.CreateTopicsAsync(
                           new TopicSpecification[] {
                               new TopicSpecification {
                                    Name = topicName, ReplicationFactor = 1,NumPartitions = this.partitions_per_topic } })));
                    await Task.WhenAll(createTask);
                    Console.Write($"\n Recrated Topic {topicName} with '{this.partitions_per_topic}' partitions!");
                    Thread.Sleep(12000);
                }
                catch (DeleteTopicsException e)
                {
                    Console.WriteLine($"\n An error occured creating topic {e.Results[0].Topic}: {e.Results[0].Error.Reason}");
                }
                catch (CreateTopicsException e)
                {
                    Console.WriteLine($"\n An error occured creating topic {e.Results[0].Topic}: {e.Results[0].Error.Reason}");
                }
            }
        }
        public async void DeleteTopic(IAdminClient admin, string topicName)
        {
            string[] topics = new string[1] { topicName };
            await admin.DeleteTopicsAsync(topics, null);
        }
        public static string RebotTelemetrySimulation(int RobotID)
        {
            // Robot Sensor Data includes the following 
            Random random = new Random();
            int currRobotID = RobotID;
            DateTime currtimestamp = DateTime.Now;
            double currCapacitiveDisplacementSensor = 10 + random.NextDouble() * 10;
            double currEngineTemperatureData = 90 + random.NextDouble() * 30;
            double currEngineFanSpeed = random.NextDouble() * 100;
            double currTorqueSensorData = 10 + random.NextDouble() * 10;
            double currGripRobustness = 80 + random.NextDouble() * 20;
           

            var RobotTelemetry = new
            {
                RobotID = currRobotID,
                timestamp = currtimestamp,
                CapacitiveDisplacementSensor = currCapacitiveDisplacementSensor,
                EngineTemperatureData = currEngineTemperatureData,
                EngineFanSpeed = currEngineFanSpeed,
                TorqueSensorData = currTorqueSensorData,
                GripRobustness = currGripRobustness
            };
            var messageString = JsonConvert.SerializeObject(RobotTelemetry);
            return messageString;
        }
        public static string GenerateAmbientSensorData()
        {
            // Robot Sensor Data includes the following 
            Random random = new Random();
            DateTime currtimestamp = DateTime.Now;
            double currTemp = random.Next(60, 85);
            double currHumidity = random.Next(30, 45);

            var RobotTelemetry = new
            {
                timestamp = currtimestamp,
                outsideTemperature = currTemp,
                Humidity = currHumidity
            };

            var messageString = JsonConvert.SerializeObject(RobotTelemetry);
            return messageString;
        }
    }
}
