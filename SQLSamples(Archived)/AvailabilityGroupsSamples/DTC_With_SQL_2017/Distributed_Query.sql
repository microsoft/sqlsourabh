set xact_abort on

begin Distributed transaction 
Select * from  windowsnod3.[WideWorldImporters].[Application].people 
Select * from  windowsnod4.[WideWorldImporters].[Application].people 
Commit Tran

begin Distributed transaction 
Select p1.FullName, p2.Logonname from  windowsnod3.[WideWorldImporters].[Application].people p1
inner join windowsnod4.[WideWorldImporters].[Application].people p2
on p1.personID = p2.personID
Commit Tran

begin Distributed transaction 
declare @count int = 1
insert into windowsnod3.[WideWorldImporters].[dbo].[SomeDistTranTable]
values (@count, getdate(), replicate(cast(@count as char(8)), 500))
Commit Tran

begin Distributed transaction 
Select p1.FullName, p2.Logonname from  
windowsnod3.[WideWorldImporters].[Application].people p1
inner join windowsnod3.[WideWorldImportersDW].Fact.Purchase p2
on p1.personID = p2.personID
Commit Tran

