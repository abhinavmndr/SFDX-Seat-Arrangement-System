@IsTest
public class SAS_Test_Cycle_Validation {

    @IsTest
    static void givenValidCycleName_WhenInsert_ThenSucceeds() {

        Cycle__c c = new Cycle__c(
            Name = 'Cycle 1'
        );

        Database.SaveResult result = Database.insert(c, false); // safe insert

        System.assert(result.isSuccess(), 'Cycle with valid name should be inserted');
        System.assertNotEquals(null, c.Id, 'Id should be assigned');
    }

    @IsTest
    static void givenInvalidCycleName_WhenInsert_ThenFails() {

        Cycle__c c = new Cycle__c(
            Name = 'Cycle A'
        );

        Database.SaveResult result = Database.insert(c, false); // safe insert

        System.assert(!result.isSuccess(), 'Insert should fail due to validation rule');
        System.assert(result.getErrors()[0].getMessage().contains('Cycle'),'Validation error message expected');
    }
}