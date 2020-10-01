# Data Movement from Edge to Cloud

The sample solution in this folder illustrates how to read data from a Azure SQL Edge table to and write to EventHub in Azure. Once the data lands in EventHub, users can use Azure Services like ADF or ASA, to write this data to a Azure Data Service of their choice. 

## Usage

The sample solution can either be executed directly from within Visual Studio or can be containerized and deployed as a container. 

- When using directly from Visual Studio, make sure to update the following values in the **Program.cs** file. 
    ```csharp
    string SQLConnectionString = "<SQL Edge connection String>"; // Connection string for the SQL Edge Instance. 
    string SourceTableName = "<Table Name>"; //Source Table Name
    string EventHubConnectionString = ""; // Connection String to the Event Hub
    string EventHubName = ""; // Name of the Event hub
    int ReadWriteFrequency = 1; /// Read/Write interval in minutes. 
    ```
- When using as a docker container, make sure to update the values in the **MyEnvironmentVariable.env** file.

## Classes

There are two main classes used in the sample solution. 

- Miscellaneouss - Implements the following functions 
    - CheckNetworkConnectivity - Checks if internet connectivity is available or not using a simple ping to www.bing.com
    - ReadDataSQLEdge - solution for reading the data from SQL and storing those in intermediate JSON files. 
    - WriteEventHub - Writing the data to the Event Hub.
    - GetMinValidCTVersionsFromSQL - Gets the minimum valid Change tracking version from the database. 
    - DeleteOldUploadedFiles - Delete the old intermediate JSON files which have been processesed. 

- SQLiteDatabaseOperations - Implements the functions required for inserting, updating and retrieving the last sync version for the Read operations. 

## Building Blocks 

There are four main aspects of this sample solution. 

### Change Tracking 

The solution makes use of change tracking feature in SQL, to read delta changes (inserts and updates) from the source table. For the purpose of this sample, I created a stored procedure in the SQL Edge database to read the current sync version and the changes from the source table table.  For more information, see [Change Tracking](https://docs.microsoft.com/sql/relational-databases/track-changes/about-change-tracking-sql-server).

```sql
Create Procedure GetChangesFromTable @tableName varchar(100), @last_sync_version bigint
AS
declare @synchronization_version bigint = CHANGE_TRACKING_CURRENT_VERSION(); 
declare @query varchar(500) 

select @synchronization_version as Current_Sync_Version

Set @query = 'SELECT P.*
FROM ' + 
@tableName + ' AS P  
inner JOIN CHANGETABLE(CHANGES ' + @tableName + ',' + cast(@last_sync_version as varchar(10)) + ') AS CT  
ON CT.MachineId = P.MachineID and CT.[Time]=P.[Time] 
Where CT.SYS_CHANGE_OPERATION in (''I'', ''U'')'
Execute(@query)
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

### Intermedia Storage of the data read from SQL

The change data from the SQL table is serialized into a JSON document and stored on the disk. The stored JSON documents are then asynchronously sent to the Event Hub. 

```csharp
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
```

## Writing to Event Hub

Asynchronously send the records in the JSON documents to Event Hub. Before writing the data to the Event Hub, the following checks are performed. 

- Check network connectivity
- Check the size of the JSON file. If the size of the JSON is larger than the max event size (1 MB) for Event Hub, the JSON is broken down into smaller chunks before sending. 

```csharp
if (json.Length >= 1048576)
{
    //The json file is too big to send to event hub. The Limit on Standard Event Hub is 1 MB
    // breakdown the JSON File and construct smaller json documents. 

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
        json2 = JsonSerializer.Serialize(array);
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
}
```
