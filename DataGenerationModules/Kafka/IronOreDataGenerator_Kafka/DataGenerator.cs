using System;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Confluent.Kafka;
using Confluent.Kafka.Admin;
using System.Collections.Generic;

namespace IronOreDataGenerator_Kafka
{
    class DataGenerator
    {
        private int MessageInterval;
        private int MessageCountPerThread;
        private string topicName;
        private string KafkaServerString;
        private int partitions_per_topic;
        public DataGenerator(int interval, int messagecountperthread, int partitions, string topic, string server)
        {
            /// Set default values for the Member variables 
            MessageInterval = interval;
            MessageCountPerThread = messagecountperthread;
            topicName = topic;
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
                var message = new Message<Null, string> { Value = GenerateSimulatedIronOreData() };
                //var dr = await p.ProduceAsync(topicName, message);
                p.Produce(topicName, message);
                Console.WriteLine($"\n Produced message #'{count}' to topic {topicName} on thread '{Thread.CurrentThread.ManagedThreadId}' with value {message.Value.ToString()}");
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

            if (metadata.Topics[0].Error.IsBrokerError && metadata.Topics[0].Error.IsError)
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
        public static string GenerateSimulatedIronOreData()
        {
            Random random = new Random();
            DateTime currtimestamp = DateTime.Now;
            double Iron_Feed = random.NextDouble() * (5.853373 - 5.083406) + 5.083406;
            double Silica_Feed = random.NextDouble() * (4.667576 - 0.892093) + 0.892093;
            double Starch_Flow = random.NextDouble() * (18.097433 - 0.002024) + 0.002024;
            double Amina_Flow = random.NextDouble() * (11.294761 - 8.526940) + 8.526940;
            double Ore_Pulp_pH = random.NextDouble() * (2.987966 - 2.715038) + 2.715038;
            //double Ore_Pulp_Density = random.NextDouble() * (1.135401 - 0.991312) + 0.991312;
            double Flotation_Column_01_Air_Flow = random.NextDouble() * (9.551099 - 7.818521) + 7.818521;
            double Flotation_Column_02_Air_Flow = random.NextDouble() * (9.564830 - 7.814160) + 7.814160;
            double Flotation_Column_03_Air_Flow = random.NextDouble() * (9.488610 - 7.830299) + 7.830299;
            double Flotation_Column_07_Air_Flow = random.NextDouble() * (9.536278 - 7.944058) + 7.944058;
            double Flotation_Column_04_Level = random.NextDouble() * (11.071762 - 7.649184) + 7.649184;
            double Flotation_Column_05_Level = random.NextDouble() * (11.053295 - 7.711438) + 7.711438;
            double Flotation_Column_06_Level = random.NextDouble() * (11.143194 - 7.564080) + 7.564080;
            double Flotation_Column_07_Level = random.NextDouble() * (10.990837 - 7.816539) + 7.816539;
            double Iron_Concentrate = random.NextDouble() * (5.915214 - 5.745897) + 5.745897;

            var IronOreDataSet = new
            {

                timestamp = currtimestamp,
                cur_Iron_Feed = Iron_Feed,
                cur_Silica_Feed = Silica_Feed,
                cur_Starch_Flow = Starch_Flow,
                cur_Amina_Flow = Amina_Flow,
                cur_Ore_Pulp_pH = Ore_Pulp_pH,
                cur_Flotation_Column_01_Air_Flow = Flotation_Column_01_Air_Flow,
                cur_Flotation_Column_02_Air_Flow = Flotation_Column_02_Air_Flow,
                cur_Flotation_Column_03_Air_Flow = Flotation_Column_03_Air_Flow,
                cur_Flotation_Column_07_Air_Flow = Flotation_Column_07_Air_Flow,
                cur_Flotation_Column_04_Level = Flotation_Column_04_Level,
                cur_Flotation_Column_05_Level = Flotation_Column_05_Level,
                cur_Flotation_Column_06_Level = Flotation_Column_06_Level,
                cur_Flotation_Column_07_Level = Flotation_Column_07_Level,
                cur_Iron_Concentrate = Iron_Concentrate
            };

            var messageString = JsonConvert.SerializeObject(IronOreDataSet);
            return messageString;
        }
    }
}
