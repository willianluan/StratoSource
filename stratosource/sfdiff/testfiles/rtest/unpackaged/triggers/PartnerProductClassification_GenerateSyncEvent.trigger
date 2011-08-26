trigger PartnerProductClassification_GenerateSyncEvent on PartnerProductClassification__c (after delete, after insert, after undelete, 
after update) {
    
    List<SyncEvent__c> events = new List<SyncEvent__c>();
	Set<Id> products = new Set<Id>();
	if (!Trigger.isDelete){
	    for(PartnerProductClassification__c ppClass : Trigger.new){
	    	if (!products.contains(ppClass.PartnerProduct__c) && ppClass.RedHatSyncable__c == 'y'){
	    		products.add(ppClass.PartnerProduct__c);
	    	}
	    }
	} else {
	    for(PartnerProductClassification__c ppClass : Trigger.old){
	    	if (!products.contains(ppClass.PartnerProduct__c) && ppClass.RedHatSyncable__c == 'y'){
	    		products.add(ppClass.PartnerProduct__c);
	    	}
	    }
	}
	
	for(Id pId : products){
        events.add(SyncEvent_Generator.createEvent(SyncEvent_Generator.EVENTTYPE_UPDATE, pId, 'PartnerProductClassification__c'));
	}
    SyncEvent_Generator.storeEvents(events);
    
}