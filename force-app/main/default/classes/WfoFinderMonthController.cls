public with sharing class WfoFinderMonthController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> getWfoDays(String empId, Date dateValue) {
        return WfoFinderMonth.findWfoDaysForAMonth(empId, dateValue);
    }
}