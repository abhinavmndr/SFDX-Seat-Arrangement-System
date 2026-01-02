@IsTest
public class SAS_Test_Employee_Sharing_Flow {

    @TestSetup
    public static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' WITH SECURITY_ENFORCED LIMIT 1];

        User empUser = new User(
            Alias = 'empuser',
            Email = 'employeeuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Employee',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'employeeuser' + DateTime.now().getTime() + '@example.com'
        );
        Database.insert(empUser, false);

        Block__c block = new Block__c(Name='Test Block', Total_Seats__c=10);
        Database.insert(block, false);
    }

    @IsTest
    public static void givenEmployeeWithUserLookup_WhenCreated_ThenEmployeeShareCreated() {
        User empUser = [SELECT Id FROM User WHERE LastName='Employee' WITH SECURITY_ENFORCED LIMIT 1 ];
        Block__c block = [SELECT Id FROM Block__c WHERE Name='Test Block' WITH SECURITY_ENFORCED LIMIT 1];

        Employee__c emp = new Employee__c(
            Name = 'Employee With Share',
            User__c = empUser.Id,
            Block__c = block.Id,
            Group__c = 'A'
        );

        Database.insert(emp, false);

        List<Employee__Share> shares = [
            SELECT Id, UserOrGroupId, AccessLevel, RowCause 
            FROM Employee__Share 
            WHERE ParentId = :emp.Id 
            AND UserOrGroupId = :emp.User__c
            WITH SECURITY_ENFORCED
        ];

        System.assertEquals(1, shares.size(), 'One share record should be created');
        System.assertEquals(empUser.Id, shares[0].UserOrGroupId, 'Share should be assigned to the User in User__c field');
        System.assertEquals('Edit', shares[0].AccessLevel, 'Access level should match what the flow sets');
    }
}