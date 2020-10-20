using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace RobotTelemetryKafka
{
    class Program
    {
        public static void Main()
        {
            int threadcount = 5;
            int messageInterval = 1000;
            int messageperthread = 100;
            int partitions_per_topic = 10;
            string kafkaTopic1Name = "RobotTelemetry";
            string kafkaTopic2Name = "AmbientTelemetry";
            string kafkaHostString = "";

            
            if (Environment.GetEnvironmentVariable("KAFKA_HOST") != null)
                kafkaHostString = Environment.GetEnvironmentVariable("KAFKA_HOST").Trim('"');
            Console.WriteLine($"Using Kafka Host - {kafkaHostString}");

            if (Environment.GetEnvironmentVariable("KAFKA_TOPIC1") != null)
                kafkaTopic1Name = Environment.GetEnvironmentVariable("KAFKA_TOPIC1").Trim('"');
            Console.WriteLine($"Using Kafka Host - {kafkaTopic1Name}");

            if (Environment.GetEnvironmentVariable("KAFKA_TOPIC2") != null)
                kafkaTopic2Name = Environment.GetEnvironmentVariable("KAFKA_TOPIC2").Trim('"');
            Console.WriteLine($"Using Kafka Host - {kafkaTopic2Name}");

            if (Environment.GetEnvironmentVariable("THREAD_COUNT") != null)
                threadcount = Convert.ToInt32(Environment.GetEnvironmentVariable("THREAD_COUNT"));
            
            if (Environment.GetEnvironmentVariable("MESSAGE_INTERVAL") != null)
                messageInterval = Convert.ToInt32(Environment.GetEnvironmentVariable("MESSAGE_INTERVAL"));

            if (Environment.GetEnvironmentVariable("MESSAGE_PER_THREAD") != null)
                messageperthread = Convert.ToInt32(Environment.GetEnvironmentVariable("MESSAGE_PER_THREAD"));
            
            if (Environment.GetEnvironmentVariable("PARTITIONS_PER_TOPIC") != null)
                partitions_per_topic = Convert.ToInt32(Environment.GetEnvironmentVariable("PARTITIONS_PER_TOPIC"));

            DataGenerator datagen = new DataGenerator(messageInterval, messageperthread, partitions_per_topic, 
                    kafkaTopic1Name, kafkaTopic2Name, kafkaHostString);

            // Before Starting the Data send workflow, if the topics are present delete them. 

            datagen.CreateTopic(kafkaTopic1Name);
            datagen.CreateTopic(kafkaTopic2Name);

            Thread.Sleep(5000);

            var tasks = new List<Task>();
                for (int i = 0; i<threadcount; i++)
                {
                    tasks.Add(Task.Factory.StartNew(() => datagen.ProducerSend()));
                }

            Task.WaitAll(tasks.ToArray());
                Console.WriteLine("Completed All thread Execution");
        }
    }
}
