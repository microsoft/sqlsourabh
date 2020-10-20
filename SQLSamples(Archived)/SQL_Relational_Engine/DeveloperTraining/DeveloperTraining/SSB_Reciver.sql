--create Reciever database 
create database Reciever 
Go

ALTER DATABASE Reciever SET TRUSTWORTHY ON
Alter authorization On Database::Reciever to sa

use Reciever
go

drop table test_rec
create table test_rec(sum_1 xml)
go
select * from test_rec with (nolock)
------------- Create Message Type ------------
/****** Object: MessageType [MsgDialer] Script Date: 05/09/2008 23:27:32 ******/
CREATE MESSAGE TYPE [TEST_MESSAGE] VALIDATION = NONE
GO

---- Create Contract -------------
/****** Object: ServiceContract [ContractDialer] Script Date: 05/09/2008 23:26:55 ******/
CREATE CONTRACT [TEST_CONTRACT] 
([TEST_MESSAGE] SENT BY ANY)
Go


------ Create Queue---------
CREATE QUEUE [Queue_test] WITH STATUS = ON , 
RETENTION = OFF , ACTIVATION ( 
STATUS = ON , 
PROCEDURE_NAME = [dbo].[Test_Act_Proc] , MAX_QUEUE_READERS = 48 , 
EXECUTE AS SELF) 
Go
/****** Object: ServiceQueue [dbo].[Queue225] Script Date: 05/09/2008 23:25:58 ******/



/****** Object: BrokerService [Svc225] Script Date: 05/09/2008 23:25:11 ******/
CREATE SERVICE [Service_Rec] AUTHORIZATION [dbo] ON 
QUEUE [dbo].[Queue_test] ([TEST_CONTRACT])
Go




create proc [dbo].[Test_Act_Proc]
as 
Print 'Activation Proc Starting'
declare @message XML
declare @mtype nvarchar(100)
declare @r nvarchar(100)
waitfor (receive top(1) @message=CAST(message_body as XML),
	@mtype=message_type_id,@r=conversation_handle from [Queue_test] ), 
	timeout 1000
select @message
insert into test_rec values(@message)
IF @@ROWCOUNT = 0 
BEGIN
	if @@trancount > 0
		rollback
	print 'NoData??'
	return
END
GO





 