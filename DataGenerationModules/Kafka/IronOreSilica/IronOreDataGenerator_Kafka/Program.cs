using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;


namespace IronOreDataGenerator_Kafka
{
    class Program
    {
        
        public static void Main()
        {
            int threadcount = 5;
            int messageInterval = 1000;
            int messageperthread = 100;
            int partitions_per_topic = 10;
            string kafkaTopicName = "IronOrePredictionData";
            string kafkaHostString = "40.83.17.22:9092";
            
            if (Environment.GetEnvironmentVariable("KAFKA_HOST") != null)
                kafkaHostString = Environment.GetEnvironmentVariable("KAFKA_HOST").Trim('"');

            Console.WriteLine($"Using Kafka Host - {kafkaHostString}");

            if (Environment.GetEnvironmentVariable("KAFKA_TOPIC") != null)
                kafkaTopicName = Environment.GetEnvironmentVariable("KAFKA_TOPIC").Trim('"');

            Console.WriteLine($"Using Kafka Topic - {kafkaTopicName}");

            if (Environment.GetEnvironmentVariable("THREAD_COUNT") != null)
                threadcount = Convert.ToInt32(Environment.GetEnvironmentVariable("THREAD_COUNT"));
            
            if (Environment.GetEnvironmentVariable("MESSAGE_INTERVAL") != null)
                messageInterval = Convert.ToInt32(Environment.GetEnvironmentVariable("MESSAGE_INTERVAL"));

            if (Environment.GetEnvironmentVariable("MESSAGE_PER_THREAD") != null)
                messageperthread = Convert.ToInt32(Environment.GetEnvironmentVariable("MESSAGE_PER_THREAD"));

            if (Environment.GetEnvironmentVariable("PARTITIONS_PER_TOPIC") != null)
                partitions_per_topic = Convert.ToInt32(Environment.GetEnvironmentVariable("PARTITIONS_PER_TOPIC"));

            DataGenerator datagen = new DataGenerator(messageInterval, messageperthread, partitions_per_topic, kafkaTopicName, kafkaHostString);

            datagen.CreateTopic(kafkaTopicName);

            Thread.Sleep(5000);

            var tasks = new List<Task>();
            for (int i = 0; i < threadcount; i++)
            {
                tasks.Add(Task.Factory.StartNew(() => datagen.ProducerSend()));
            }

            Task.WaitAll(tasks.ToArray());
            Console.WriteLine("Completed All thread Execution");
        }
    }
}
