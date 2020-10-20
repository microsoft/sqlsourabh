using System;
using System.Data.SqlClient;
using System.Threading;

namespace ConsoleApplication1
{
    class Program
    {
        public static string GetTruckRouteURL()
        {
            string ConnectionStrings = "Data Source=.;Initial Catalog=Test_Bing_Maps;Integrated Security=True";
            SqlConnection conn = new SqlConnection(ConnectionStrings);
            string URL = null;
            try
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand("dbo.GetAddressURL", conn);
                cmd.CommandType = System.Data.CommandType.StoredProcedure;
                Object output = cmd.ExecuteScalar();
                Console.WriteLine(output.ToString());
                Console.ReadLine(); 
                URL = output.ToString();
                conn.Close();
                return URL;
            }
            catch (Exception e)
            {
                Console.Write(e.Message.ToString());
                Console.ReadLine();
                return null;
            }
            
        }
        static void Main(string[] args)
        {
            //SqlConnection conn = new SqlConnection();

            //Console.WriteLine(GetTruckRouteURL());
            
            int n = 0;
            int sleeptime = 3000;
            while (n <= 2500)
            {
                SqlConnection conn = new SqlConnection();
                conn.ConnectionString = "Data Source=51.143.0.59;" +
                                        "Initial Catalog=Test1;" +
                                        "User id=sa;" +
                                        "Password=!Locks123";  // ;
                try
                {
                    var query = "Select @@servername";
                    var command = new SqlCommand(query, conn);
                    conn.Open();
                    var servername = command.ExecuteScalar();
                    Console.WriteLine("Returned Servername- {0} at Data/Time - {1}", servername.ToString(), System.DateTime.Now.ToString());
                    //Console.ReadLine();
                    conn.Close();
                    conn.Dispose();
              

                }
                catch (Exception e)
                {
                    string message1 = "Cannot open database ";
                    if (e.Message.ToString().Contains(message1))
                    {
                        conn.Close();
                        conn.Dispose();
                    }
                    else if (e.Message.ToString().Contains("A network-related or instance-specific error occurred while establishing a connection to SQL Server"))
                    {
                        conn.Close();
                        conn.Dispose();
                    }
                    else if (e.Message.ToString().Contains("because the database replica is not in the PRIMARY or SECONDARY role"))
                    {
                        Console.WriteLine("Availability Group in Resolving State");
                        conn.Close();
                        conn.Dispose();
                    }
                    else
                        Console.WriteLine("Error {0} with Message {1} was encountered",e.Data, e.Message);
                    //Console.ReadLine();                   
                }
                n++;
                Thread.Sleep(sleeptime);
            
            }
            

        }
    }
}
