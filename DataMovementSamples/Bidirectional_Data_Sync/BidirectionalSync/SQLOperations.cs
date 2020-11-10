using System;
using System.Collections.Generic;
using System.Text;
using System.Data.SqlClient;
using System.Data;
using System.Data.Common;
using System.Threading;
using System.Globalization;
using System.IO;

namespace BidirectionalSync
{
    class SQLOperations
    {

        public static DataSet read_from_edge(string edgeconn, string edgeSourceTab)
        {
            /// function to read changes (updated records) from the source table on SQL Edge. 
            /// The function uses a stored procedure to read the data from a SQL Database. The logic in the Stored Procedure can be user conrolled. 
            /// For the purposes of the sample, the Stored procedure will consume the delta changes using the Change Tracking feature in SQL. 
            /// 

            DataSet ds = new DataSet();

            if (edgeconn != "" || edgeSourceTab != "")
            {
                //check if the table has change tracking enabled and then get the min_valid_version for the table. 
                long min_version = GetMinValidCTVersionsFromSQL(edgeconn, edgeSourceTab);
                if (min_version != -1)
                {
                    ///Read the last Sync Value For the Source Table.
                    ///
                    long last_sync_version = SQLiteDatabaseOperations.SelectLastSyncVersion("AzureSQLEdge", edgeSourceTab);
                    try
                    {
                        try
                        {
                            try
                            {
                                using (SqlConnection connection = new SqlConnection(edgeconn))
                                {

                                    //Read Data from SQL Edge using the Predefined Stored Procedure. 
                                    /// This example used a SP, to minimize the usage of T-SQL constructs in the code.
                                    ///  

                                    SqlCommand sql_cmnd = new SqlCommand("GetChangesFromTable", connection);
                                    sql_cmnd.CommandType = CommandType.StoredProcedure;
                                    sql_cmnd.Parameters.AddWithValue("@TableName", SqlDbType.VarChar).Value = edgeSourceTab;
                                    sql_cmnd.Parameters.AddWithValue("@last_sync_version", SqlDbType.BigInt).Value = last_sync_version;

                                    connection.Open();
                                    SqlDataAdapter da = new SqlDataAdapter(sql_cmnd);
                                    da.Fill(ds);
                                    da.Dispose();

                                    /// Convert this Database to a Json Object.
                                    /// This JSON will be used to sync data to the targets
                                    /// 
                                    connection.Close();
                                    Console.WriteLine("Completed Reading the Data from the SQL Edge Database");
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

            return ds;
        }

        public static void write_to_edge(string connestring, string desttableName, DataSet ds, string CloudSourceTable)
        {
            /// The function takes a data source and writes it to a SQL Table using a stored procedure. the Stored procedure uses the MERGE statement to identify the exisiting records to update. 
            /// 

            // First parse the dataset to get the current version number
            long currnet_version = (Int64)ds.Tables[0].Rows[0]["Current_Sync_Version"];
            
            // Pass the second ds as a parameter to a SQL Stored Procedure.
            using (SqlConnection connection = new SqlConnection(connestring))
            {
                try
                {
                    SqlCommand sql_cmnd = new SqlCommand("dbo.WriteChangesToTable", connection);
                    sql_cmnd.CommandType = CommandType.StoredProcedure;
                    sql_cmnd.Parameters.AddWithValue("@tableName", SqlDbType.NVarChar).Value = desttableName;
                    sql_cmnd.Parameters.AddWithValue("@tableInput", ds.Tables[1]);

                    connection.Open();
                    int result = (Int32)sql_cmnd.ExecuteNonQuery();
                    connection.Close();
                    
                    ////Insert an entry into the SQLite Database to record the last_sync Version and the Source Table Name. 
                    SQLiteDatabaseOperations.InsertRecords(currnet_version, "AzureSQLDatabase", CloudSourceTable);

                    Console.WriteLine("Completed Writing the Data to the SQL Edge Database");
                }
                catch (SqlException e)
                {
                    Console.WriteLine(e.Message);
                }
            }
            
        }

        public static DataSet read_from_sqldb(string sqldbConn, string sqldbSourceTab)
        {
            DataSet ds = new DataSet();

            if (sqldbConn != "" || sqldbSourceTab != "")
            {
                //check if the table has change tracking enabled and then get the min_valid_version for the table. 
                long min_version = GetMinValidCTVersionsFromSQL(sqldbConn, sqldbSourceTab);

                if (min_version != -1)
                {
                    ///Read the last Sync Value For the Source Table.
                    ///
                    long last_sync_version = SQLiteDatabaseOperations.SelectLastSyncVersion("AzureSQLDatabase", sqldbSourceTab);
                    try
                    {
                        try
                        {
                            try
                            {
                                using (SqlConnection connection = new SqlConnection(sqldbConn))
                                {

                                    //Read Data from SQL Edge using the Predefined Stored Procedure. 
                                    /// This example used a SP, to minimize the usage of T-SQL constructs in the code.
                                    ///  

                                    SqlCommand sql_cmnd = new SqlCommand("GetChangesFromTable", connection);
                                    sql_cmnd.CommandType = CommandType.StoredProcedure;
                                    sql_cmnd.Parameters.AddWithValue("@TableName", SqlDbType.VarChar).Value = sqldbSourceTab;
                                    sql_cmnd.Parameters.AddWithValue("@last_sync_version", SqlDbType.BigInt).Value = last_sync_version;

                                    connection.Open();
                                    SqlDataAdapter da = new SqlDataAdapter(sql_cmnd);
                                    da.Fill(ds);
                                    da.Dispose();

                                    /// Convert this Database to a Json Object.
                                    /// This JSON will be used to sync data to the targets
                                    /// 
                                    connection.Close();
                                    Console.WriteLine("Completed Reading the Data from the Azure SQL Database");
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

            return ds;

        }

        public static void write_to_sqldb(string connestring, string desttableName, DataSet ds, string EdgeSourceTable)
        {
            /// The function takes a data source and writes it to a SQL Table using a stored procedure. the Stored procedure uses the MERGE statement to identify the exisiting records to update. 
            /// 

            // First parse the dataset to get the current version number
            long currnet_version = (Int64)ds.Tables[0].Rows[0]["Current_Sync_Version"];

            // Pass the second ds as a parameter to a SQL Stored Procedure.
            using (SqlConnection connection = new SqlConnection(connestring))
            {
                try
                {
                    SqlCommand sql_cmnd = new SqlCommand("dbo.WriteChangesToTable", connection);
                    sql_cmnd.CommandType = CommandType.StoredProcedure;
                    sql_cmnd.Parameters.AddWithValue("@tableName", SqlDbType.NVarChar).Value = desttableName;
                    sql_cmnd.Parameters.AddWithValue("@tableInput", ds.Tables[1]);

                    connection.Open();
                    int result = (Int32)sql_cmnd.ExecuteNonQuery();
                    connection.Close();

                    ////Insert an entry into the SQLite Database to record the last_sync Version and the Source Table Name. 
                    SQLiteDatabaseOperations.InsertRecords(currnet_version, "AzureSQLEdge", EdgeSourceTable);

                    Console.WriteLine("Completed Writing Data to the Azure SQL Database");
                }
                catch (SqlException e)
                {
                    Console.WriteLine(e.Message);
                }
            }
        }

        public static void edge_to_cloud(string edgeconn, string edgeSourceTab, string sqldbConn, string cloudDestTable, int FrequencyInMinutes)
        {
            while (true)
            {
                DataSet ds = read_from_edge(edgeconn, edgeSourceTab);
                write_to_sqldb(sqldbConn, cloudDestTable, ds, edgeSourceTab);

                Thread.Sleep(new TimeSpan(0, FrequencyInMinutes, 0));
            }
            
        }

        public static void cloud_to_edge(string sqldbConn, string cloudSourceTable, string edgeconn, string EdgeDestTable, int FrequencyInMinutes)
        {
            while (true)
            {
                DataSet ds = read_from_sqldb(sqldbConn, cloudSourceTable);
                write_to_edge(edgeconn, EdgeDestTable, ds, cloudSourceTable);

                Thread.Sleep(new TimeSpan(0, FrequencyInMinutes, 0));
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
                    string query1 = "Select count(*) as TableCount from sys.change_tracking_tables where object_id = object_id(N'" + TableName + "')";

                    SqlCommand sql_cmnd1 = new SqlCommand(query1, connection);
                    connection.Open();
                    int result = (Int32)sql_cmnd1.ExecuteScalar();
                    if (result == 1)
                    {
                        Console.WriteLine($"The specified Table [{TableName}] is enabled for change tracking.");

                        //Get the Min Valid Version for the Table. 

                        string query = "Select CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID(N'" + TableName + "')) as min_version";
                        //Console.WriteLine($"SQL Query -> {query}");
                        SqlCommand sql_cmd = new SqlCommand(query, connection);

                        object tempval = sql_cmd.ExecuteScalar();
                        if (tempval.GetType() != typeof(DBNull))
                        {
                            min_version = (Int64)tempval;
                        }
                        
                    }
                    else
                        Console.WriteLine("The specified table is not enabled for Changed Tracking");

                    connection.Close();
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
    }
}
