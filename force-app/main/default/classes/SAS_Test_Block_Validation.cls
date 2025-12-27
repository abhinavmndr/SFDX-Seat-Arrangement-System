@IsTest
public class SAS_Test_Block_Validation {


    @IsTest
    static void whenDailySeatsGreaterThanTotal_onInsert_thenValidationFails() {

        Block__c block = new Block__c(
            Name = 'Insert Fail Block',
            Total_Seats__c = 10,
            Daily_Seats_Available__c = 15
        );

        Database.SaveResult result = Database.insert(block, false);

        System.assert(!result.isSuccess(), 'Insert should fail due to validation rule');
        System.assert(result.getErrors()[0].getMessage().contains('Daily Seats Available'),'Expected validation message missing');
    }


    @IsTest
    static void whenDailySeatsGreaterThanTotal_onUpdate_thenValidationFails() {

        // Step 1: Insert a VALID record
        Block__c block = new Block__c(
            Name = 'Update Fail Block',
            Total_Seats__c = 10,
            Daily_Seats_Available__c = 5
        );
        Database.insert(block,false);
        
        Employee__c emp = new Employee__c(
        	Name = 'test emp',
            Group__c = 'A',
            Block__c = block.Id
        );
        Database.insert(emp,false);

        // Step 2: Update to INVALID value
        block.Daily_Seats_Available__c = 20;

        Database.SaveResult result = Database.update(block, false);

        System.assert(!result.isSuccess(), 'Update should fail due to validation rule');
        System.assert(result.getErrors()[0].getMessage().contains('Daily Seats Available'),'Expected validation message missing');
    }


    @IsTest
    static void whenDailySeatsLessOrEqual_onUpdate_thenSucceeds() {

        Block__c block = new Block__c(
            Name = 'Update Success Block',
            Total_Seats__c = 10,
            Daily_Seats_Available__c = 5
        );
        Database.insert(block,false);
        
        Employee__c emp = new Employee__c(
        	Name = 'test emp',
            Group__c = 'A',
            Block__c = block.Id
        );
        Database.insert(emp,false);

        block.Daily_Seats_Available__c = 9;

        Database.SaveResult result = Database.update(block, false);

        System.assert(result.isSuccess(), 'Update should succeed');
        System.assertEquals(0, result.getErrors().size(), 'No errors expected');

        Block__c updatedBlock = [
            SELECT Daily_Seats_Available__c
            FROM Block__c
            WHERE Id = :block.Id
        ];
        System.assertEquals(9, updatedBlock.Daily_Seats_Available__c, 'Daily Seats Available should be updated');
    }
}