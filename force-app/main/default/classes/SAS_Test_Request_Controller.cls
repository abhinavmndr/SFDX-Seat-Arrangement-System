@IsTest
public class SAS_Test_Request_Controller {

    @TestSetup
    public static void setupData() {

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' WITH SECURITY_ENFORCED LIMIT 1];

        User empUser = new User(
            Alias = 'empuser',
            Email = 'employeeuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Employee',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'employeeuser' + DateTime.now().getTime() + '@example.com'
        );
        Database.insert(empUser, false);
        
        // Create Employee linked to User
        Employee__c emp = new Employee__c(
            Name = 'Test Employee',
            User__c = empUser.Id
        );
        Database.insert(emp, true);

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
    public static void givenLoggedInEmployee_WhenGetMyRequests_ThenRequestsReturned() {

        User u = [SELECT Id FROM User WHERE LastName='Employee' WITH SECURITY_ENFORCED LIMIT 1];
        System.runAs(u) {
            List<Request__c> result = SAS_Request_Controller.getMyRequests(); 
            System.assertEquals(2, result.size(), 'Employee should see only their requests');
        }
        
    }

    @IsTest
    public static void givenValidInputs_WhenCreateRequest_ThenRequestIdReturned() {

        Employee__c emp = [SELECT Id FROM Employee__c WITH SECURITY_ENFORCED LIMIT 1];

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