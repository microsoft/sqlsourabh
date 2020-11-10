# Bidirectional Data Movement - Azure SQL Edge and Azure SQL Database.

The sample solution in this folder illustrates bidirectional data movement between Azure SQL and Azure SQL Edge. This sample code can be used in scenarions where the exisiting mechanisms like (Azure SQL Data Sync, Azure Data Factory or SQL Replication) cannot be used. The existing mechanims as mentioned above are optimized for this sort of data movement and offer the best out-of-box experience.

The sample code uses the following SQL features

1. Change Tracking - To read changes (update/inserts) from the source Table. The read logic is implemented in a stored procedure in the source database. This SP would need to be **updated** for a different source table schema.
2. MERGE Statement - The sample uses SQL MERGE statement to write changes (update/inserts) from the source Table. The write logic is implemented in a stored procedure in the target database. This SP would need to be **updated** for a different source/target table schema.
3. User Defined Table Type - A new user defined table type is created in the database. A table variable for this table type is used as a parameter to the Write Stored procedure. 

## Assumptions

1. For the purpose of this sample, different tables are used as a source/target pair for the bi-directional data movement. You could use the same table as source/target, which may require additional logic to remove cyclic operations. 
2. There is continous connectivity between Edge and cloud. 

## Usage

The sample solution can either be executed directly from within Visual Studio or can be containerized and deployed as a container. 

- When using directly from Visual Studio, make sure to update the following values in the **Program.cs** file. 
    ```csharp
    string sqlEdgeConnString = "<SQL Edge connection String>"; // Connection string for the SQL Edge Instance. 
    string sqlDBConnString = "<Table Name>"; //Source Table Name   
    int ReadWriteFrequency = 1; /// Read/Write interval in minutes. 
    ```
- When using as a docker container, add an environment variable file to pass the required parameters to the sample.

## Extending the Application to multiple Source/Taget Table pairs. 

The sample code can be easily extended to sync/move data across multiple different target pairs. To do that, you'll need to to the following
1. Create the correspoding read/write stored procedures for your Source/Target table schemas. 
2. Update the code in the SQLOperations class to reference the correct read/write stored procedures.
3. Create a new thread with the desired wrapper function. 

    ```csharp
    /// Task1 - Cloud to Edge Sync for Cloud Source Table 1 and Target Edge Table 1
    /// SYNTAX -> cloud_to_edge(string sqldbConn, string cloudSourceTable, string edgeconn, string EdgeDestTable, int FrequencyInMinutes)
    tasks.Add(Task.Factory.StartNew(() => SQLOperations.cloud_to_edge(sqlDBConnString, "TelemetryData", sqlEdgeConnString, "TelemetryDataTarget", ReadWriteFrequency)));
    ```

## Classes

There are two main classes used in the sample solution. 

- SQLOperations - Implements the following 4 core functions and additional two wrapper functions.
    - read_from_edge - Implements code to read data from SQL Edge.
    - write_to_edge - Implements code to write data to SQL Edge. 
    - read_from_sqldb - Implements code to read data from Azure SQL.
    - write_to_sqldb - Implements code to write data to Azure SQL.
    - Wrapper Functions 
        - edge_to_cloud - Wrapper for the Edge to Cloud sync
        - cloud_to_edge - Wrapper for Cloud to Edge data sync

- SQLiteDatabaseOperations - Implements the functions required for inserting and retrieving the last sync version for the Read operations. 

## SQL Database Schema

The sample SQL Database (and Table) schema can be implemented using the accompanying files. 
- AzureSQLObjects.sql - Creates the ables, stored procedures and table types on the Azure SQL Database.
- SQL_Edge_objects.sql - Creates the database, tables, stored procedures and table types on Azure SQL Edge.

## Building Blocks 

There are four main aspects of this sample solution. 

### Change Tracking 

The solution makes use of change tracking feature in SQL, to read delta changes (inserts and updates) from the source table. For the purpose of this sample, I created a stored procedure in the SQL Edge database to read the current sync version and the changes from the source table table. **You'll need to change the SP on the source servers to match the schema of your source tables**. For more information, see [Change Tracking](https://docs.microsoft.com/sql/relational-databases/track-changes/about-change-tracking-sql-server).

```sql
Create Procedure dbo.GetChangesFromTable @tableName varchar(100), @last_sync_version bigint
AS
declare @synchronization_version bigint = CHANGE_TRACKING_CURRENT_VERSION(); 
declare @query varchar(500) 

select @synchronization_version as Current_Sync_Version

Set @query = 'SELECT P.*
FROM ' + 
@tableName + ' AS P  
inner JOIN CHANGETABLE(CHANGES ' + @tableName + ',' + cast(@last_sync_version as varchar(10)) + ') AS CT  
ON CT.var_machineid = P.var_machineid and CT.[timestamp]=P.[timestamp] 
Where CT.SYS_CHANGE_OPERATION in (''I'', ''U'')'
Execute(@query)
Go
```

### Merge Statement

The solution makes use the MERGE T-SQL statment to update/insert records in the SQL target table. This code is implemented as a stored procedure as described below. This SP takes the target tablename and a table values parameter Input. The table type acts as the source for the MERGE statement. **You'll need to change the SP on the source servers to match the schema of your source tables**. For more information, see [MERGE (Transact-SQL)](https://docs.microsoft.com/sql/t-sql/statements/merge-transact-sql) and [Use Table-Valued Parameters (Database Engine)](https://docs.microsoft.com/sql/relational-databases/tables/use-table-valued-parameters-database-engine).

```sql
Create Procedure dbo.WriteChangesToTable @tableName nvarchar(50), @tableInput TelemetryDataTable READONLY
As
Set NoCount On
declare @query nvarchar(4000) = '
MERGE ' + @tableName + ' AS target USING @tableInput AS source  
    ON (target.[var_machineid] = source.[var_machineid] and target.[timestamp] = source.[timestamp])  
    WHEN MATCHED THEN
        UPDATE SET  
					target.[var_voltate] = source.[var_voltate],
					target.[var_rotate] = source.[var_rotate] ,
					target.[var_pressure] = source.[var_pressure],
					target.[var_vibration] = source.[var_vibration],
					target.[var_error1] = source.[var_error1] ,
					target.[var_error2] = source.[var_error2]   
    WHEN NOT MATCHED BY TARGET THEN  
        INSERT ([timestamp],[var_machineid],[var_voltate],[var_rotate],[var_pressure],[var_vibration],[var_error1],[var_error2])
			values (source.[timestamp],source.[var_machineid],source.[var_voltate],source.[var_rotate],
				source.[var_pressure],source.[var_vibration],source.[var_error1],source.[var_error2]);'

exec sp_executesql @query, N'@tableName nvarchar(50), @tableInput TelemetryDataTable READONLY', @tableName, @tableInput
Go

```

### Reading Data from the SQL Table

This section of the solution first checks if the table exists and if its enabled for Change Tracking, and then calls the stored procedure defined above to read the change tracking data from SQL. 

```csharp
SqlCommand sql_cmnd = new SqlCommand("GetChangesFromTable", connection);
sql_cmnd.CommandType = CommandType.StoredProcedure;
sql_cmnd.Parameters.AddWithValue("@TableName", SqlDbType.VarChar).Value = tablename;
sql_cmnd.Parameters.AddWithValue("@last_sync_version", SqlDbType.BigInt).Value = last_sync_version;

connection.Open();
SqlDataAdapter da = new SqlDataAdapter(sql_cmnd);
da.Fill(ds);
da.Dispose();
```

### Write Data to the SQL Table

This section of the code uses the Write stored procedure defined above to write the change tracking data from SQL. 

```csharp
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
```

