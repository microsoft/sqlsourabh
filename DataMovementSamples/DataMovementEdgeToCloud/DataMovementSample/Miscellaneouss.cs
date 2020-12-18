using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Net.NetworkInformation;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace DataMovementSample
{
    public class Miscellaneouss
    {
        /// The miscellaneouss class to implement the following routine. 
        /// Checking Network connectivity
        /// Ensuring all synchornization conditions are valid.     
        ///

        public static bool CheckNetworkConnectivity()
        {
            PingReply reply;
            bool isConnected = false;
            string host = "www.bing.com";
            Ping p = new Ping();
            try
            {
                reply = p.Send(host, 3000);
                if (reply.Status == IPStatus.Success)
                    isConnected = true;

                // Write the PingReply Stats
                //Console.WriteLine($"Ping Reply Address : {reply.Address}");
                Console.WriteLine($"Ping Reply RoundTrip Time : {reply.RoundtripTime}");
            }
            catch
            {

            }
            return isConnected;
        }

        //Read Data from SQL and Generate an JSON for the Rows. 
        // For the purpose of this demo, we are using Change Tracking feature in SQL 
        // The function reads the net changes from the underlying table.
        public static Task ReadDataSQLEdge(string connectionString, string tablename, int ReadInterval)
        {
            // Check if the connection string is a valid connection string or not.           
            DataSet ds = new DataSet();
            string json;
           
            while (true)
            {
                if (connectionString != "" || tablename != "")
                {
                    long min_version = GetMinValidCTVersionsFromSQL(connectionString, tablename);
                    if (min_version != -1)
                    {
                        long last_sync_version = SQLiteDatabaseOperations.SelectLastSyncVersion();
                        try
                        {
                            try
                            {
                                try
                                {
                                    using (SqlConnection connection = new SqlConnection(connectionString))
                                    {
                                        /// Check the table is present in the database or not
                                        /// If present, check if Change tracking is enabled on the Table or not. 
                                        /// 

                                        string query = "Select count(*) as TableCount from sys.change_tracking_tables where object_id = object_id(N'" + tablename + "')";

                                        SqlCommand sql_cmnd1 = new SqlCommand(query, connection);
                                        connection.Open();
                                        int result = (Int32)sql_cmnd1.ExecuteScalar();
                                        connection.Close();
                                        if (result == 1)
                                        {
                                            Console.WriteLine($"The specified Table [{tablename}] is enabled for change tracking.");
                                            
                                            //Read Data from SQL Edge using the Predefined Stored Procedure. 
                                            /// This example used a SP, to minimize the usage of T-SQL constructs in the code.
                                            ///  

                                            SqlCommand sql_cmnd = new SqlCommand("GetChangesFromTable", connection);
                                            sql_cmnd.CommandType = CommandType.StoredProcedure;
                                            sql_cmnd.Parameters.AddWithValue("@TableName", SqlDbType.VarChar).Value = tablename;
                                            sql_cmnd.Parameters.AddWithValue("@last_sync_version", SqlDbType.BigInt).Value = last_sync_version;

                                            connection.Open();
                                            SqlDataAdapter da = new SqlDataAdapter(sql_cmnd);
                                            da.Fill(ds);
                                            da.Dispose();

                                            /// Convert this Database to a Json Object.
                                            /// This JSON will be used to sync data to the targets
                                            /// 
                                            connection.Close();
                                        }
                                        else
                                            Console.WriteLine("The specified table is not enabled for Changed Tracking");
                                    }
                                }
                                catch (SqlException e)
                                {
                                    Console.WriteLine(e.Message);
                                }
                                catch (System.ArgumentException ae)
                                {
                                    Console.WriteLine($"Error Establishing connection to SQL to read the data. Reason: {ae.Message}");
                                }

                                long currnet_version = (Int64)ds.Tables[0].Rows[0]["Current_Sync_Version"];
                                //Console.WriteLine($"Current Version from Database -> {currnet_version}");

                                // get the Current Sync Version from the record set.
                                //System.Text.Json.JsonSerializer serializer = new JsonSerializer();    
                                List<Dictionary<string, object>> rows = new List<Dictionary<string, object>>();
                                Dictionary<string, object> row;
                                foreach (DataRow dr in ds.Tables[1].Rows)
                                {
                                    row = new Dictionary<string, object>();
                                    foreach (DataColumn col in ds.Tables[1].Columns)
                                    {
                                        row.Add(col.ColumnName, dr[col]);
                                    }
                                    rows.Add(row);
                                }
                                ds.Clear();
                                ds.Dispose();
                                json = "";
                                json = System.Text.Json.JsonSerializer.Serialize(rows);

                                ///create the json file for interim storage 
                                ///
                                string filename = "ChangeTrackingData_" + Convert.ToString(last_sync_version)
                                        + "_" + DateTime.UtcNow.ToString(new CultureInfo("en-us")).Replace("/", " ").Replace(":", " ").Replace(" ", "_") + ".json";
                                File.WriteAllText(filename, json);

                                ///Write the last synchronization details to the datastore.json file.
                                ///
                                //WriteLastSyncVersion(currnet_version, filename, "Created");
                                SQLiteDatabaseOperations.InsertRecords(currnet_version, filename);

                            }
                            catch (Exception e)
                            {
                                Console.WriteLine(e.Message);

                            }
                        }
                        catch (Exception e)
                        {
                            Console.WriteLine(e.Message);
                        }
                    }
                    else
                    {
                        Console.WriteLine("There was either an error reading the MIN VALID LSN or the value returned was NULL");
                        
                    }
                }
                else
                {
                    Console.WriteLine("The Connection String to SQL Edge or the Source Table name is incorrect");
                }
                Thread.Sleep(new TimeSpan(0, ReadInterval, 0));                
            }

        }

        public static async Task WriteEventHub(string eventhubconn, string eventhubname, int WriteInterval)
        {
            
            //using EventDataBatch eventBatch = await producerClient.CreateBatchAsync();
            while (true)
            {
                if (eventhubconn == "")
                {
                    Console.WriteLine("Exception - Event Hub Connection string is not Valid. ");
                    break;
                }
                // this function will read the datastore.json file to first file (status = Created) which has not yet been Sent to the EventHub. 
                // We will first read the json file and then convert it into a byte stream
                // which will then be used to send the events to the event hub.
                string filename = "";

                filename = SQLiteDatabaseOperations.SelectNextUploadedFile();
                if (filename != "" && File.Exists(filename))
                {
                    bool isConnected = CheckNetworkConnectivity();
                    if (isConnected)
                    {

                        Console.WriteLine("Network Connectivity Exists!! Proceeding with Data Sync");
                        await using (var producerClient = new EventHubProducerClient(eventhubconn, eventhubname))
                        {

                            using EventDataBatch eventBatch = await producerClient.CreateBatchAsync();

                            // Add events to the batch. An event is a represented by a collection of bytes and metadata. 
                            try
                            {
                                string json = (new StreamReader(new FileStream(filename, FileMode.Open))).ReadToEnd();

                                if (json.Length >= 1048576)
                                {
                                    //The json file is too big to send to event hub. The Limit on Standard Event Hub is 1 MB
                                    // breakdown the JSON File and construct smaller json files. 

                                    List<object> items = JsonSerializer.Deserialize<List<object>>(json);
                                    Console.WriteLine($"List contains {items.Count} elements");
                                    int copyrange = 0;

                                    for (int j = 0; j < items.Count; j += 2500)
                                    {
                                        string json2 = "";
                                        if (items.Count - j > 2500)
                                            copyrange = 2500;
                                        else
                                            copyrange = items.Count - j - 1;
                                        object[] array = new object[copyrange];
                                        Console.WriteLine($"Array Length {array.Length}, Value of J - {j}");
                                        items.CopyTo(j, array, 0, copyrange);
                                        //Console.WriteLine($"List contains {array.Length} elements");
                                        json2 = JsonSerializer.Serialize(array);
                                        //Console.WriteLine($"Length of the new json file is -> {json2.Length}");
                                        EventData d2 = new EventData(Encoding.UTF8.GetBytes(json2));
                                        eventBatch.TryAdd(d2);
                                        try
                                        {
                                            await producerClient.SendAsync(eventBatch);
                                            Console.WriteLine("Sent 1 JSON file with multiple records to the Event Hub");
                                        }
                                        catch (Exception e)
                                        {
                                            Console.WriteLine(e.Message);
                                            continue;
                                        }
                                    }
                                    SQLiteDatabaseOperations.UpdateRecords(filename);
                                    // Also rename the file on the disk 
                                    try
                                    {
                                        //File.Move(filename, filename + "_processed");
                                    }
                                    catch
                                    {
                                        Console.WriteLine($"File {filename} cannot be renamed.");
                                    }

                                }
                                else
                                {
                                    EventData d = new EventData(Encoding.UTF8.GetBytes(json));
                                    eventBatch.TryAdd(d);
                                    try
                                    {
                                        await producerClient.SendAsync(eventBatch);
                                        SQLiteDatabaseOperations.UpdateRecords(filename);
                                        Console.WriteLine("Sent 1 JSON file with multiple records to the Event Hub");
                                        try
                                        {
                                            //File.Move(filename, filename + "_processed");
                                        }
                                        catch
                                        {
                                            Console.WriteLine($"File {filename} cannot be renamed.");
                                        }
                                    }
                                    catch (Exception e)
                                    {
                                        Console.WriteLine(e.Message);
                                        continue;
                                    }
                                }
                            }
                            catch (Exception e)
                            {
                                Console.WriteLine(e.Message);
                            }


                        }
                    }
                }

                Thread.Sleep(new TimeSpan(0, WriteInterval, 0));
            }
        }

        public static long GetMinValidCTVersionsFromSQL(string connectionString, string TableName)
        {
            /// This function will be used to return the Min Valid Version and the Current version from SQL.
            long min_version = -1;
            try
            {
                //Console.WriteLine($"The Source Connection '{connectionString}' is valid");
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    string query = "Select CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID(N'" + TableName + "')) as min_version";
                    //Console.WriteLine($"SQL Query -> {query}");
                    connection.Open();
                    SqlCommand sql_cmd = new SqlCommand(query, connection);

                    //min_version = (Int64)sql_cmd.ExecuteScalar();

                    object tempval = sql_cmd.ExecuteScalar();
                    if (tempval.GetType() != typeof(DBNull))
                    {
                        min_version = (Int64)tempval;
                    }
                    return min_version;
                }
            }
            catch (System.InvalidOperationException oe)
            {
                Console.WriteLine($"Error Establishing connection to SQL to read Min Valid LSN. Reason: {oe.Message}");
                return -1;
            }
            catch (SqlException e)
            {
                Console.WriteLine($"Error Establishing connection to SQL to read Min Valid LSN. Reason: {e.Message}");
                return -1;
            }
            catch (System.ArgumentException ae)
            {
                Console.WriteLine($"Error Establishing connection to SQL to read Min Valid LSN. Reason: {ae.Message}");
                return -1;
            }
        }

        public static void DeleteOldUploadedFiles()
        {
            //Get the list of files to delete from the SQLite Database.
            while (true)
            {
                string[] filelist = SQLiteDatabaseOperations.GetFilesToDelete();
                foreach (string filename in filelist)
                {
                    if (File.Exists(filename))
                    {
                        try
                        {
                            File.Delete(filename);
                            SQLiteDatabaseOperations.DeleteEntryFromDatabase(filename);
                        }
                        catch (Exception e)
                        {
                            Console.WriteLine(e.Message);
                        }
                    }
                }
                Thread.Sleep(new TimeSpan(2, 0, 0));
            }

        }

    }

}
