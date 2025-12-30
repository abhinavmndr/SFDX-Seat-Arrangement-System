@IsTest
public class SAS_Test_Cycle_Group_Scheduler {

    @IsTest
    static void givenScheduledJob_WhenExecuted_ThenCycleGroupsAreRotated() {

        // GIVEN
        Cycle__c c1 = new Cycle__c(Name = 'Cycle 1', Group__c = 'A');
        Cycle__c c2 = new Cycle__c(Name = 'Cycle 2', Group__c = 'B');

        Database.insert(new List<Cycle__c>{ c1, c2 },false);

        String cronExp = '0 0 0 1 1 ? 2050'; // valid future cron

        Test.startTest();
        System.schedule(
            'Cycle Group Rotation Job',
            cronExp,
            new CycleGroupScheduler()
        );
        Test.stopTest(); // scheduled job executes here

        List<Cycle__c> updatedCycles = [
            SELECT Group__c
            FROM Cycle__c
            ORDER BY CreatedDate
        ];

        System.assertEquals('B', updatedCycles[0].Group__c,
            'First cycle should receive last group');
        System.assertEquals('A', updatedCycles[1].Group__c,
            'Second cycle should receive first group');
    }
}