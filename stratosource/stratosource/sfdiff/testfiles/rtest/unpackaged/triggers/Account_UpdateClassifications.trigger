trigger Account_UpdateClassifications on Account (after insert, after update) {
    List<ServiceMessage__c> serviceMessageList = new List<ServiceMessage__c>();
    List<SyncEvent__c> events = new List<SyncEvent__c>();
    DOM.Document serviceMessageDocument;
    DOM.XmlNode serviceMessageDocumentXml;
    DOM.XmlNode serviceMessageXml;
    Boolean accountUpdate = false;

/*
	Set<ID> types = new Set<ID>();
	for (RecordType recType : [
			select	Id
				 ,	Name
			  from	RecordType
			 where  isActive = true
			   and	Name like '%Partner'
		]) types.add(recType.Id);
*/
    for(Account accountNew : Trigger.new) {
    	if (!accountNew.IsPartner) {
    		continue;
    	}
 //   	if (!types.contains(accountNew.RecordTypeId)) {
 //   		continue;
 //   	}
        Account accountOld = Trigger.IsInsert ? new Account() : Trigger.oldMap.get(accountNew.Id);
	
        if (accountNew.RedHatSyncable__c && !accountOld.RedHatSyncable__c) {
        	SyncEvent__c event = new SyncEvent__c();
	        event.EventType__c = 'UPDATE';
	        event.ObjectId__c = accountNew.Id;
	        event.ObjectType__c = 'Partnerall__c';
	        event.SyncStatus__c = 'NEW';
	        event.EventParams__c = '';
	        event.CreatedTime__c = DateTime.now().getTime();
			events.add(event);
        }
        else {
        	if (!(accountNew.PartnerClassifications__r.size() > 0 
        			&& accountNew.Application_Types__c == null
        			&& accountNew.Industry_Focus__c == null
        			&& accountNew.Middleware_Supported__c == null
        			&& accountNew.Operating_System_Supported__c == null
        			&& accountNew.Software_Focus__c == null
        			&& accountNew.Ownership == null
        			&& accountNew.Vertical__c == null
        			&& accountNew.Hardware_Platform__c == null
        			&& accountNew.Target_Market_Size__c == null
        			&& accountNew.Hardware_Focus__c == null
        			&& accountNew.Hosting_Partner__c == null
        			&& accountNew.Select_Specialization_s__c == null
        			))
        	{
		        accountUpdate = Trigger.IsInsert
	                         || accountNew.Additional_Countries_of_Operation__c != accountOld.Additional_Countries_of_Operation__c
	                         || accountNew.Additional_Partnerships__c != accountOld.Additional_Partnerships__c
	                         || accountNew.Application_Types__c != accountOld.Application_Types__c
	                         || accountNew.Industry_Focus__c != accountOld.Industry_Focus__c
	                         || accountNew.Middleware_Supported__c != accountOld.Middleware_Supported__c
	                         || accountNew.Operating_System_Supported__c != accountOld.Operating_System_Supported__c
	                         || accountNew.Software_Focus__c != accountOld.Software_Focus__c
	                         || accountNew.Ownership != accountOld.Ownership
	                         || accountNew.Vertical__c != accountOld.Vertical__c
	                         || accountNew.Hardware_Platform__c != accountOld.Hardware_Platform__c
	                         || accountNew.Target_Market_Size__c != accountOld.Target_Market_Size__c
	                         || accountNew.Hardware_Focus__c != accountOld.Hardware_Focus__c
                             || accountNew.Hosting_Partner__c != accountOld.Hosting_Partner__c
                             || accountNew.Select_Specialization_s__c != accountOld.Select_Specialization_s__c
	                         || accountNew.PartnerClassifications__r.size() == 0;
        	}
        }        
        if (accountUpdate == false)
            continue;
        
        serviceMessageDocument = new DOM.Document();
        serviceMessageDocumentXml = serviceMessageDocument.createRootElement('envelope', System.Label.NS_SOAP, 'soap');
        serviceMessageXml = serviceMessageDocumentXml.addChildElement('body', System.Label.NS_SOAP, null);
        serviceMessageXml.setNamespace('service', System.Label.NS_SERVICE);
        serviceMessageXml.setAttributeNS('generatedBy', 'Trigger.Account_UpdateClassifications', System.Label.NS_SERVICE, null);
        serviceMessageXml.setAttributeNS('accountId', accountNew.Id, System.Label.NS_SERVICE, null);
        serviceMessageList.add(new ServiceMessage__c(Command__c = '/account/update-classifications/copy-from-fields', Payload__c = serviceMessageDocument.toXmlString()));
    }
    
    if (serviceMessageList.size() != 0) {
        insert serviceMessageList;
    }
	if (events.size() > 0) {
		insert events;
	}    
}