public class CycleGroupRotator {
    public static void rotateGroups() {

        List<Cycle__c> cycles = [
            SELECT Id, Group__c 
            FROM Cycle__c 
            ORDER BY CreatedDate
        ];

        Integer size = cycles.size();
        if(size <= 1){
            return;
        }

        // store original groups
        List<String> groups = new List<String>();
        for(Cycle__c c : cycles){
            groups.add(c.Group__c);
        }

        // rotate groups
        for(Integer i = 0; i < size; i++){
            // circular previous index
            Integer prevIndex = Math.mod((i - 1 + size), size);
            cycles[i].Group__c = groups[prevIndex];
        }

        update cycles;
    }
}