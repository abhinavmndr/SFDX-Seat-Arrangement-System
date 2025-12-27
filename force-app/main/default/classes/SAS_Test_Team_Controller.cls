@IsTest
public class SAS_Test_Team_Controller {
    
    @TestSetup
    public static void setupTestData(){
        
        List<Team__c> teamsToInsert = new List<Team__c>{
            new Team__c(Name = 'Team A'),
            new Team__c(Name = 'Team B'),
            new Team__c(Name = 'Team C')
        };
        
        Database.insert(teamsToInsert, false);
    }
    
    @IsTest
    public static void givenTeamsExist_WhenGetTeams_ThenTeamsAreReturned(){
        
        List<Team__c> teams = SAS_Team_Controller.getTeams();
        
        System.assertEquals(3, teams.size(), 'Should return all teams');
    }    
}