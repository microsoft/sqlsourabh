create database BLOCKING_EXAMPLE
Go

select * from sys.databases where database_id = DB_ID ('BLOCKING_EXAMPLE')

--- Alter this DB to Enable Broker and Enable TRUSTWORTHY ON

ALTER DATABASE BLOCKING_EXAMPLE SET ENABLE_BROKER
Go
ALTER DATABASE BLOCKING_EXAMPLE SET TRUSTWORTHY ON
Go
Use BLOCKING_EXAMPLE
Go

------------- Create Message Type ------------
/****** Object: MessageType [MsgDialer] Script Date: 05/09/2008 23:27:32 ******/
CREATE MESSAGE TYPE [TEST_MESSAGE] VALIDATION = NONE
GO

---- Create Contract -------------
/****** Object: ServiceContract [ContractDialer] Script Date: 05/09/2008 23:26:55 ******/
CREATE CONTRACT [TEST_CONTRACT] 
	AUTHORIZATION [dbo] ([TEST_MESSAGE] SENT BY ANY)
Go


------ Create Queue---------
/****** Object: ServiceQueue [dbo].[Queue225] Script Date: 05/09/2008 23:25:58 ******/
CREATE QUEUE [dbo].[Queue_test] 
WITH STATUS = ON , 
RETENTION = OFF , 
ACTIVATION ( 
						STATUS = ON , 
						PROCEDURE_NAME = [dbo].[Test_Act_Proc] , 
						MAX_QUEUE_READERS = 48 , 
						EXECUTE AS SELF
				  ) 
Go


/****** Object: BrokerService [Svc225] Script Date: 05/09/2008 23:25:11 ******/
CREATE SERVICE [Service_test] AUTHORIZATION [dbo] 
	ON QUEUE [dbo].[Queue_test] ([TEST_CONTRACT])
Go

--- Create a table for Recieved Messages
create table Recieved_Messages(message XML, mtype varchar(100))
Go
drop procedure Test_Act_Proc
go
create proc [dbo].[Test_Act_Proc]
as 
Print 'Activation Proc Starting'
declare @message XML
declare @mtype nvarchar(100)
declare @r nvarchar(100)
waitfor (receive top(1) 
			@message=CAST(message_body as XML),
			@mtype=message_type_id,
			@r=conversation_handle 
			from [Queue_test] ), 
	timeout 1000
select @message
insert into Recieved_Messages values(@message, @mtype)
IF @@ROWCOUNT = 0 
BEGIN
	if @@trancount > 0
		rollback
	print 'NoData??'
	return
END
GO


-- Create a Test Table on which we will create the trigger.. 
Create table test_SSB(a int, b int)
GO

create trigger SSB_trigger 
on test_SSB
AFTER INSERT
as
declare @h as uniqueIdentifier
declare @message varchar(1000)

declare @test1 int, @test2 int
select @test1=a, @test2=b from INSERTED with(nolock)

Set @message = ''
set @message = @message + 'The value Inserted in the table were '+ Cast(@test1 as varchar(10)) + ' and '+ Cast(@test2 as varchar(10));

BEGIN DIALOG CONVERSATION @h
FROM SERVICE [Service_test] TO SERVICE 'Service_test', 'CURRENT DATABASE'
ON CONTRACT [TEST_CONTRACT]
with encryption = off;
SEND ON CONVERSATION @h MESSAGE TYPE [TEST_MESSAGE] (@message)
print @h

IF EXISTS(select * from sys.conversation_endpoints 
						where conversation_handle=@h and state='ER')
	begin
		RAISERROR ('Service Broker in error state',18,127)
		rollback transaction
	end
else
	begin
		END CONVERSATION @h WITH CLEANUP;
		print 'Clean Up Completed'
	end 

GO

--- Now Lets insert a row in the Table 
set Statistics profile on
Go
insert into test_SSB values(1,2)
go
set Statistics profile off
Go

--- Lets try and query some information from the Service Broker
select * from sys.conversation_endpoints
go

end conversation 'E7859D9A-EE1B-E111-B3D1-00271366579F' with cleanup
Go

select * from [Queue_test]
go

select * from sys.transmission_queue
go

select * from Recieved_Messages
go

SELECT * FROM test_SSB



