using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace BidirectionalSync
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello World!");

            SQLiteDatabaseOperations.CreateDatabaseAndTable();

            //// Sample Connection Strings
            //string sqlEdgeConnString = "Server = xxx.xxx.xxx.xxx,1433; Database = DataMovementTest; UID = sa; Pwd = MyStrongSQLP@a$$worD"; ;
            //string sqlDBConnString = "Server = mysqlserver.database.windows.net; Database = Doctestdb; UID = azuresqlAdmin; Pwd = MyStrongSQLP@a$$worD";

            string sqlEdgeConnString = ""; ;
            string sqlDBConnString = "";
	    int ReadWriteFrequency = 1; /// Read/Write interval in minutes. 


            /// Thread Allocations 
            /// In the below code example, each source, target sync has been implemented as a separate thread. 
            /// If more source/target Pairs needs to be synchronized, then add a thread each of the sync pair. 
            /// 

            var tasks = new List<Task>(2);

            /// Task1 - Cloud to Edge Sync for Cloud Source Table 1 and Target Edge Table 1
            /// SYNTAX -> cloud_to_edge(string sqldbConn, string cloudSourceTable, string edgeconn, string EdgeDestTable, int FrequencyInMinutes)
            tasks.Add(Task.Factory.StartNew(() => SQLOperations.cloud_to_edge(sqlDBConnString, "TelemetryData", sqlEdgeConnString, "TelemetryDataTarget", ReadWriteFrequency )));

            // Task2 - Edge to Cloud Sync for Edge Source Table 2 and Target Cloud Table 2
            /// SYNTAX -> edge_to_cloud(string edgeconn, string edgeSourceTab, string sqldbConn, string cloudDestTable, int FrequencyInMinutes)
            tasks.Add(Task.Factory.StartNew(() => SQLOperations.edge_to_cloud(sqlEdgeConnString, "TelemetryData", sqlDBConnString, "TelemetryDataTarget", ReadWriteFrequency )));

            Task.WaitAll(tasks.ToArray());

    }
    }
}
