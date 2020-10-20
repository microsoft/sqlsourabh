---- create sender database
create database Sender
Go

ALTER DATABASE SENDER SET TRUSTWORTHY ON
Alter authorization On Database::Sender to sa


use Sender
go

create table test_send(a int, b int)
go

------------- Create Message Type ------------
/****** Object: MessageType [MsgDialer] Script Date: 05/09/2008 23:27:32 ******/
CREATE MESSAGE TYPE [TEST_MESSAGE] VALIDATION = NONE
GO

---- Create Contract -------------
/****** Object: ServiceContract [ContractDialer] Script Date: 05/09/2008 23:26:55 ******/
CREATE CONTRACT [TEST_CONTRACT] AUTHORIZATION [dbo] ([TEST_MESSAGE] SENT BY ANY)
Go


------ Create Queue---------
/****** Object: ServiceQueue [dbo].[Queue225] Script Date: 05/09/2008 23:25:58 ******/
CREATE QUEUE [dbo].[Queue_test] WITH STATUS = ON , RETENTION = OFF 
Go


/****** Object: BrokerService [Svc225] Script Date: 05/09/2008 23:25:11 ******/
CREATE SERVICE [Service_test] AUTHORIZATION [dbo] 
ON QUEUE [dbo].[Queue_test] ([TEST_CONTRACT])
Go

create trigger SSB_trigger 
on test_send
AFTER INSERT
as
declare @h as uniqueIdentifier
declare @message varchar(1000)

declare @test1 int, @test2 int
select @test1=a, @test2=b from INSERTED with(nolock)

Set @message = ''
set @message = @message + 'The value Inserted in the table were '+ Cast(@test1 as varchar(10)) + ' and '+ Cast(@test2 as varchar(10));

BEGIN DIALOG CONVERSATION @h
FROM SERVICE [Service_test] 
TO SERVICE 'Service_Rec', 'E201AF79-CCE6-4E31-B161-5847778F131E'
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