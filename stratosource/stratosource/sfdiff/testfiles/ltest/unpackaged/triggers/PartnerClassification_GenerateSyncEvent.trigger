trigger PartnerClassification_GenerateSyncEvent on PartnerClassification__c (after delete, after insert, after undelete, 
after update) {

    List<SyncEvent__c> events = new List<SyncEvent__c>();
    if (Trigger.isInsert || Trigger.isUnDelete){
        for(PartnerClassification__c pClass : Trigger.new){
            if (pClass.RedHatSyncable__c == 'y'){
                String params = 'PartnerClassification__c.Account__c=' + pClass.Partner__c +
                    '&PartnerClassification__c.Classification__c=' + pClass.Classification__c;
                events.add(SyncEvent_Generator.logObjectCreate(pClass, params));
            }
        }
    } else if (Trigger.isUpdate){
        for(PartnerClassification__c pClass : Trigger.new){
            if (pClass.RedHatSyncable__c == 'y')
                events.add(SyncEvent_Generator.logObjectUpdate(pClass));
        }
    } else if (Trigger.isDelete){
        for (PartnerClassification__c pClass : Trigger.old){     
            if (pClass.RedHatSyncable__c == 'y'){       
                String params = 'PartnerClassification__c.Account__c=' + pClass.Partner__c +
                    '&PartnerClassification__c.Classification__r.HierarchyKey__c=' + pClass.ClassificationKey__c;
                events.add(SyncEvent_Generator.logObjectDelete(pClass, params));
            }
        }
    }
    SyncEvent_Generator.storeEvents(events);
    
}