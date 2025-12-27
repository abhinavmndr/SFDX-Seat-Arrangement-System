@isTest
public class SAS_Test_Employee_Controller {
	@testSetup
    public static void setupTestData() {

        //Create Blocks
        Block__c block1 = new Block__c(
            Name = 'Block A',
            Total_Seats__c = 20,
            Daily_Seats_Available__c = 10
        );
        Block__c block2 = new Block__c(
            Name = 'Block B',
        	Total_Seats__c = 18,
            Daily_Seats_Available__c = 10
        );
        insert new List<Block__c>{block1, block2};
            
 		//Create Teams
 		Team__c teamA = new Team__c(Name = 'Team A');
 		Team__c teamB = new Team__c(Name = 'Team B');
        insert new List<Team__c>{teamA, teamB};

        //Create Employees
        List<Employee__c> employees = new List<Employee__c>();
        employees.add(new Employee__c(
            Name = 'Abhinav Manandhar',
            User__c = UserInfo.getUserId(), // current user
            Block__c = block1.Id,
            Group__c = 'A',
            Team__c = teamA.Id,
            Email__c = 'abhinav@test.com'
        ));
        employees.add(new Employee__c(
            Name = 'Suman Shrestha',
            Block__c = block1.Id,
            Group__c = 'A',
            Team__c = teamB.Id,
            Email__c = 'suman@test.com'
        ));
        employees.add(new Employee__c(
            Name = 'Ramesh Khatri',
            Block__c = block2.Id,
            Group__c = 'B',
            Team__c = teamA.Id,
            Email__c = 'ramesh@test.com'
        ));
        insert employees;
    }

    @IsTest
    public static void givenLoggedInUser_WhenGetLoggedInEmployeeId_ThenReturnsEmployeeRecord() {

        Test.startTest();
        Employee__c emp = SAS_Employee_Controller.getLoggedInEmployeeId();
        Test.stopTest();

        System.assertNotEquals(null, emp, 'Employee record should not be null');
        System.assertEquals(UserInfo.getUserId(), [SELECT User__c FROM Employee__c WHERE Id=:emp.Id WITH SECURITY_ENFORCED].User__c,
                            'Employee.User__c should match logged in user');
    }

    @IsTest
    public static void givenGroupName_WhenGetEmployeesByGroup_ThenReturnsEmployeesInGroup() {

        List<Employee__c> emps = SAS_Employee_Controller.getEmployeesByGroup('A');
        List<Employee__c> empsBlank = SAS_Employee_Controller.getEmployeesByGroup('');
        
        System.assertEquals(0, empsBlank.size(), 'Should return 0 employees in Group1');
        System.assertEquals(2, emps.size(), 'Should return 2 employees in Group1');
        
        for (Employee__c e : emps) {
            System.assertEquals('A', e.Group__c, 'Employee Group__c should match input');
        }
    }

    @IsTest
    public static void givenTeamName_WhenGetEmployeesByTeam_ThenReturnsEmployeesInTeam() {

        Team__c t = [SELECT Id, Name FROM Team__c WHERE Name = 'Team A'];
        List<Employee__c> emps = SAS_Employee_Controller.getEmployeesByTeam(t.Id);
        List<Employee__c> empsBlank = SAS_Employee_Controller.getEmployeesByTeam('');

        System.assertEquals(2, emps.size(), 'Should return 2 employees in TeamA');
        System.assertEquals(0, empsBlank.size(), 'Should return 0 employees in TeamA');
    }

    @IsTest
    public static void givenEmployeeName_WhenGetEmployeesByName_ThenReturnsMatchingEmployees() {

        List<Employee__c> emps = SAS_Employee_Controller.getEmployeesByName('Abhinav');
        //List<Employee__c> empsBlank = SAS_Employee_Controller.getEmployeesByName('');

        System.assertEquals(1, emps.size(), 'Should return 1 employee matching name');
        //System.assertEquals(0, emps.size(), 'Should return 0 employee');
        
        System.assert(emps[0].Name.contains('Abhinav'), 'Employee name should contain search text');
    }

    @IsTest
    public static void givenEmployeeIds_WhenBulkUpdateEmployees_ThenRecordsAreUpdated() {

        List<Employee__c> emps = [SELECT Id, Block__c, Group__c FROM Employee__c WHERE Group__c='A'];
        Id newBlockId = [SELECT Id FROM Block__c WHERE Name='Block B' WITH SECURITY_ENFORCED LIMIT 1].Id;

        Test.startTest();
        SAS_Employee_Controller.bulkUpdateEmployees(
            new List<Id>{emps[0].Id, emps[1].Id},
            newBlockId,
            'B'
        );
        Test.stopTest();

        List<Employee__c> updatedEmps = [SELECT Id, Block__c, Group__c FROM Employee__c WHERE Id IN :emps WITH SECURITY_ENFORCED];
        for (Employee__c e : updatedEmps) {
            System.assertEquals(newBlockId, e.Block__c, 'Block should be updated');
            System.assertEquals('B', e.Group__c, 'Group should be updated');
        }
    }

    @IsTest
    public static void givenGroupAndBlock_WhenGetAvailableSeats_ThenReturnsSeatsFromFlow() {

        // Create dummy Block__c for test
        Block__c block = [SELECT Id FROM Block__c WITH SECURITY_ENFORCED LIMIT 1];

        Test.startTest();
        // Note: This calls the autolaunched Flow
        // In tests, you need to make sure the Flow is active in the org
        Integer seats = SAS_Employee_Controller.getAvailableSeats('A', block.Id);
        Test.stopTest();

        // We cannot assert exact seats in test context unless we mock flow
        System.assertNotEquals(null, seats, 'Seats should be returned');
    }
}