using System;
using System.Collections.Generic;
using System.Data.SQLite;
using System.IO;

namespace BidirectionalSync
{
    class SQLiteDatabaseOperations
    {
        // This class implements all the functions required to create table, insert data, update data in the SQLite Database.
        // This database is used to track the Synchronization artifacts for the data movement to cloud. 
        //

        public static void CreateDatabaseAndTable()
        {
            if (!File.Exists("SyncInfoDatabase.sqllite"))
            {
                SQLiteConnection.CreateFile("SyncInfoDatabase.sqllite");

                string sql = @"CREATE TABLE SyncInformation(
                               timestamp Text ,
                               last_sync_value Integer,
                               identifier TEXT,
                               sourceTableName TEXT);";

                SQLiteConnection con = new SQLiteConnection("Data Source=SyncInfoDatabase.sqllite;Version=3;");
                con.Open();
                SQLiteCommand cmd = new SQLiteCommand(sql, con);
                cmd.ExecuteNonQuery();

                //create an index on the table 

                string sql1 = @"CREATE INDEX idx on SyncInformation(sourceTableName,identifier, timestamp)";
                cmd.CommandText = sql1;
                cmd.ExecuteNonQuery();

                con.Close();

            }
        }
        public static void InsertRecords(long last_sync_value, string identifier, string sourceTableName)
        {
            //SQLiteConnection.CreateFile("SyncInfoDatabase.sqllite");
            string sql = @"INSERT INTO SyncInformation(timestamp, last_sync_value, identifier, sourceTableName) values ('" +
                    DateTime.UtcNow.ToString() + "', " + last_sync_value.ToString() + ", '" + identifier + "', '" + sourceTableName + "')" ;

            SQLiteConnection con = new SQLiteConnection("Data Source=SyncInfoDatabase.sqllite;Version=3;");
            con.Open();
            SQLiteCommand cmd = new SQLiteCommand(sql, con);
            cmd.ExecuteNonQuery();
            con.Close();
        }
        public static long SelectLastSyncVersion(string identifier, string sourceTableName)
        {
            long last_sync_version = 0;
            //SQLiteConnection.CreateFile("SyncInfoDatabase.sqllite");
            string sql = @"SELECT max(last_sync_value) as last_sync_version FROM SyncInformation where identifier = '" + identifier 
                + "' and sourceTableName = '" + sourceTableName + "'";
            SQLiteConnection con = new SQLiteConnection("Data Source=SyncInfoDatabase.sqllite;Version=3;");
            con.Open();
            SQLiteCommand cmd = new SQLiteCommand(sql, con);
            object tempval = cmd.ExecuteScalar();
            if (tempval.GetType() != typeof(DBNull))
                last_sync_version = Convert.ToInt64(tempval);
            con.Close();
            Console.WriteLine($"Last Sync Version -> {last_sync_version}");
            return last_sync_version;
        }

    }
}
