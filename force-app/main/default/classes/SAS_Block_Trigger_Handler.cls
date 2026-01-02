public with sharing class SAS_Block_Trigger_Handler {
    
    public static void validateDailySeatsAvailable(List<Block__c> newList, Map<Id, Block__c> oldMap){
        
        //Create list to filter blocks whose Daily seats available is 
        List<Block__c> filteredBlk = new List<Block__c>();

        //Create Set of block Ids
        Set<Id> blockIds = new Set<Id>();
        
        for(Block__c newblk : newList){
            Block__c oldBlk = oldMap.get(newblk.Id);
            if(newblk.Daily_Seats_Available__c != oldBlk.Daily_Seats_Available__c){
                filteredBlk.add(newblk);
                blockIds.add(newblk.Id);    
            }       
        }

        //Map to hold group to count of employees in that group for a particular block
        Map<String, Integer> groupToGroupCountMap = new Map<String, Integer>();

        for (AggregateResult ar : [
            SELECT Group__c grp, COUNT(Id) total 
            FROM Employee__c 
            WHERE Block__c IN :blockIds 
            AND Group__c NOT IN ('X', 'Y')
            GROUP BY Group__c
        ]) {
            String key = (String)ar.get('grp');  // just the group
            groupToGroupCountMap.put(key, (Integer)ar.get('total'));
        }

        Integer maxValue = 0;

        for(Integer val : groupToGroupCountMap.values()){
            if(maxValue == 0 || val > maxValue){
                maxValue = val;
            }
        }

        for(Block__c blk : filteredBlk){
            Block__c oldBlk = oldMap.get(blk.Id);
            Integer OldHybridCount = (Integer)oldBlk.Daily_Seats_Available__c;
            if(blk.Daily_Seats_Available__c-oldBlk.Daily_Seats_Available__c  > oldBlk.Hybrid_Seats_Available__c - maxValue){
                blk.addError(maxValue+' seats are already occupied in this block by Hybrid Groups. Cannot increase Daily Seats Available above '+ (OldHybridCount+(oldBlk.Hybrid_Seats_Available__c - maxValue)));
                
            }
        }


    }
}