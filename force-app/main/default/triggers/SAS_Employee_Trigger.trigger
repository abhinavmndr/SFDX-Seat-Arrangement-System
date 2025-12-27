trigger SAS_Employee_Trigger on Employee__c (before insert, after insert, after update) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
			SAS_Employee_Trigger_Handler.recalculateDailyOccupiedSeats(Trigger.new, null);   
            SAS_Employee_Trigger_Handler.validateDailyOccupiedSeats(Trigger.new);
            SAS_Employee_Trigger_Handler.validateHybridSeats(Trigger.new);  
            SAS_Employee_Trigger_Handler.updateTeamEmployeeCount(Trigger.new,null);   
        }
        if(Trigger.isUpdate){
            SAS_Employee_Trigger_Handler.recalculateDailyOccupiedSeats(Trigger.new, Trigger.oldMap);
            SAS_Employee_Trigger_Handler.validateDailyOccupiedSeats(Trigger.new);   
            SAS_Employee_Trigger_Handler.validateHybridSeats(Trigger.new);
            SAS_Employee_Trigger_Handler.updateTeamEmployeeCount(Trigger.new,Trigger.oldMap);     
        }
        
    }
}