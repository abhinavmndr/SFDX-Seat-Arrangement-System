public class WfoFinder {
    public static void isWFO(String empId, Date d){
        
        String day = SAS_Day_Finder_Of_The_Week.getDayName(d);
        //Set<String> weekDays = new Set<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'};
        Date myDate = Date.today();
        Date weekStart = myDate.toStartofWeek();
        System.debug(weekStart);
       
        //Date myDate2 = Date.newInstance(2025, 11, 25);
        Date weekStart2 = d.toStartofWeek();
        System.debug(weekStart2);
        
        Integer daysBetween =  Math.abs(weekStart.daysBetween(weekStart2));
        System.debug(daysBetween);
        
        Integer noOfWeeksBetween = daysBetween/7;
        System.debug('No of weeks between is ' + noOfWeeksBetween );
        
        Employee__c emp = [SELECT Id, Group__c FROM Employee__c WHERE Id = :empId];
        if(emp.Group__c == 'X' || emp.Group__c == 'Y' ){
            System.debug('Always work from office');
            return;
        }
        Cycle__c cyc = [SELECT Id, Name, Current_Schedule__c FROM Cycle__c WHERE Group__c = :emp.Group__c];
        List<Cycle__c> cycList = [SELECT Id,Name,Current_Schedule__c FROM Cycle__c ORDER BY Name ASC];
        // create a list to store the names
        List<String> nameList = new List<String>();
        for (Cycle__c c : cycList) {
            nameList.add(c.Name);
        }
        //System.assert(false,nameList);
        Integer numOfCycles = [SELECT COUNT() FROM Cycle__c];
        List<String> cycNames = cyc.Current_Schedule__c.split(';');
        Integer mod =  Math.mod((noOfWeeksBetween), numOfCycles);  
        Integer index = nameList.indexOf(cyc.Name);
        Cycle__c c;
        if(d < myDate ){
            c = cycList[Math.mod((index - mod + numOfCycles), numOfCycles)];
        }else{
            c = cycList[Math.mod((index + mod), numOfCycles)];
        }
        //Cycle__c c = cycList[Math.mod((index + mod), numOfCycles)];
        //System.assert(false,c.Name);
        
        Set<String> weekDays = new Set<String>(c.Current_Schedule__c.split(';'));
        //System.assert(false,weekDays);
        if(weekDays.contains(day)){
            System.debug('Work from office day');
        }       
    }

    public static void isWfoWeek(String empId, Date d){

        String day = SAS_Day_Finder_Of_The_Week.getDayName(d);
        Date myDate = Date.today();
        Date weekStart = myDate.toStartofWeek();
        System.debug(weekStart);

        Date weekStart2 = d.toStartofWeek();
        System.debug(weekStart2);

         Integer daysBetween =  Math.abs(weekStart.daysBetween(weekStart2));
        System.debug(daysBetween);
        
        Integer noOfWeeksBetween = daysBetween/7;
        System.debug('No of weeks between is ' + noOfWeeksBetween );

        Employee__c emp = [SELECT Id, Group__c FROM Employee__c WHERE Id = :empId];
        if(emp.Group__c == 'X' || emp.Group__c == 'Y' ){
            System.debug('Always work from office');
            return;
        }

        Cycle__c cyc = [SELECT Id, Name, Current_Schedule__c FROM Cycle__c WHERE Group__c = :emp.Group__c];
        List<Cycle__c> cycList = [SELECT Id,Name,Current_Schedule__c FROM Cycle__c ORDER BY Name ASC];
        // create a list to store the names
        List<String> nameList = new List<String>();
        for (Cycle__c c : cycList) {
            nameList.add(c.Name);
        }

        //System.assert(false,nameList);
        Integer numOfCycles = [SELECT COUNT() FROM Cycle__c];
        List<String> cycNames = cyc.Current_Schedule__c.split(';');
        Integer mod =  Math.mod((noOfWeeksBetween), numOfCycles);  
        Integer index = nameList.indexOf(cyc.Name);
        Cycle__c c;
        if(d < myDate ){
            c = cycList[Math.mod((index - mod + numOfCycles), numOfCycles)];
        }else{
            c = cycList[Math.mod((index + mod), numOfCycles)];
        }

        Set<String> weekDays = new Set<String>(c.Current_Schedule__c.split(';'));
        //System.assert(false,weekDays);
        
        
        Date monthStart  = d.toStartOfMonth();
        Integer year = monthStart.year();
        Integer month = monthStart.month();
        Integer numOfDays = Date.daysInMonth(year, month);
        for(Integer i=0; i<numOfDays; i++){
            String dName = SAS_Day_Finder_Of_The_Week.getDayName(monthStart);
            if(weekDays.contains(dName)){
                System.debug(' Work from office on ' + dName);
            }
            monthStart = monthStart + 1;
        }
    }
}