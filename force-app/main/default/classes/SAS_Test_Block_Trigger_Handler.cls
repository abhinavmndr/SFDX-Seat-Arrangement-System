@IsTest
public class SAS_Test_Block_Trigger_Handler {

    @TestSetup
    static void setupData() {

        // Create test Block
        Block__c block = new Block__c(
            Name = 'Test Block',
            Total_Seats__c = 8,
            Daily_Seats_Available__c = 5
        );
        Database.insert(block,false);

        // Create Employees in Hybrid Groups
        List<Employee__c> emps = new List<Employee__c>{
            new Employee__c(Name='Emp 1', Block__c=block.Id, Group__c='A'),
            new Employee__c(Name='Emp 2', Block__c=block.Id, Group__c='A'),
            new Employee__c(Name='Emp 3', Block__c=block.Id, Group__c='B')
        };
        Database.insert(emps,false);
    }
    
    @IsTest
    static void givenDailySeatsIncreasedWithinLimit_WhenValidateDailySeatsAvailable_ThenNoError() {

        Block__c block = [SELECT Id, Daily_Seats_Available__c FROM Block__c LIMIT 1];
        block.Daily_Seats_Available__c = 6;
       
        // Use Database.update with allOrNone=false
        Database.SaveResult result = Database.update(block, false);

        // Assert that the update succeeded
        System.assert(result.isSuccess(), 'Update should succeed since it is within limit');
        System.assertEquals(0, result.getErrors().size(), 'No errors should be returned');
    }

    @IsTest
    static void givenDailySeatsExceedsHybrid_WhenValidateDailySeatsAvailable_ThenErrorThrown() {

        Block__c block = [SELECT Id, Daily_Seats_Available__c FROM Block__c LIMIT 1];
        block.Daily_Seats_Available__c = 7;
        
        Database.SaveResult result = Database.update(block, false);

        // Assert that the update failed
        System.assert(!result.isSuccess(), 'Update should fail since it exceeds limit');
        System.assert(result.getErrors()[0].getMessage().contains(
            'seats are already occupied in this block by Hybrid Groups. Cannot increase Daily Seats Available above'
        ), 'Validation error message should match expected');
    }
}