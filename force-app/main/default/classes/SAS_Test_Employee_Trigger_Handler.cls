@isTest
public class SAS_Test_Employee_Trigger_Handler {

    @testSetup
    public static void setupData() {

        // Create Block
        Block__c block1 = new Block__c(
            Name = 'Block A',
            Total_Seats__c = 15,
            Daily_Seats_Available__c = 2,
            Daily_Occupied_Seats__c = 0
        );
        
        Block__c block2 = new Block__c(
            Name = 'Block B',
            Total_Seats__c = 15,
            Daily_Seats_Available__c = 14,
            Daily_Occupied_Seats__c = 0
        );
        
        List<Block__c> blocks = new List<Block__c>{block1, block2};
		Database.insert(blocks,false);
            
        // Create Team
        Team__c team1 = new Team__c(Name = 'Team A');
        Team__c team2 = new Team__c(Name = 'Team B');
        List<Team__c> teams = new List<Team__c>{team1, team2};
		Database.insert(teams,false);

        // Create Employees
        List<Employee__c> employees = new List<Employee__c>();
        
        Employee__c empX1 = new Employee__c(
            Name = 'Emp X1',
            Block__c = block1.Id,
            Group__c = 'X',
            Team__c = team1.Id
        );
        employees.add(empX1);
        
        Employee__c empY1 = new Employee__c(
            Name = 'Emp Y1',
            Block__c = block1.Id,
            Group__c = 'Y',
            Team__c = team1.Id
        );
        employees.add(empY1);
        
        Database.insert(employees, false);

    }

    @IsTest
    public static void givenEmployeesInXYGroups_WhenRecalculateDailyOccupiedSeats_ThenBlockIsUpdated() {

        List<Block__c> blocks = [SELECT Daily_Occupied_Seats__c FROM Block__c WITH SECURITY_ENFORCED ORDER BY Name];
        System.assertEquals(2,blocks[0].Daily_Occupied_Seats__c,'Occupied seats should match X + Y employees');
        
        Employee__c emp = [SELECT Id, Name, Block__c FROM Employee__c LIMIT 1];
        emp.Block__c = blocks[1].id;
        update emp;
        
        Block__c b = [SELECT Daily_Occupied_Seats__c FROM Block__c WHERE Id = :blocks[1].id WITH SECURITY_ENFORCED];
        System.assertEquals(1,b.Daily_Occupied_Seats__c,'Occupied seats should match X + Y employees');
    }

  
    @IsTest
    public static void givenExceededDailySeats_WhenValidateDailyOccupiedSeats_ThenErrorIsThrown() {

        Block__c block = [SELECT Id FROM Block__c WITH SECURITY_ENFORCED LIMIT 1];

        Employee__c emp = new Employee__c(
            Name = 'Emp Overflow',
            Block__c = block.Id,
            Group__c = 'X'
        );

  		Database.SaveResult sr = Database.insert(emp, false);
        System.assert(!sr.isSuccess(), 'Insert should fail due to daily seats exceeded');
        System.assert(sr.getErrors()[0].getMessage().contains('Daily Seats Occupied cannot be greater'), 'Correct validation error expected');
        
    }

    @IsTest
    public static void givenExceededHybridSeats_WhenValidateHybridSeats_ThenErrorIsThrown() {

        Block__c block = [SELECT Id FROM Block__c WHERE Name = 'Block B' WITH SECURITY_ENFORCED];

        Database.insert(new Employee__c(Name = 'Hybrid 1', Block__c = block.Id, Group__c = 'A'), false);

        Employee__c emp = new Employee__c(Name = 'Hybrid 2', Block__c = block.Id, Group__c = 'A');

        Database.SaveResult sr = Database.insert(emp, false);
        System.assert(!sr.isSuccess(), 'Insert should fail due to hybrid seat limit');
        System.assert(sr.getErrors()[0].getMessage().contains('No hybrid seats available'), 'Correct hybrid seat error expected');

    }

    @IsTest
    public static void givenEmployees_WhenUpdateTeamEmployeeCount_ThenTeamCountIsCorrect() {

        List<Team__c> updatedTeams = [SELECT Number_Of_Employees__c FROM Team__c WITH SECURITY_ENFORCED ORDER BY Name];
        System.assertEquals(2,updatedTeams[0].Number_Of_Employees__c,'Team employee count should match aggregate');
        
        Employee__c emp = [SELECT Id, Team__c FROM Employee__c WHERE Name = 'Emp Y1' WITH SECURITY_ENFORCED];
        emp.Team__c = updatedTeams[1].Id;

        Database.SaveResult sr = Database.update(emp, false);
        System.assert(sr.isSuccess(), 'Employee update should succeed');
        
        Team__c t = [SELECT Number_Of_Employees__c FROM Team__c WHERE Id = :updatedTeams[1].Id WITH SECURITY_ENFORCED];
        System.assertEquals(1,t.Number_Of_Employees__c,'Team employee count should match aggregate');

    }
    
}