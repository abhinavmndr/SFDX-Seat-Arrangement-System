public with sharing class SAS_Block_Controller {

    @AuraEnabled(cacheable=true)
    public static List<BlockSummaryWrapper> getBlockSummaries() {

        // Load Blocks
        Map<Id, Block__c> blocks = new Map<Id, Block__c>(
            [SELECT Id, Name, Location__c, Total_Seats__c,
                    Daily_Seats_Available__c, Daily_Occupied_Seats__c,
                    Hybrid_Seats_Available__c
             FROM Block__c]
        );

        // Excluded groups
        Set<String> excludedGroups = new Set<String>{ 'X', 'Y' };

        // Load ALL group picklist values (dynamic)
        List<String> allGroups = new List<String>();
        for (Schema.PicklistEntry pe : Employee__c.Group__c.getDescribe().getPicklistValues()) {
            if (!excludedGroups.contains(pe.getValue())) {
                allGroups.add(pe.getValue());
            }
        }

        // Employee counts grouped by Block + Group (excluding X and Y)
        List<AggregateResult> counts = [
            SELECT Block__c blockId, Group__c grp, COUNT(Id) total
            FROM Employee__c
            WHERE Block__c IN :blocks.keySet()
            AND Group__c NOT IN :excludedGroups
            GROUP BY Block__c, Group__c
        ];

        // Build block → group count map (RAW COUNTS ONLY)
        Map<Id, Map<String, Integer>> blockToGroups = new Map<Id, Map<String, Integer>>();

        for (AggregateResult ar : counts) {
            Id blockId = (Id) ar.get('blockId');
            String groupName = (String) ar.get('grp');
            Integer employeeCount = (Integer) ar.get('total');

            if (!blockToGroups.containsKey(blockId)) {
                blockToGroups.put(blockId, new Map<String, Integer>());
            }
            blockToGroups.get(blockId).put(groupName, employeeCount);
        }

        // Build final list
        List<BlockSummaryWrapper> finalList = new List<BlockSummaryWrapper>();

        for (Block__c b : blocks.values()) {
            BlockSummaryWrapper wrap = new BlockSummaryWrapper();

            wrap.blockId = b.Id;
            wrap.blockName = b.Name;
            wrap.location = b.Location__c;
            wrap.totalSeats = b.Total_Seats__c;
            wrap.dailyAvailable = b.Daily_Seats_Available__c - b.Daily_Occupied_Seats__c;

            // Ensure full group list exists with zero fallback
            Map<String, Integer> groupsForBlock =
                blockToGroups.containsKey(b.Id)
                ? blockToGroups.get(b.Id)
                : new Map<String, Integer>();

            // Apply hybrid logic ONLY here
            for (String grp : allGroups) {

                Integer employeeCount =
                    groupsForBlock.containsKey(grp)
                    ? groupsForBlock.get(grp)
                    : 0;

                Integer value;

                if (b.Hybrid_Seats_Available__c != null) {
                    value = Math.max(
                        0,
                        (Integer) b.Hybrid_Seats_Available__c - employeeCount
                    );
                } else {
                    value = employeeCount;
                }

                groupsForBlock.put(grp, value);
            }

            wrap.groupCounts = groupsForBlock;
            finalList.add(wrap);
        }

        return finalList;
    }

    public class BlockSummaryWrapper {
        @AuraEnabled public Id blockId;
        @AuraEnabled public String blockName;
        @AuraEnabled public String location;
        @AuraEnabled public Decimal totalSeats;
        @AuraEnabled public Decimal dailyAvailable;
        @AuraEnabled public Map<String, Integer> groupCounts;
    }

    @AuraEnabled(cacheable=true)
    public static List<Block__c> getBlocks() {
        return [
            SELECT Id, Name
            FROM Block__c
            ORDER BY Name
        ];
    }
}