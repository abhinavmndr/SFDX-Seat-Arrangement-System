@IsTest
public class SAS_Test_Block_Controller {

    @testSetup
    static void setupTestData() {

        // Create Blocks
        Block__c blockA = new Block__c(
            Name = 'Block A',
            Location__c = 'Bakhundole',
            Total_Seats__c = 100,
            Daily_Seats_Available__c = 60,
            Daily_Occupied_Seats__c = 0
        );

        Block__c blockB = new Block__c(
            Name = 'Block B',
            Location__c = 'Jwagal',
            Total_Seats__c = 80,
            Daily_Seats_Available__c = 80,
            Daily_Occupied_Seats__c = 5
        );

        Database.insert(new List<Block__c>{ blockA, blockB },false);

        // Create Employees
        List<Employee__c> emps = new List<Employee__c>{
            new Employee__c(Name='Emp 1', Block__c=blockA.Id, Group__c='A'),
            new Employee__c(Name='Emp 2', Block__c=blockA.Id, Group__c='A'),
            new Employee__c(Name='Emp 3', Block__c=blockA.Id, Group__c='B'),
            new Employee__c(Name='Emp 4', Block__c=blockA.Id, Group__c='X'), 
            new Employee__c(Name='Emp 5', Block__c=blockB.Id, Group__c='X')
        };

        Database.insert(emps,false);
    }

    @IsTest
    static void givenBlocksAndEmployees_WhenGetBlockSummaries_ThenSummariesReturned() {

        List<SAS_Block_Controller.BlockSummaryWrapper> summaries =
            SAS_Block_Controller.getBlockSummaries();

        System.assertNotEquals(null, summaries, 'Summaries should not be null');
        System.assertEquals(2, summaries.size(), 'Two blocks should be returned');

        // Validate Block A
        SAS_Block_Controller.BlockSummaryWrapper blockA;
        for (SAS_Block_Controller.BlockSummaryWrapper w : summaries) {
            if (w.blockName == 'Block A') {
                blockA = w;
                break;
            }
        }
        
        // Validate Block B 
        SAS_Block_Controller.BlockSummaryWrapper blockB;
        for (SAS_Block_Controller.BlockSummaryWrapper w : summaries) {
            if (w.blockName == 'Block B') {
                blockB = w;
                break;
            }
        }

        System.assertNotEquals(null, blockA, 'Block A summary should exist');
        System.assertNotEquals(null, blockB, 'Block B summary should exist');
        System.assertEquals('Bakhundole', blockA.location);
        System.assertEquals(59, blockA.dailyAvailable, 'Daily available seats incorrect');

        // Hybrid logic checks
        System.assertEquals(38, blockA.groupCounts.get('A'),
            'Hybrid seats for Group A should be 40 - 2 = 38');
        System.assertEquals(39, blockA.groupCounts.get('B'),
            'Hybrid seats for Group B should be 40 - 1 = 39');

        // Excluded groups
        System.assertEquals(false, blockA.groupCounts.containsKey('X'));
        System.assertEquals(false, blockA.groupCounts.containsKey('Y'));
        
        System.assertEquals(0,blockB.groupCounts.get('B'),'Non-hybrid block should return raw employee count');
    }	

    @IsTest
    static void givenBlocksExist_WhenGetBlocks_ThenBlocksReturnedInOrder() {

        List<Block__c> blocks = SAS_Block_Controller.getBlocks();

        System.assertEquals(2, blocks.size(), 'Should return 2 blocks');
        System.assertEquals('Block A', blocks[0].Name);
        System.assertEquals('Block B', blocks[1].Name);
    }
}