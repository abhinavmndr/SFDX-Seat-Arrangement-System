public with sharing class TeamController {

    @AuraEnabled(cacheable=true)
    public static List<Team__c> getTeams() {
        return [
            SELECT Id, Name
            FROM Team__c
            ORDER BY Name
        ];
    }
}