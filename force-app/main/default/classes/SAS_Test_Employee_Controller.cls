@IsTest
public class SAS_Test_Employee_Controller {

    @testSetup
    public static void setupTestData() {

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User user1 = new User(
            Alias = 'u1',
            Email = 'u1@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserOne',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'user1' + DateTime.now().getTime() + '@test.com'
        );

        Database.insert(user1, false);

        Block__c blockA = new Block__c(
            Name = 'Block A',
            Total_Seats__c = 20,
            Daily_Seats_Available__c = 10
        );

        Block__c blockB = new Block__c(
            Name = 'Block B',
            Total_Seats__c = 18,
            Daily_Seats_Available__c = 10
        );

        insert new List<Block__c>{ blockA, blockB };

        Team__c teamA = new Team__c(Name = 'Team A');
        Team__c teamB = new Team__c(Name = 'Team B');
        insert new List<Team__c>{ teamA, teamB };

        insert new List<Employee__c>{
            new Employee__c(
                Name = 'Abhinav Manandhar',
                User__c = user1.Id,
                Block__c = blockA.Id,
                Group__c = 'A',
                Team__c = teamA.Id,
                Email__c = 'abhinav@test.com'
            ),
            new Employee__c(
                Name = 'Suman Shrestha',
                Block__c = blockA.Id,
                Group__c = 'A',
                Team__c = teamB.Id,
                Email__c = 'suman@test.com'
            ),
            new Employee__c(
                Name = 'Ramesh Khatri',
                Block__c = blockB.Id,
                Group__c = 'B',
                Team__c = teamA.Id,
                Email__c = 'ramesh@test.com'
            )
        };
    }

    @IsTest
    public static void givenLoggedInUser_WhenGetLoggedInEmployeeId_ThenEmployeeReturned() {

        User u = [SELECT Id FROM User WHERE LastName='UserOne' LIMIT 1];

        System.runAs(u) {
            Employee__c emp = SAS_Employee_Controller.getLoggedInEmployeeId();

            System.assertNotEquals(null, emp);
            System.assertEquals(u.Id, emp.User__c);
        }
    }

    @IsTest
    public static void givenGroupName_WhenGetEmployeesByGroup_ThenCorrectEmployeesReturned() {

        List<Employee__c> emps = SAS_Employee_Controller.getEmployeesByGroup('A');
        List<Employee__c> empsBlank = SAS_Employee_Controller.getEmployeesByGroup('');

        System.assertEquals(2, emps.size());
        System.assertEquals(0, empsBlank.size());
    }

    @IsTest
    public static void givenTeamId_WhenGetEmployeesByTeam_ThenCorrectEmployeesReturned() {

        Team__c t = [SELECT Id FROM Team__c WHERE Name='Team A' LIMIT 1];

        List<Employee__c> emps = SAS_Employee_Controller.getEmployeesByTeam(t.Id);
        List<Employee__c> empsBlank = SAS_Employee_Controller.getEmployeesByTeam('');

        System.assertEquals(2, emps.size());
        System.assertEquals(0, empsBlank.size());
    }

    @IsTest
    public static void givenEmployeeName_WhenGetEmployeesByName_ThenMatchReturned() {

        List<Employee__c> emps = SAS_Employee_Controller.getEmployeesByName('Abhinav');

        System.assertEquals(1, emps.size());
        System.assert(emps[0].Name.contains('Abhinav'));
    }

    @IsTest
    public static void givenEmployeeIds_WhenBulkUpdateEmployees_ThenUpdated() {

        List<Employee__c> emps = [
            SELECT Id FROM Employee__c WHERE Group__c='A'
        ];

        Id newBlockId = [SELECT Id FROM Block__c WHERE Name='Block B' LIMIT 1].Id;

        SAS_Employee_Controller.bulkUpdateEmployees(
            new List<Id>{ emps[0].Id, emps[1].Id },
            newBlockId,
            'B'
        );

        for (Employee__c e : [
            SELECT Block__c, Group__c 
            FROM Employee__c 
            WHERE Id IN :emps
        ]) {
            System.assertEquals('B', e.Group__c);
            System.assertEquals(newBlockId, e.Block__c);
        }
    }

    @IsTest
    public static void givenGroupAndBlock_WhenGetAvailableSeats_ThenSeatsReturned() {

        Block__c block = [SELECT Id FROM Block__c LIMIT 1];

        Integer seats = SAS_Employee_Controller.getAvailableSeats('A', block.Id);

        System.assertNotEquals(null, seats);
    }
}