public with sharing class SyncEvent_Generator {
    public static final String STATUS_NEW = 'NEW';
    public static final String EVENTTYPE_CREATE = 'CREATE';
    public static final String EVENTTYPE_UPDATE = 'UPDATE';
    public static final String EVENTTYPE_DELETE = 'DELETE';
    public static final String EVENTTYPE_UNKNOWN = 'UNKNOWN';

    public static SyncEvent__c logObjectUpdate(SObject sObj){
        return createEvent(EVENTTYPE_UPDATE, sObj.Id, getObjectType(sObj));
    }

    public static SyncEvent__c logObjectCreate(SObject sObj){
        return createEvent(EVENTTYPE_CREATE, sObj.Id, getObjectType(sObj));
    }

    public static SyncEvent__c logObjectDelete(SObject sObj){
        return createEvent(EVENTTYPE_DELETE, sObj.Id, getObjectType(sObj));
    }   

    public static SyncEvent__c logObjectUpdate(SObject sObj, String eventParams){
        return createEvent(EVENTTYPE_UPDATE, sObj.Id, getObjectType(sObj), eventParams);
    }

    public static SyncEvent__c logObjectCreate(SObject sObj, String eventParams){
        return createEvent(EVENTTYPE_CREATE, sObj.Id, getObjectType(sObj), eventParams);
    }

    public static SyncEvent__c logObjectDelete(SObject sObj, String eventParams){
        return createEvent(EVENTTYPE_DELETE, sObj.Id, getObjectType(sObj), eventParams);
    }   
    
    public static void storeEvents(List<SyncEvent__c> eventList){
        insert eventList;
    }
    
    // Used for unit testing
    public static void storeEvent(SyncEvent__c event){
        List<SyncEvent__c> events = new List<SyncEvent__c>();
        events.add(event);
        storeEvents(events);
    }

    public static SyncEvent__c createEvent(String eventType, String changedObjectId, String changedObjectType){
        return createEvent(eventType, changedObjectId, changedObjectType, null);
    }
        
    public static SyncEvent__c createEvent(String eventType, String changedObjectId, String changedObjectType, String eventParams){
        SyncEvent__c event = new SyncEvent__c();
        
        event.EventType__c = eventType;
        event.ObjectId__c = changedObjectId;
        event.ObjectType__c = changedObjectType;
        event.SyncStatus__c = STATUS_NEW;
        event.EventParams__c = eventParams;
        event.CreatedTime__c = DateTime.now().getTime();
        
        return event;
    }   
    
    private static String getObjectType(SObject sObj){
        return sObj.getSObjectType().getDescribe().getName();
    }
    
    public static void updateAccountSyncableFlag(List<Account> accounts){
        for (Account a : accounts){
            a.RedHatSyncable__c = a.RedHatSyncable__c || (a.PartnerStatuses__c != null && a.PartnerStatuses__c != '' && a.PartnerStatuses__c != 'None');
        }
    }

}