@IsTest
public class SAS_Test_Autolaunched_Request_Flow {

    @TestSetup
    static void setupTestData() {

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            CommunityNickname = 'testuser',
            TimeZoneSidKey = 'Asia/Kathmandu',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );

        Database.insert(new List<User>{u}, false);

        Employee__c emp = new Employee__c(
            Name = 'Test Employee',
            User__c = u.Id,
            Email__c = 'testemployee@example.com'
        );

        Database.insert(new List<Employee__c>{emp}, false);

        Block__c block = new Block__c(Name = 'Test Block', Total_Seats__c = 10);
        Database.insert(new List<Block__c>{block}, false);
    }

    @IsTest
    static void testFlowCreatesRequestAndSubmitsForApproval() {

        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Block__c block = [SELECT Id FROM Block__c LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'varBlockId'      => block.Id,
            'varGroupName'    => 'A',
            'varRequestType'  => 'Transfer Request',
            'varReason'       => 'Need seat urgently',
            'varRequesterId'  => emp.Id
        };

        Test.startTest();

        Flow.Interview.Submit_for_Approval_From_Autolaunched_Flow flow =
            new Flow.Interview.Submit_for_Approval_From_Autolaunched_Flow(inputs);

        flow.start();

        String createdRequestId = (String)flow.getVariableValue('varCreatedRequestId');

        Test.stopTest();

        Request__c req = [SELECT Id, Requester__c, Status__c, Group__c, Block__c
                          FROM Request__c WHERE Id = :createdRequestId];

        System.assertEquals(emp.Id, req.Requester__c, 'Requester should match Employee');
        System.assertEquals('A', req.Group__c, 'Group should match input');
        System.assertEquals(block.Id, req.Block__c, 'Block should match input');
        System.assertEquals('Pending', req.Status__c, 'Initial status should be Pending');

        List<ProcessInstance> approvals = [
            SELECT Id, TargetObjectId, Status
            FROM ProcessInstance
            WHERE TargetObjectId = :createdRequestId
        ];

        System.assert(!approvals.isEmpty(), 'Approval ProcessInstance should exist for the Request');
        System.assertEquals('Pending', approvals[0].Status, 'Approval process should be Pending');
    }
}