using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace DataMovementSample
{
    class Program
    {
        static void Main(string[] args)
        {
            //Set the default values

            string SQLConnectionString = "Server = <server_name>; Database = <database_name> UID = <user_name>; Pwd = <password>"; // Connection string for the SQL Edge Instance. 
            string SourceTableName = "<table_name>"; //Source Table Name
            string EventHubConnectionString = ""; // Connection String to the Event Hub
            string EventHubName = ""; // Name of the Event hub
            int ReadWriteFrequency = 1; /// Read/Write interval in minutes. 

            // Read Environment Variables.

            if (Environment.GetEnvironmentVariable("SQLConnectionString") != null)
                SQLConnectionString = Environment.GetEnvironmentVariable("KAFKA_HOST").Trim('"');

            if (Environment.GetEnvironmentVariable("SourceTableName") != null)
                SourceTableName = Environment.GetEnvironmentVariable("SourceTableName").Trim('"');

            if (Environment.GetEnvironmentVariable("EventHubConnectionString") != null)
                EventHubConnectionString = Environment.GetEnvironmentVariable("EventHubConnectionString");

            if (Environment.GetEnvironmentVariable("EventHubName") != null)
                EventHubName = Environment.GetEnvironmentVariable("EventHubName");

            if (Environment.GetEnvironmentVariable("ReadWriteFrequencyInMiutes") != null)
                ReadWriteFrequency = Convert.ToInt32(Environment.GetEnvironmentVariable("ReadWriteFrequencyInMiutes"));


            //Initializing the SQLLite Database. If it exists, reload it. 
            SQLiteDatabaseOperations.CreateDatabaseAndTable();

            var tasks = new List<Task>(3);

            ///Get the Changed data from SQL Edge
            ///
            //await Miscellaneouss.ReadDataSQLEdge(appsettings.SQLEdgeConnectionString, appsettings.TableName, Convert.ToInt32(appsettings.ReadWriteFrequencyInMs));
            tasks.Add(Task.Factory.StartNew(() => Miscellaneouss.ReadDataSQLEdge(SQLConnectionString, SourceTableName, Convert.ToInt32(ReadWriteFrequency))));

            ///Send the data to Event Hub
            ///
            tasks.Add(Task.Factory.StartNew(() => Miscellaneouss.WriteEventHub(EventHubConnectionString, EventHubName, Convert.ToInt32(ReadWriteFrequency))));
            //await Miscellaneouss.WriteEventHub(appsettings.TargetConnectionString, appsettings.EventHubName, Convert.ToInt32(appsettings.ReadWriteFrequencyInMs));

            /// Load the File Deletion Thread
            /// 
            tasks.Add(Task.Factory.StartNew(() => Miscellaneouss.DeleteOldUploadedFiles()));

            Task.WaitAll(tasks.ToArray());

        }
    }

}
