@IsTest
public class SAS_Test_Cycle_Trigger_Handler {

    @TestSetup
    static void setupTestData() {
        Cycle__c existingCycle = new Cycle__c(
            Name = 'Cycle 1',
            Current_Schedule__c = 'Monday;Tuesday',
            Group__c = 'A'
        );
        Database.insert(existingCycle, false);
    }

    @IsTest
    static void givenNewCycle_WhenInsertWithoutConflictingWeekday_ThenInsertSucceeds() {
        Cycle__c newCycle = new Cycle__c(
            Name = 'Cycle 3',
            Current_Schedule__c = 'Wednesday;Thursday'
        );

        Database.SaveResult result = Database.insert(newCycle, false);

        System.assert(result.isSuccess(), 'Cycle should be inserted successfully');
        System.assertNotEquals(null, newCycle.Id, 'Id should be assigned');
    }

    @IsTest
    static void givenNewCycle_WhenInsertWithConflictingWeekday_ThenErrorThrown() {
        Cycle__c conflictingCycle = new Cycle__c(
            Name = 'Cycle 4',
            Current_Schedule__c = 'Monday'
        );

        Database.SaveResult result = Database.insert(conflictingCycle, false);

        System.assert(!result.isSuccess(), 'Insert should fail due to weekday conflict');
        System.assert(
            result.getErrors()[0].getMessage().contains('already assigned to another Cycle'),
            'Expected conflict error message missing'
        );
    }

    @IsTest
    static void givenCycle_WhenUpdateWithoutConflictingWeekday_ThenUpdateSucceeds() {
        Cycle__c cycleToUpdate = [SELECT Id, Current_Schedule__c FROM Cycle__c LIMIT 1];
        cycleToUpdate.Current_Schedule__c = 'Friday';

        Database.SaveResult result = Database.update(cycleToUpdate, false);

        System.assert(result.isSuccess(), 'Update should succeed');
        System.assertEquals(0, result.getErrors().size(), 'No errors expected');

        Cycle__c updated = [SELECT Current_Schedule__c FROM Cycle__c WHERE Id = :cycleToUpdate.Id];
        System.assertEquals('Friday', updated.Current_Schedule__c, 'Schedule should update successfully');
    }

    @IsTest
    static void givenCycle_WhenUpdateWithConflictingWeekday_ThenErrorThrown() {
        Cycle__c cyc2 = new Cycle__c(
            Name = 'Cycle 2'
        );
        Database.insert(cyc2, false);

        cyc2.Current_Schedule__c = 'Monday'; 

        Database.SaveResult result = Database.update(cyc2, false);

        System.assert(!result.isSuccess(), 'Update should fail due to weekday conflict');
        System.assert(
            result.getErrors()[0].getMessage().contains('already assigned to another Cycle'),
            'Expected conflict error message missing'
        );
    }
    
    @IsTest
    static void givenNewCycleWithUniqueGroup_whenValidateGroups_thenInsertSucceeds() {
        Cycle__c newCycle = new Cycle__c(
            Name = 'Cycle 5',
            Group__c = 'B'
        );

        Database.SaveResult sr = Database.insert(newCycle, false);

        System.assert(sr.isSuccess(), 'Cycle insert should succeed');
    }

    @IsTest
    static void givenNewCycleWithExistingGroup_whenValidateGroups_thenErrorReturned() {
        Cycle__c newCycle = new Cycle__c(
            Name = 'Cycle 6',
            Group__c = 'A'
        );

        Database.SaveResult sr = Database.insert(newCycle, false);

        System.assert(!sr.isSuccess(), 'Insert should fail due to group conflict');
        System.assert(
            sr.getErrors()[0].getMessage().contains('This Group is already assigned to another Cycle'),
            'Expected group conflict error message'
        );
    }

    @IsTest
    static void givenExistingCycleUpdateWithUniqueGroup_whenValidateGroups_thenUpdateSucceeds() {
        Cycle__c cyc2 = new Cycle__c(
            Name = 'Cycle 2'
        );
        Database.insert(cyc2, false);

        cyc2.Group__c = 'B'; 

        Database.SaveResult sr = Database.update(cyc2, false);
        System.assert(sr.isSuccess(), 'Update should succeed with unique group');
    }

    @IsTest
    static void givenExistingCycleUpdateWithExistingGroup_whenValidateGroups_thenErrorReturned() {
        Cycle__c cyc2 = new Cycle__c(
            Name = 'Cycle 2'
        );
        Database.insert(cyc2, false);

        cyc2.Group__c = 'A'; 

        Database.SaveResult sr = Database.update(cyc2, false);

        System.assert(!sr.isSuccess(), 'Update should fail due to group conflict');
        System.assert(
            sr.getErrors()[0].getMessage().contains('This Group is already assigned to another Cycle'),
            'Expected group conflict error message'
        );
    }
}