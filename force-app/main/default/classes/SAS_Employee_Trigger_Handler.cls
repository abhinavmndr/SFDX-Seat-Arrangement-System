public class SAS_Employee_Trigger_Handler{

    public static void recalculateDailyOccupiedSeats(List<Employee__c> newList,Map<Id, Employee__c> oldMap) {

        Set<Id> blockIds = new Set<Id>();

        // Collect blocks from NEW records (insert + update)
        for (Employee__c emp : newList) {
            if (emp.Block__c != null) {
                blockIds.add(emp.Block__c);
            }
        }

        // Collect blocks from OLD records (update only)
        if (oldMap != null) {
            for (Employee__c oldEmp : oldMap.values()) {
                if (oldEmp.Block__c != null) {
                    blockIds.add(oldEmp.Block__c);
                }
            }
        }

        if (blockIds.isEmpty()) return;

        // Aggregate query
        Map<Id, Integer> blockToCountMap = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT Block__c blockId, COUNT(Id) seatCount
            FROM Employee__c
            WHERE Block__c IN :blockIds
              AND Group__c IN ('X', 'Y')
            GROUP BY Block__c
        ]) {
            blockToCountMap.put(
                (Id) ar.get('blockId'),
                (Integer) ar.get('seatCount')
            );
        }

        // Prepare updates
        List<Block__c> blocksToUpdate = new List<Block__c>();

        for (Id blockId : blockIds) {
            blocksToUpdate.add(new Block__c(
                Id = blockId,
                Daily_Occupied_Seats__c = blockToCountMap.containsKey(blockId)
                    ? blockToCountMap.get(blockId)
                    : 0
            ));
        }

        update blocksToUpdate;
    }

    public static void validateDailyOccupiedSeats(List<Employee__c> newList){

        // List of employees whose group changed to X/Y
        List<Employee__c> filteredEmpToIncrement = new List<Employee__c>();
        // Set of block ids.
        Set<Id> blockIds = new Set<Id>();

        for(Employee__c newEmp : newList){
            if((newEmp.Block__c != null) && (newEmp.Group__c == 'X' || newEmp.Group__c == 'Y')){
                filteredEmpToIncrement.add(newEmp);
                blockIds.add(newEmp.Block__c);
            } 
        }
        // Create Map of Block Id to Block record.
        Map<Id, Block__c> blockIdToBlockMap = new Map<Id, Block__c>([SELECT Id, Daily_Occupied_Seats__c, Name , Daily_Seats_Available__c FROM Block__c WHERE Id IN :blockIds]);

        // Map to hold unique block updates
        Map<Id, Block__c> blockUpdateMap = new Map<Id, Block__c>();

        for(Employee__c emp : filteredEmpToIncrement){
            if(blockIdToBlockMap.containsKey(emp.Block__c)){
                Block__c block = blockIdToBlockMap.get(emp.Block__c);
                if(block.Daily_Occupied_Seats__c > block.Daily_Seats_Available__c){
                    emp.addError('Daily Seats Occupied cannot be greater than Daily Seats Available in Block: ' + block.Name);
                }
            } 
        }

    }

    public static void validateHybridSeats(List<Employee__c> newList){

        // List of employees whose group changed to Hybrid
        List<Employee__c> filteredEmp = new List<Employee__c>();
        // Set of block ids.
        Set<Id> blockIds = new Set<Id>();

        Set<String> blockGroupKeys = new Set<String>();

        for(Employee__c newEmp : newList){
            if((newEmp.Block__c != null) && (newEmp.Group__c != 'X' && newEmp.Group__c != 'Y')){
                filteredEmp.add(newEmp);
                blockIds.add(newEmp.Block__c);
                blockGroupKeys.add(newEmp.Block__c + '---' + newEmp.Group__c);
            } 
        }
        // Create Map of Block Id to Block record.
        Map<Id, Block__c> blockIdToBlockMap = new Map<Id, Block__c>([SELECT Id, Name , Hybrid_Seats_Available__c FROM Block__c WHERE Id IN :blockIds]);

         // Step 3: Aggregate query to count Employees by Block + Group
        Map<String, Integer> blockGroupToCount = new Map<String, Integer>();

        for (AggregateResult ar : [SELECT Block__c blockId, Group__c grp, COUNT(Id) total FROM Employee__c WHERE Block__c IN :blockIds GROUP BY Block__c, Group__c]) {
            String key = (String)ar.get('blockId') + '---' + (String)ar.get('grp');
            blockGroupToCount.put(key, (Integer)ar.get('total'));
        }
        
        for(Employee__c emp : filteredEmp){
            if(blockIdToBlockMap.containsKey(emp.Block__c)){
                String key = emp.Block__c + '---' + emp.Group__c;
                Integer currentCount = blockGroupToCount.containsKey(key)? blockGroupToCount.get(key): 0;
                Block__c block = blockIdToBlockMap.get(emp.Block__c);
                if (currentCount > block.Hybrid_Seats_Available__c) {
                    emp.addError('No hybrid seats available in Block: ' + block.Name +' for Group: ' + emp.Group__c);
                }
            }
        }
    }

    public static void updateTeamEmployeeCount(List<Employee__c> newList,Map<Id, Employee__c> oldMap) {

        Set<Id> teamIds = new Set<Id>();

        for (Employee__c emp : newList) {
            // INSERT
            if (oldMap == null) {
                if (emp.Team__c != null) {
                    teamIds.add(emp.Team__c);
                }
            }
            // UPDATE – only if team changed
            else {
                Employee__c oldEmp = oldMap.get(emp.Id);
                if (emp.Team__c != oldEmp.Team__c) {
                    if (emp.Team__c != null) {
                        teamIds.add(emp.Team__c);
                    }
                    if (oldEmp.Team__c != null) {
                        teamIds.add(oldEmp.Team__c);
                    }
                }
            }
        }

        if (teamIds.isEmpty()) {
            return;
        }

        // Aggregate query to count employees per team
        Map<Id, Integer> teamEmployeeCountMap = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT Team__c teamId, COUNT(Id) empCount
            FROM Employee__c
            WHERE Team__c IN :teamIds
            GROUP BY Team__c
        ]) {
            teamEmployeeCountMap.put(
                (Id) ar.get('teamId'),
                (Integer) ar.get('empCount')
            );
        }

        // Update Team records
        List<Team__c> teamsToUpdate = new List<Team__c>();

        for (Id teamId : teamIds) {
            Team__c t = new Team__c(
                Id = teamId,
                Number_Of_Employees__c = teamEmployeeCountMap.containsKey(teamId)
                    ? teamEmployeeCountMap.get(teamId)
                    : 0
            );
            teamsToUpdate.add(t);
        }

        if (!teamsToUpdate.isEmpty()) {
            update teamsToUpdate;
        }
    }


}