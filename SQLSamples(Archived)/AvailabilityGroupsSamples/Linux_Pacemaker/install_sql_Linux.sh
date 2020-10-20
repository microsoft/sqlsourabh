#!/bin/bash -e
# Installing SQL Server on Linux. Using local installation package
clear

## Perform cleanup of any existing installation
echo "**************************************************************************"
echo "Removing an Existing installations of SQL Server"
echo "**************************************************************************"
echo
echo
sudo cd /LinuxRPMS/
sudo yum -y remove mssql-server

date1="$(date +%s)"

#Password for SQL Server
MSSQL_SA_PASSWORD='!Locks123'

#SQL Server Edition and PID
MSSQL_PID='evaluation'


echo "**************************************************************************"
echo "Starting SQL Server Installation, with local installation media"
echo "**************************************************************************"

sudo yum -y localinstall mssql-server-14.0.3030.27-1.x86_64.rpm

echo "********************************************************************************************"
echo "Running mssql-conf setup for SQL Server Configurations (SA Password and Instance Edition)"
echo "********************************************************************************************"
echo
echo
sudo systemctl stop mssql-server
sudo MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD \
     MSSQL_PID=$MSSQL_PID \
    /opt/mssql/bin/mssql-conf -n setup accept-eula

echo "********************************************************************************************"
echo "Setting up firewall policy for SQL Server - Using Port 1433 "
echo "********************************************************************************************"
echo
echo

sudo firewall-cmd --zone=public --add-port=1433/tcp --permanent	
sudo firewall-cmd --reload

echo "********************************************************************************************"
echo "Setting up trace flags 1222, 1204,3004,3605 for SQL Server"
echo "********************************************************************************************"
echo
echo
sudo /opt/mssql/bin/mssql-conf traceflag 1222 1204 3004 3605 on

echo "********************************************************************************************"
echo "Configuring SQL Server Memory "
echo "********************************************************************************************"
echo
echo
sudo /opt/mssql/bin/mssql-conf set memory.memorylimitmb 3000

# Start SQL Server Instance 
sudo systemctl restart mssql-server

sleep 5

echo "********************************************************************************************"
echo "Restoring WideWorldImporters Database from backup File"
echo "********************************************************************************************"
echo
## ensure the database files do not exists
rm -f /var/opt/mssql/data/WideWorldImporters.ldf 
rm -f /var/opt/mssql/data/WideWorldImporters.mdf 
rm -f /var/opt/mssql/data/WideWorldImporters_UserData.ndf 
rm -f /var/opt/mssql/data/WideWorldImporters_InMemory_Data_1 -r

#Attempt Database Restore
sqlcmd -Usa -P'!Locks123' -Slocalhost -i"/LinuxRPMS/Restore_Database_command.sql" -r1

date2="$(date +%s)"
echo
echo
echo "************************************************************************"
echo
echo "Completed Installation and configuration in $((date2-date1)) seconds"
echo
echo "************************************************************************"


#Display SQL Server Error Log
#sudo cat /var/opt/mssql/log/errorlog 





