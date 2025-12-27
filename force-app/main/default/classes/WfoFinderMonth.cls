public with sharing class WfoFinderMonth {
    public static Map<String, Boolean> findWfoDaysForAMonth(String empId, Date inpDate){
		
        Map<String, Boolean> wfoDaysMap = new Map<String, Boolean>();

        Date todayDate = Date.today();
        Date todayDateWeekStartDate = todayDate.toStartOfWeek();
        //System.debug(todayDateWeekStartDate);

        Date weekStartDateOfTheCurrentMonth = inpDate.toStartOfMonth().toStartOfWeek();
        //System.debug(weekStartDateOfTheCurrentMonth);

        Integer daysBetween =  Math.abs(todayDateWeekStartDate.daysBetween(weekStartDateOfTheCurrentMonth));
        //System.debug(daysBetween);
        
        Integer noOfWeeksBetween = daysBetween/7;
        //System.debug('No of weeks between is ' + noOfWeeksBetween );

        Date monthStartDate = inpDate.toStartOfMonth();
        Integer year = monthStartDate.year();
        Integer month = monthStartDate.month();
        Integer numOfDays = Date.daysInMonth(year, month);
        Date startDate = monthStartDate;
        Date weekStartDate = weekStartDateOfTheCurrentMonth;
        
        Employee__c emp = [SELECT Id, Group__c FROM Employee__c WHERE Id = :empId];
        
        if(emp.Group__c == 'X' || emp.Group__c == 'Y' ){
            for(Integer i=0; i<numOfDays; i++){
                String nameOfTheDay = SAS_Day_Finder_Of_The_Week.getDayName(startDate);
                if(nameOfTheDay == 'Saturday' || nameOfTheDay == 'Sunday'){
                    wfoDaysMap.put(String.valueOf(startDate), false);
                }else{
                    wfoDaysMap.put(String.valueOf(startDate), true);
                }
                startDate += 1; 
            }
            //System.debug(wfoDaysMap);
            return wfoDaysMap;
        }else{
            Cycle__c cyc = [SELECT Id, Name, Current_Schedule__c FROM Cycle__c WHERE Group__c = :emp.Group__c];
            List<Cycle__c> cycList = [SELECT Id,Name,Current_Schedule__c FROM Cycle__c ORDER BY Name ASC];
            
            // create a list to store the names
            List<String> cycleNameList = new List<String>();
            for (Cycle__c c : cycList) {
                cycleNameList.add(c.Name);
            }
    
            Integer numOfCycles = cycList.size();
            Integer mod =  Math.mod((noOfWeeksBetween), numOfCycles);  
            Integer index = cycleNameList.indexOf(cyc.Name);
            
            Cycle__c currentCycle;
            if(inpDate < todayDate ){
                currentCycle = cycList[Math.mod((index - mod + numOfCycles), numOfCycles)];
            }else{
                currentCycle = cycList[Math.mod((index + mod), numOfCycles)];
            }
            index = cycleNameList.indexOf(currentCycle.Name);
            //System.debug('the index is '+ index);
    
            Set<String> wfoDays = new Set<String>(currentCycle.Current_Schedule__c.split(';'));
            //System.assert(false,weekDays);
    
            
            
            for(Integer i=0; i<numOfDays; i++){
    
                //System.debug('day' +i);
                String nameOfTheDay = SAS_Day_Finder_Of_The_Week.getDayName(startDate);
                //System.debug('The day is ' +nameOfTheDay);
                //System.debug('The date is ' +startDate);
                //System.debug('The start date of the week  is ' +weekStartDate);
                
                if(wfoDays.contains(nameOfTheDay)){
                    wfoDaysMap.put(String.valueOf(startDate), true);
                    //System.debug('Work from office on ' + nameOfTheDay);
                }else {
                    wfoDaysMap.put(String.valueOf(startDate), false);
                    //System.debug('Work from home on ' + nameOfTheDay);
                }
                startDate += 1;
                if(startDate > weekStartDate + 7){
                    index += 1;
                    weekStartDate += 7;
                    currentCycle = cycList[Math.mod((index), numOfCycles)];
                    //System.debug('The current cycle is ' + currentCycle);
                    wfoDays = new Set<String>(currentCycle.Current_Schedule__c.split(';'));
                }
                //System.debug(index);
      
            }
    
            return wfoDaysMap;
        }

        
    
    }

}