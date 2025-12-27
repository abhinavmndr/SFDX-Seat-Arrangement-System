public with sharing class SAS_Employee_Controller {
    @AuraEnabled(cacheable=true)
    public static Employee__c getLoggedInEmployeeId() {
        Id userId = UserInfo.getUserId();

        Employee__c emp = [
            SELECT Id, Block__c, Group__c 
            FROM Employee__c 
            WHERE User__c = :userId
            LIMIT 1
        ];

        return emp;
    }

    @AuraEnabled(cacheable=true)
    public static List<Employee__c> getEmployeesByGroup(String groupName) {
        if (String.isBlank(groupName)) {
            return new List<Employee__c>();
        }

        return [
            SELECT Id, Name, Email__c, Group__c, Block__r.Name
            FROM Employee__c
            WHERE Group__c = :groupName
        ];
    }

    @AuraEnabled()
    public static List<Employee__c> getEmployeesByTeam(String teamName) {
        if (String.isBlank(teamName)) {
            return new List<Employee__c>();
        }

        return [
            SELECT Id, Name, Email__c, Group__c, Block__r.Name
            FROM Employee__c
            WHERE Team__c = :teamName
        ];
    }

    @AuraEnabled()
    public static List<Employee__c> getEmployeesByName(String empName) {
        if (String.isBlank(empName)) {
            return new List<Employee__c>();
        }

        return [
            SELECT Id, Name, Email__c, Group__c, Block__r.Name
            FROM Employee__c
            WHERE Name LIKE :('%' + empName + '%')
        ];
    }


    @AuraEnabled(cacheable=true)
    public static Integer getAvailableSeats(String groupName, String blockId) {
       /* if (String.isBlank(groupName) || blockId == null) {
            return 0;
        }*/
        // Daily groups
        // Prepare input variables for Flow
        Map<String, Object> flowInputs = new Map<String, Object>();
        
        flowInputs.put('varBlockId',blockId );
        flowInputs.put('varGroupName',groupName );

        // Invoke the autolaunched Flow
        Flow.Interview.Get_Available_Seats flowInstance = new Flow.Interview.Get_Available_Seats(flowInputs);

        flowInstance.start();
        Decimal count = (Decimal)flowInstance.getVariableValue('varAvailableSeats');
        Integer intCount = (Integer)count;
        //System.assert(false,intCount );

        // Return output variable from Flow
		System.debug(intCount);
        return intCount;
        
    }

    @AuraEnabled
    public static void bulkUpdateEmployees(List<Id> employeeIds, Id blockId, String groupName) {
        List<Employee__c> toUpdate = new List<Employee__c>();

        for (Id empId : employeeIds) {
            Employee__c e = new Employee__c(
                Id = empId,
                Block__c = blockId,
                Group__c = groupName
            );
            toUpdate.add(e);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}