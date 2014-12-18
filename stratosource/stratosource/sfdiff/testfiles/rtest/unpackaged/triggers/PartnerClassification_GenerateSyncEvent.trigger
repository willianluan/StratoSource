trigger PartnerClassification_GenerateSyncEvent on PartnerClassification__c (after delete, after insert, after undelete, 
after update) {

    List<SyncEvent__c> events = new List<SyncEvent__c>();
	Set<Id> partners = new Set<Id>();
	if (!Trigger.isDelete){
	    for(PartnerClassification__c pClass : Trigger.new){
	        if (!partners.contains(pClass.Partner__c) && pClass.RedHatSyncable__c == 'y'){
		    	partners.add(pClass.Partner__c);
	        }
	    }
	} else {
	    for(PartnerClassification__c pClass : Trigger.old){
	        if (!partners.contains(pClass.Partner__c) && pClass.RedHatSyncable__c == 'y'){
		    	partners.add(pClass.Partner__c);
	        }
	    }
	}

	for(Id pId : partners){
        events.add(SyncEvent_Generator.createEvent(SyncEvent_Generator.EVENTTYPE_UPDATE, pId, 'PartnerClassification__c'));
	}
    SyncEvent_Generator.storeEvents(events);
    
}