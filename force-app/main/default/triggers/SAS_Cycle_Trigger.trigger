trigger SAS_Cycle_Trigger on Cycle__c (before insert, before update) {
    
    if(Trigger.isBefore ){
        if(Trigger.isInsert){
            SAS_Cycle_Trigger_Handler.validateSchedules(Trigger.new, null);
        }
        if(Trigger.isUpdate){
            SAS_Cycle_Trigger_Handler.validateSchedules(Trigger.new, Trigger.oldMap);
        }
    }
}