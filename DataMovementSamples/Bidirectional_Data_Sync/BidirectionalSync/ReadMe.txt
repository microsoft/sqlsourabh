Objectives
++++++++++++++

This sample project provides a quick demonstration for Bi-Directional Data Movement between SQL Edge and Azure SQL. For the Purpose of this demostration, the sample uses a simple "SELECT with time range" to read data from the source tables in Azure SQL Edge and Azure SQL Databases. The following pattern is used. 

										Sample Code
Azure SQL Database ------------------------------------------------------> Azure SQL Edge

										Sample Code	
Azure SQL Edge ----------------------------------------------------------> Azure SQL Database

Assumptions
+++++++++++++++++
The following assumptions have been made to reduce complexity of the sample solution. 

1. The Source and Target tables for the Data Movement (on each SQL Edge and Azure SQL Database) should be difference, otherwise we will end up with Cyclic update/inserts. Also all Source Tables (on both Edge and cloud need to have Change tracking enabled).

2. Only updates and inserts are being tracked for the purpose of this samples. The updated records are tracked using the change tracking feature in SQL.

4. All inserts/updates are implemented as MERGE operation.

5. A SQLite database is used to store the sync times

Disclaimer 
++++++++++++++
This is just a sample and provides contructs to achieve functionality which is already offered by products like Azure Data Factory and Azure SQL Data Sync.  

