trigger Account_GenerateSyncEvent on Account (after delete, after insert, after undelete, 
after update) {

    List<SyncEvent__c> events = new List<SyncEvent__c>();
    if (Trigger.isInsert || Trigger.isUnDelete){
        for(Account o : Trigger.new){
            if (o.RedHatSyncable__c)
                events.add(SyncEvent_Generator.logObjectCreate(o));
        }
    } else if (Trigger.isUpdate){
        for(Account o : Trigger.new){
            if (o.RedHatSyncable__c)
                events.add(SyncEvent_Generator.logObjectUpdate(o));
        }
    } else if (Trigger.isDelete){
        for (Account a : Trigger.old){
            // Temporary disabled to test migration
            if (a.RedHatSyncable__c 
                    && (a.MigrationSource__c == null 
                        || !('Legacy Partner Center New'.equals(a.MigrationSource__c)
                        || 'Legacy Partner Center Merged'.equals(a.MigrationSource__c))
                    )
                ){
                events.add(SyncEvent_Generator.logObjectDelete(a));
            }
        }
    }
    SyncEvent_Generator.storeEvents(events);

}