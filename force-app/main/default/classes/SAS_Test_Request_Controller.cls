@IsTest
public class SAS_Test_Request_Controller {

    @TestSetup
    static void setupData() {

        // Create Employee linked to User
        Employee__c emp = new Employee__c(
            Name = 'Test Employee',
            User__c = UserInfo.getUserId()
        );
        Database.insert(emp, false);

        // Create Requests for that employee
        List<Request__c> requests = new List<Request__c>{
            new Request__c(
                Requester__c = emp.Id,
                Status__c = 'Pending'
            ),
            new Request__c(
                Requester__c = emp.Id,
                Status__c = 'Rejected'
            )
        };
        Database.insert(requests, false);
    }

    @IsTest
    static void givenLoggedInEmployee_WhenGetMyRequests_ThenRequestsReturned() {

        List<Request__c> result = SAS_Request_Controller.getMyRequests();
        System.assertEquals(2, result.size(), 'Employee should see only their requests');
    }

    // -------------------------
    // createRequest()
    // -------------------------
    @IsTest
    static void givenValidInputs_WhenCreateRequest_ThenRequestIdReturned() {

        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];

        Block__c block = new Block__c(
            Name = 'Test Block'
        );
        Database.insert(block, false);

        String requestId = SAS_Request_Controller.createRequest(
            'Transfer Request',
            block.Id,
            'A',
            'Need seat urgently',
            emp.Id
        );

        System.assertNotEquals(null, requestId, 'Flow should return created Request Id');
    }
}