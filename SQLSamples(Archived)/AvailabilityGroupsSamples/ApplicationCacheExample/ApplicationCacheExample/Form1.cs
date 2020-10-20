using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;
using System.Configuration;

namespace ApplicationCacheExample
{
    public partial class Form1 : Form
    {
        TranCaching lnklist;
        public Form1()
        {
            InitializeComponent();
            lnklist = new TranCaching();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            //Create the connection and insert a record into the table 

            string ConnectionString = System.Configuration.ConfigurationManager.ConnectionStrings["db"].ToString();
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    if (this.Value.Text != null)
                    {
                        SqlCommand cmd = new SqlCommand();
                        cmd.Connection = conn;
                        cmd.CommandText = "dbo.InsertData @a";
                        cmd.Parameters.AddWithValue("@a", Convert.ToInt32(this.Value.Text));
                        try
                        {
                            conn.Open();
                            while (lnklist.Count > 0)
                            {
                                //Traverse the Link List to see if there are command which needs to be executed. 
                                //get the first element from the list

                                SqlCommand command = lnklist.GetNode();
                                command.Connection = conn;
                                Int32 rowsAffected1 = command.ExecuteNonQuery();
                                Logger.ForeColor = Color.Green;
                                Logger.AppendText("\r\n Inserted 1 record into the Table from the Cache");


                            }
                            Int32 rowsAffected = cmd.ExecuteNonQuery();
                            Logger.ForeColor = Color.Green;
                            Logger.AppendText("\r\n Inserted 1 record into the Table");
                            conn.Close();
                        }
                        catch (SqlException ed)
                        {
                            Logger.ForeColor = Color.Red;
                            //this.Logger.AppendText("\r\n" + ed.Message);
                            Logger.AppendText("\r\n Encountered Connection Exception - Caching the Transaction");
                            lnklist.AddAtLast(cmd);
                            Logger.AppendText("\r\n Current cached Count : " + lnklist.Count.ToString());
                        }
                        finally
                        {
                            conn.Close();
                        }

                    }
                    else
                    {
                        Logger.ForeColor = Color.Red;
                        Logger.AppendText("\r\n Please specify a value to insert");
                    }
                }

            }
            catch (DataException ex)
            {
                this.Logger.ForeColor = Color.Red;
                this.Logger.AppendText("\r\n" + ex.Message);
            }
        }
    }
}
