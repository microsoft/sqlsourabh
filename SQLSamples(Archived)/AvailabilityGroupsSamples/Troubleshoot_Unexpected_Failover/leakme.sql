declare @hdl int
exec sp_cursoropen @hdl OUTPUT, N'select * from sys.sysobjects s1',4,4,100
go