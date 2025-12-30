@IsTest
public class SAS_Test_Request_Status_Flows {

    @TestSetup
    static void setupData() {

        Block__c oldBlock = new Block__c(Name = 'Old Block', Total_Seats__c = 10);
        Block__c newBlock = new Block__c(Name = 'New Block', Total_Seats__c = 10);
        Database.insert(new List<Block__c>{ oldBlock, newBlock }, false);

        Employee__c emp = new Employee__c(
            Name = 'Test Employee',
            Email__c = 'luffytaro0473@gmail.com',
            Group__c = 'A',
            Block__c = oldBlock.Id
        );
        Database.insert(emp, false);
        
        Request__c req1 = new Request__c(
            Requester__c = emp.Id,
            Status__c = 'Pending'
        );        
        Request__c req2 = new Request__c(
            Requester__c = emp.Id,
            Status__c = 'Pending',
            Group__c = 'B',
            Block__c = newBlock.Id
        );
        Database.insert(new List<Request__c>{ req1, req2 }, false);

    }

    @IsTest
    static void givenRequest_WhenStatusChangedToRejected_ThenFlowRuns() {

        Request__c req = [
            SELECT Id, Status__c
            FROM Request__c
            LIMIT 1
        ];

        Test.startTest();

        req.Status__c = 'Rejected';
        Database.update(req, false);

        Test.stopTest();

        Request__c updatedReq = [SELECT Status__c FROM Request__c WHERE Id = :req.Id];
        System.assertEquals('Rejected', updatedReq.Status__c, 'Request status should be updated to Rejected');
    }

    @IsTest
    static void givenRequest_WhenStatusChangedToApproved_ThenEmployeeUpdated() {

        Request__c req = [
            SELECT Id, Status__c, Group__c, Block__c, Requester__c
            FROM Request__c
            WHERE Group__c != NULL
            LIMIT 1
        ];

        Test.startTest();

        req.Status__c = 'Approved';
        Database.update(req, false);

        Test.stopTest();

        Employee__c updatedEmp = [
            SELECT Group__c, Block__c
            FROM Employee__c
            WHERE Id = :req.Requester__c
        ];

        System.assertEquals(req.Group__c, updatedEmp.Group__c,
            'Employee Group should be updated from request');

        System.assertEquals(req.Block__c, updatedEmp.Block__c,
            'Employee Block should be updated from request');

        Request__c updatedReq = [SELECT Status__c FROM Request__c WHERE Id = :req.Id];
        System.assertEquals('Approved', updatedReq.Status__c, 'Request status should be Approved');
    }
}