public with sharing class SAS_Team_Controller {

    @AuraEnabled(cacheable=true)
    public static List<Team__c> getTeams() {
        return [
            SELECT Id, Name
            FROM Team__c
            ORDER BY Name
        ];
    }
}