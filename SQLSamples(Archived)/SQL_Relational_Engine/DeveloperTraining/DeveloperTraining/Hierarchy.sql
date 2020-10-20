USE AdventureWorks
GO
drop table HumanResources.EmployeeOrg


CREATE TABLE HumanResources.EmployeeOrg
(
   OrgNode hierarchyid PRIMARY KEY CLUSTERED,
   OrgLevel AS OrgNode.GetLevel(),
   EmployeeID int UNIQUE NOT NULL,
   EmpName varchar(20) NOT NULL,
   Title varchar(20) NULL
) ;
GO
truncate table HumanResources.EmployeeOrg

CREATE UNIQUE INDEX EmployeeOrgNc1 
ON HumanResources.EmployeeOrg(OrgLevel, OrgNode) ;
GO

INSERT HumanResources.EmployeeOrg (OrgNode, EmployeeID, EmpName, Title)
VALUES (hierarchyid::GetRoot(), 6, 'David', 'Marketing Manager') ;
GO

SELECT OrgNode.ToString() AS Text_OrgNode, 
OrgNode, OrgLevel, EmployeeID, EmpName, Title 
FROM HumanResources.EmployeeOrg ;


DECLARE @Manager hierarchyid 
SELECT @Manager = hierarchyid::GetRoot()
FROM HumanResources.EmployeeOrg ;

INSERT HumanResources.EmployeeOrg (OrgNode, EmployeeID, EmpName, Title)
VALUES
(@Manager.GetDescendant(NULL, NULL), 46, 'Sariya', 'Marketing Specialist') ; 
GO

ALTEr PROC AddEmp(@mgrid int, @empid int, @e_name varchar(20), @title varchar(20)) 
AS 
BEGIN
   DECLARE @mOrgNode hierarchyid, @lc hierarchyid
   SELECT @mOrgNode = OrgNode 
   FROM HumanResources.EmployeeOrg 
   WHERE EmployeeID = @mgrid
   SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
   BEGIN TRANSACTION
      SELECT @lc = min(OrgNode) 
      FROM HumanResources.EmployeeOrg 
      WHERE OrgNode.GetAncestor(1) =@mOrgNode ;

      INSERT HumanResources.EmployeeOrg (OrgNode, EmployeeID, EmpName, Title)
      VALUES(@mOrgNode.GetDescendant(NULL, @lc), @empid, @e_name, @title)
   COMMIT
END ;
GO

EXEC AddEmp 6, 1398, 'Avin2', 'Marketing Specialist' ;
EXEC AddEmp 6, 119, 'Jill', 'Marketing Specialist' ;
EXEC AddEmp 46, 269, 'Wanida', 'Marketing Assistant' ;
EXEC AddEmp 271, 272, 'Mary', 'Marketing Assistant' ;


SELECT OrgNode.ToString() AS Text_OrgNode, 
OrgNode, OrgLevel, EmployeeID, EmpName, Title 
FROM HumanResources.EmployeeOrg ;
GO

delete from HumanResources.EmployeeOrg where EmployeeID = 46

--- Query for Seriya Subordinates


DECLARE @CurrentEmployee hierarchyid

SELECT @CurrentEmployee = OrgNode
FROM HumanResources.EmployeeOrg
WHERE EmployeeID = 6 ;

SELECT OrgNode.ToString() AS Text_OrgNode, *
FROM HumanResources.EmployeeOrg
WHERE OrgNode.GetAncestor(1) = @CurrentEmployee


DECLARE @CurrentEmployee hierarchyid

SELECT EmployeeID
FROM HumanResources.EmployeeOrg
WHERE OrgNode in (select OrgNode.GetAncestor(1) 
FROM HumanResources.EmployeeOrg
where EmployeeId = 272)

SELECT OrgNode.ToString() AS Text_OrgNode, *
FROM HumanResources.EmployeeOrg
WHERE OrgNode.GetAncestor(1) = @CurrentEmployee

-- To Get the levels

SELECT OrgNode.ToString() AS Text_OrgNode, 
OrgNode.GetLevel() AS EmpLevel, *
FROM HumanResources.EmployeeOrg ;
GO

DECLARE @CurrentEmployee hierarchyid , @OldParent hierarchyid, @NewParent hierarchyid
SELECT @CurrentEmployee = OrgNode FROM HumanResources.EmployeeOrg
  WHERE EmployeeID = 271 ; 
SELECT @OldParent = OrgNode FROM HumanResources.EmployeeOrg
  WHERE EmployeeID = 6 ; 
SELECT @NewParent = OrgNode FROM HumanResources.EmployeeOrg
  WHERE EmployeeID = 119 ; 

UPDATE HumanResources.EmployeeOrg
SET 
OrgNode = @CurrentEmployee.GetReparentedValue(@OldParent, @NewParent) 
WHERE OrgNode = @CurrentEmployee ;
GO
