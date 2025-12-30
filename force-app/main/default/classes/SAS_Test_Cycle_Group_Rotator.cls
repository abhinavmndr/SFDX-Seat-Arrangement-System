@IsTest
public class SAS_Test_Cycle_Group_Rotator {

    @IsTest
    public static void givenMultipleCycles_WhenRotateGroups_ThenGroupsAreRotated() {

        Cycle__c c1 = new Cycle__c(Name = 'Cycle 1', Group__c = 'A');
        Cycle__c c2 = new Cycle__c(Name = 'Cycle 2', Group__c = 'B');
        
        Database.insert(new List<Cycle__c>{ c1, c2 },false);

        CycleGroupRotator.rotateGroups();

        List<Cycle__c> updatedCycles = [SELECT Name, Group__c FROM Cycle__c ORDER BY CreatedDate];

        System.assertEquals('B', updatedCycles[0].Group__c);
        System.assertEquals('A', updatedCycles[1].Group__c);
    }

    @IsTest
    static void givenSingleCycle_WhenRotateGroups_ThenNoChangeOccurs() {

        Cycle__c c = new Cycle__c(Name = 'Cycle 1', Group__c = 'A');
        Database.insert(c, false);

        Test.startTest();
        CycleGroupRotator.rotateGroups();
        Test.stopTest();

        Cycle__c updated = [SELECT Group__c FROM Cycle__c WHERE Id = :c.Id];

        System.assertEquals('A', updated.Group__c);
    }
}