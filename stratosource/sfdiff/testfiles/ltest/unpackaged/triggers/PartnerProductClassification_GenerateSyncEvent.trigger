trigger PartnerProductClassification_GenerateSyncEvent on PartnerProductClassification__c (after delete, after insert, after undelete, 
after update) {
    
    List<SyncEvent__c> events = new List<SyncEvent__c>();
    if (Trigger.isInsert || Trigger.isUnDelete){
        for(PartnerProductClassification__c ppClass : Trigger.new){
            if (ppClass.RedHatSyncable__c == 'y'){
                String eventParams = 'PartnerProductClassification__c.PartnerProduct__c=' + ppClass.PartnerProduct__c
                        + '&PartnerProductClassification__c.Classification__c=' + ppClass.Classification__c;
                
                events.add(SyncEvent_Generator.logObjectCreate(ppClass, eventParams));
            }
        }
    } else if (Trigger.isUpdate){
        for(PartnerProductClassification__c ppClass : Trigger.new){
            if (ppClass.RedHatSyncable__c == 'y')
                events.add(SyncEvent_Generator.logObjectUpdate(ppClass));
        }
    } else if (Trigger.isDelete){
        for (PartnerProductClassification__c ppClass : Trigger.old){
            if (ppClass.RedHatSyncable__c == 'y'){
                String eventParams = 'PartnerProductClassification__c.PartnerProduct__c=' + ppClass.PartnerProduct__c
                        + '&PartnerProductClassification__c.Classification__r.HierarchyKey__c=' + ppClass.ClassificationKey__c;
                        
                events.add(SyncEvent_Generator.logObjectDelete(ppClass, eventParams));
            }
        }
    }
    SyncEvent_Generator.storeEvents(events);
    
}