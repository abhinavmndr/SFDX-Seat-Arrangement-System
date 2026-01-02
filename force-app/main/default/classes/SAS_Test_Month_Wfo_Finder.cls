@IsTest
public class SAS_Test_Month_Wfo_Finder {

    @testSetup
    public static void setupData() {

        // Create Cycles
        List<Cycle__c> cycles = new List<Cycle__c>{
            new Cycle__c(
                Name = 'Cycle 1',
                Group__c = 'A',
                Current_Schedule__c = 'Monday;Wednesday;Friday'
            ),
            new Cycle__c(
                Name = 'Cycle 2',
                Group__c = 'B',
                Current_Schedule__c = 'Tuesday;Thursday'
            )
        };
        Database.insert(cycles, false);

        // Employees
        List<Employee__c> employees = new List<Employee__c>{
            new Employee__c(
                Name = 'Emp X',
                Group__c = 'X'
            ),
            new Employee__c(
                Name = 'Emp A',
                Group__c = 'A'
            )
        };
        Database.insert(employees, false);
    }
    
    @IsTest
    public static void givenHybridEmployee_WhenCheckingSpecificDate_ThenValueIsTrue() {
    
        Employee__c emp = [SELECT Id FROM Employee__c WHERE Group__c = 'A' WITH SECURITY_ENFORCED LIMIT 1];
    
        // Pick a known month
        Date inputMonth = Date.newInstance(2025, 12, 1);
    
        Map<String, Boolean> result = SAS_Month_Wfo_Finder.findWfoDaysForAMonth(emp.Id, inputMonth);
    
        // Pick a known weekday in that month
        Date knownDate = Date.newInstance(2025, 12, 24); // Wednesday
    
        String key = String.valueOf(knownDate);
    
        System.assert(result.containsKey(key),'Map should contain the date');
        System.assertEquals(false, result.get(key),'Expected WFO (true) for ' + knownDate);
    }   
    
    @IsTest
    public static void givenNonHybridEmployee_WhenCheckingSpecificDateGreaterThanTodayDate_ThenValueIsTrue() {
    
        Employee__c emp = [SELECT Id FROM Employee__c WHERE Group__c = 'X' WITH SECURITY_ENFORCED LIMIT 1];
    
        Date inputDate = Date.newInstance(2025, 12, 1);
    
        Map<String, Boolean> result = SAS_Month_Wfo_Finder.findWfoDaysForAMonth(emp.Id, inputDate);
    
        // Pick known weekdays in that month
        Date knownDate1 = Date.newInstance(2025, 12, 15); 
        Date knownDate2 = Date.newInstance(2025, 12, 16);
        Date knownDate3 = Date.newInstance(2025, 12, 17);
        
        System.assertEquals(true, result.get(String.valueOf(knownDate1)),'Expected WFO (true) for ' + knownDate1);
        System.assertEquals(true, result.get(String.valueOf(knownDate2)),'Expected WFO (true) for ' + knownDate2);
        System.assertEquals(true, result.get(String.valueOf(knownDate3)),'Expected WFO (true) for ' + knownDate3);
    } 
}