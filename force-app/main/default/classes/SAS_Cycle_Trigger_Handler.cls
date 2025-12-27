public with sharing class SAS_Cycle_Trigger_Handler {
    
    public static void validateSchedules(List<Cycle__c> newList,Map<Id, Cycle__c> oldMap) {

        // Step 1: Filter cycles    that actually need validation
        List<Cycle__c> cyclesToValidate = new List<Cycle__c>();
        Set<Id> updatingIds = new Set<Id>();

        for (Cycle__c c : newList) {

            // INSERT
            if (oldMap == null) {
                if (c.Current_Schedule__c != null) {
                    cyclesToValidate.add(c);
                }
            }
            // UPDATE
            else {
                Cycle__c oldC = oldMap.get(c.Id);
                if (
                    c.Current_Schedule__c != null &&
                    c.Current_Schedule__c != oldC.Current_Schedule__c
                ) {
                    cyclesToValidate.add(c);
                    updatingIds.add(c.Id);
                }
            }
        }

        if (cyclesToValidate.isEmpty()) {
            return;
        }

        // Step 2: Load "other" cycles
        List<Cycle__c> otherCycles;

        if (oldMap == null) {
            // INSERT → all existing cycles
            otherCycles = [
                SELECT Id, Current_Schedule__c
                FROM Cycle__c
                WHERE Current_Schedule__c != NULL
            ];
        } else {
            // UPDATE → exclude updating records
            otherCycles = [
                SELECT Id, Current_Schedule__c
                FROM Cycle__c
                WHERE Id NOT IN :updatingIds
                AND Current_Schedule__c != NULL
            ];
        }

        // Step 3: Reserve weekdays from existing cycles
        Map<String, Id> weekdayToCycle = new Map<String, Id>();

        for (Cycle__c c : otherCycles) {
            for (String day : c.Current_Schedule__c.split(';')) {
                weekdayToCycle.put(day.trim(), c.Id);
            }
        }

        // Step 4: Validate final schedules
        for (Cycle__c c : cyclesToValidate) {
            for (String day : c.Current_Schedule__c.split(';')) {
                day = day.trim();

                if (weekdayToCycle.containsKey(day)) {
                    c.addError(
                        'Weekday "' + day +
                        '" is already assigned to another Cycle.'
                    );
                    break;
                }

                // reserve for this cycle
                weekdayToCycle.put(day, c.Id);
            }
        }
    }
    
    public static void validateGroups(List<Cycle__c> newList,Map<Id, Cycle__c> oldMap) {
    
        // Step 1: Identify records that need validation
        List<Cycle__c> cyclesToValidate = new List<Cycle__c>();
        Set<Id> updatingIds = new Set<Id>();
        Set<String> groupValues = new Set<String>();
    
        for (Cycle__c c : newList) {
    
            // INSERT
            if (oldMap == null) {
                if (c.Group__c != null) {
                    cyclesToValidate.add(c);
                    groupValues.add(c.Group__c);
                }
            }
            // UPDATE
            else {
                Cycle__c oldC = oldMap.get(c.Id);
                if (
                    c.Group__c != null &&
                    c.Group__c != oldC.Group__c
                ) {
                    cyclesToValidate.add(c);
                    updatingIds.add(c.Id);
                    groupValues.add(c.Group__c);
                }
            }
        }
    
        if (cyclesToValidate.isEmpty()) {
            return;
        }
    
        // Step 2: Load other cycles with same groups
        List<Cycle__c> otherCycles;
    
        if (oldMap == null) {
            otherCycles = [
                SELECT Id, Group__c
                FROM Cycle__c
                WHERE Group__c IN :groupValues
            ];
        } else {
            otherCycles = [
                SELECT Id, Group__c
                FROM Cycle__c
                WHERE Group__c IN :groupValues
                AND Id NOT IN :updatingIds
            ];
        }
    
        // Step 3: Build group → cycle map
        Map<String, Id> groupToCycle = new Map<String, Id>();
    
        for (Cycle__c c : otherCycles) {
            groupToCycle.put(c.Group__c, c.Id);
        }
    
        // Step 4: Final validation
        for (Cycle__c c : cyclesToValidate) {
    
            if (groupToCycle.containsKey(c.Group__c)) {
                c.addError(
                    'This Group is already assigned to another Cycle.'
                );
            } else {
                groupToCycle.put(c.Group__c, c.Id);
            }
        }
    }



}