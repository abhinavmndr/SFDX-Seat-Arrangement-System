public with sharing class SAS_Approval_Request_Controller {
    
    @AuraEnabled(cacheable=true)
    public static List<ProcessInstanceWorkitem> getApprovalRequestsByRecordId(String recordId) {
        return[ SELECT Id, 
                        ProcessInstance.TargetObjectId,
                        ProcessInstance.Status
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :recordId];
    }


    @AuraEnabled(cacheable=true)
    public static List<ApprovalDTO> getApprovalRequests(String status) {

        List<ApprovalDTO> results = new List<ApprovalDTO>();

        // Step 1: Query ProcessInstance records
        List<ProcessInstance> instances = [
            SELECT Id,
                   Status,
                   CreatedDate,
                   TargetObjectId,
                   TargetObject.Name,
                   SubmittedBy.Name,
                   (SELECT Id FROM Workitems)
            FROM ProcessInstance
            WHERE TargetObject.Type = 'Request__c'
              AND Status = :status
            ORDER BY CreatedDate DESC
        ];

        // Step 2: Collect TargetObjectIds
        Set<Id> recordIds = new Set<Id>();
        for (ProcessInstance pi : instances) {
            recordIds.add(pi.TargetObjectId);
        }

        // Step 3: Query Request__c with Request Type included
        Map<Id, Request__c> requestsMap = new Map<Id, Request__c>(
            [
                SELECT Id,
                       Date_of_Request__c,
                       Block__r.Name,
                       Group__c,
                       Type__c
                FROM Request__c
                WHERE Id IN :recordIds
            ]
        );

        // Step 4: Build DTO list
        for (ProcessInstance pi : instances) {

            Id workItemId = null;
            if (!pi.Workitems.isEmpty()) {
                workItemId = pi.Workitems[0].Id;
            }

            Request__c req = requestsMap.get(pi.TargetObjectId);

            results.add(new ApprovalDTO(
                pi.Id,
                pi.TargetObjectId,
                pi.TargetObject.Name,
                pi.Status,
                pi.SubmittedBy.Name,
                workItemId,
                req != null ? req.Date_of_Request__c : null,
                req != null && req.Block__r != null ? req.Block__r.Name : null,
                req != null ? req.Group__c : null,
                req != null ? req.Type__c : null
            ));
        }

        return results;
    }

    @AuraEnabled
    public static void processApproval(Id workItemId, String action) {
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(workItemId);
        req.setAction(action); // Approve / Reject
        Approval.process(req);
    }

    // DTO
    public class ApprovalDTO {
        @AuraEnabled public Id processInstanceId;
        @AuraEnabled public Id recordId;
        @AuraEnabled public String recordName;
        @AuraEnabled public String status;
        @AuraEnabled public String submittedBy;
        @AuraEnabled public Id workItemId;
        @AuraEnabled public Date dateOfRequest;
        @AuraEnabled public String blockName;
        @AuraEnabled public String groupName;
        @AuraEnabled public String requestType; // ✅ NEW FIELD

        public ApprovalDTO(
            Id piId,
            Id rId,
            String rName,
            String st,
            String sub,
            Id wiId,
            Date dor,
            String bName,
            String gName,
            String rType
        ) {
            processInstanceId = piId;
            recordId = rId;
            recordName = rName;
            status = st;
            submittedBy = sub;
            workItemId = wiId;
            dateOfRequest = dor;
            blockName = bName;
            groupName = gName;
            requestType = rType;
        }
    }
}