:Connect Node6
Grant Alter Any Availability Group TO [NT Authority\System]
Grant Connect SQL TO [NT Authority\System]
Grant View server state TO [NT Authority\System]

Drop Availability Group [AutoFailoverFailure]
Go
Drop Database [DB2]
Go

:Connect Node7,1500

Grant Alter Any Availability Group TO [NT Authority\System]
Grant Connect SQL TO [NT Authority\System]
Grant View server state TO [NT Authority\System]

Drop Database [DB2]
Go