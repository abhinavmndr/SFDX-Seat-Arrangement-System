trigger SAS_Block_Trigger on Block__c (before update) {

    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            SAS_Block_Trigger_Handler.validateDailySeatsAvailable(Trigger.new, Trigger.oldMap);
        }   
    }
}