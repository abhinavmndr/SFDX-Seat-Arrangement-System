@IsTest
public with sharing class SAS_Test_Approval_Request_Controller {
    
    @testSetup
    public static void setupTestData() {

        Block__c block = new Block__c(
            Name = 'Test Block',
            Total_Seats__c = 20,
            Daily_Seats_Available__c = 10
        );
        Database.insert(block,false);
        
        Employee__c emp = new Employee__c(
            Name = 'Test Employee',
            Email__c = 'luffytaro0473@gmail.com'
        );
        Database.insert(emp,false);

        Request__c req = new Request__c(
            Status__c = 'Pending',
            Requester__c = emp.Id,
            Block__c = block.Id,
            Group__c = 'B',
            Type__c = 'Transfer Request'
        );
        Database.insert(req,false);

        Approval.ProcessSubmitRequest submitReq = new Approval.ProcessSubmitRequest();
        submitReq.setObjectId(req.Id);
        submitReq.setSubmitterId(UserInfo.getUserId());
        submitReq.setComments('Submitting request for approval from test');

        Approval.ProcessResult result = Approval.process(submitReq);
        System.assert(result.isSuccess(), 'Approval submission failed');
    }
    
    @IsTest
    static void givenRequestSubmittedForApproval_WhenGetApprovalRequestsByRecordId_ThenWorkItemsAreReturned() {

        Request__c reqRec = [SELECT Id FROM Request__c WITH SECURITY_ENFORCED LIMIT 1];

        List<ProcessInstanceWorkitem> workItems =
            SAS_Approval_Request_Controller.getApprovalRequestsByRecordId(reqRec.Id);

        System.assert(workItems.size() > 0);
        System.assertEquals(reqRec.Id, workItems[0].ProcessInstance.TargetObjectId);
    }
    
    @IsTest
    public static void givenPendingApprovalWorkItem_WhenApproved_ThenProcessInstanceIsApproved() {

        Request__c reqRec = [SELECT Id FROM Request__c WITH SECURITY_ENFORCED LIMIT 1];

        ProcessInstanceWorkitem workItem = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :reqRec.Id
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        SAS_Approval_Request_Controller.processApproval(workItem.Id, 'Approve');

        ProcessInstance procInst = [
            SELECT Status
            FROM ProcessInstance
            WHERE TargetObjectId = :reqRec.Id
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        System.assertEquals('Approved', procInst.Status);
    }
    
    @IsTest
    public static void givenPendingApprovalRequests_WhenGetApprovalRequests_ThenDTOsAreReturned() {

        Request__c req = [
            SELECT Id, Name, Status__c, Group__c, Type__c, Date_of_Request__c, Block__r.Name 
            FROM Request__c 
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    
        List<SAS_Approval_Request_Controller.ApprovalDTO> dtos =
            SAS_Approval_Request_Controller.getApprovalRequests('Pending');
    
        System.assertNotEquals(0, dtos.size());
    
        SAS_Approval_Request_Controller.ApprovalDTO dto = dtos[0];
    
        System.assertEquals(req.Id, dto.recordId);
        System.assertEquals(req.Name, dto.recordName);
        System.assertEquals('Pending', dto.status);
        System.assertNotEquals(null, dto.workItemId);
        System.assertNotEquals(null, dto.processInstanceId);
        System.assertNotEquals(null, dto.submittedBy);
    
        System.assertEquals(req.Date_of_Request__c, dto.dateOfRequest);
        System.assertEquals(req.Block__r.Name, dto.blockName);
        System.assertEquals(req.Group__c, dto.groupName);
        System.assertEquals(req.Type__c, dto.requestType);
    }
}