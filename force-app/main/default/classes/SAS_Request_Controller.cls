public with sharing class SAS_Request_Controller {

    @AuraEnabled(cacheable=true)
    public static List<Request__c> getMyRequests() {

        // Step 1: Get Employee for logged-in user
        Employee__c emp = [
            SELECT Id
            FROM Employee__c
            WHERE User__c = :UserInfo.getUserId()
            LIMIT 1
        ];

        // Step 2: Get Requests linked to that Employee
        return [
            SELECT Id, Name, Status__c, CreatedDate
            FROM Request__c
            WHERE 	Requester__c = :emp.Id
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static String createRequest(String requestType, String blockId, String groupName, String reason, String empId) {

        Map<String, Object> inputs = new Map<String, Object>{
            'varBlockId'      => blockId,
            'varGroupName'    => groupName,
            'varRequestType'  => requestType,
            'varReason'  => reason,
            'varRequesterId'  => empId
        };

        Flow.Interview.Submit_for_Approval_From_Autolaunched_Flow flow = new Flow.Interview.Submit_for_Approval_From_Autolaunched_Flow(inputs);

        flow.start();

        String requestId = (String)flow.getVariableValue('varCreatedRequestId');
       // System.assert(false, requestId);
        return requestId;
    }
}