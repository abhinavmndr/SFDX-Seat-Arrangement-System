@IsTest
public class SAS_Test_GetAvailableSeats_Flow {
    
    @TestSetup
    public static void setupTestData() {

        Block__c blockA = new Block__c(
            Name = 'Block A',
            Total_Seats__c = 20,
            Daily_Seats_Available__c = 10
        );
        Block__c blockB = new Block__c(
            Name = 'Block B',
            Total_Seats__c = 15,
            Daily_Seats_Available__c = 5
        );

        Database.insert(new List<Block__c>{ blockA, blockB }, false);
    }

    @IsTest
    public static void givenValidBlockAndHybridGroup_WhenFlowRuns_ThenReturnsCorrectAvailableHybridSeats() {

        Block__c blockA = [SELECT Id FROM Block__c WHERE Name = 'Block A' WITH SECURITY_ENFORCED LIMIT 1];

        Map<String, Object> flowInputs = new Map<String, Object>{
            'varBlockId' => blockA.Id,
            'varGroupName' => 'A'
        };

        Flow.Interview.Get_Available_Seats flowInstance = new Flow.Interview.Get_Available_Seats(flowInputs);
        flowInstance.start();

        Decimal availableSeats = (Decimal)flowInstance.getVariableValue('varAvailableSeats');
        Integer intSeats = (Integer)availableSeats;

        System.assertEquals(10, intSeats, 'Flow should return correct available seats for Block A');
    }

    @IsTest
    public static void givenValidBlockAndDailyGroup_WhenFlowRuns_ThenReturnsCorrectAvailableDailySeats() {

        Block__c blockB = [SELECT Id FROM Block__c WHERE Name = 'Block B' WITH SECURITY_ENFORCED LIMIT 1];

        Map<String, Object> flowInputs = new Map<String, Object>{
            'varBlockId' => blockB.Id,
            'varGroupName' => 'X'
        };

        Flow.Interview.Get_Available_Seats flowInstance = new Flow.Interview.Get_Available_Seats(flowInputs);
        flowInstance.start();

        Decimal availableSeats = (Decimal)flowInstance.getVariableValue('varAvailableSeats');
        Integer intSeats = (Integer)availableSeats;

        System.assertEquals(5, intSeats, 'Flow should return 0 when groupName is blank');
    }
}