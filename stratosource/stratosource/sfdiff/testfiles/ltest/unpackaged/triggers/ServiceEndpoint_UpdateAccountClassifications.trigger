trigger ServiceEndpoint_UpdateAccountClassifications on ServiceMessage__c (before update) {
    //
    // Sanity
    //

    system.assert(Trigger.new.size() == 1);

    //
    // Setup 
    //
    
    final String EXPECTED_COMMAND = '/account/update-classifications/copy-from-fields';
    final String NS_SOAP = System.Label.NS_SOAP;
    final String NS_SERVICE = System.Label.NS_SERVICE;
    final ServiceMessage__c serviceMessage = Trigger.new[0];
    
    if (serviceMessage.Command__c != EXPECTED_COMMAND)
        return;
    
    Dom.Document doc = new Dom.Document();
    doc.load(serviceMessage.Payload__c);
    DOM.XmlNode body = doc.getRootElement().getChildElement('body', NS_SOAP);

    Id accountId = body.getAttributeValue('accountId', NS_SERVICE);
   
    //
    // Find all classifications with a legacy picklist and picklist value
    //
    
    List<Classification__c> classificationMapList = [
        select Legacy_Picklist__c
             , Legacy_Picklist_Value__c
             , HierarchyKey__c
          from Classification__c
         where Legacy_Picklist__c != null
           and Legacy_Picklist_Value__c != null
           and HierarchyKey__c like 'PARTNER_CLASSIFICATION.%'
    ];

    //
    // Map them (this step may be redundant now with the legacy picklist values contained on the 
    // classification itself, but I don't have the desire to rework and retest the logic).
    //
    // @todo
    
    Map<String, Map<String, String>> classificationsMap = new Map<String, Map<String, String>>();

    for(Classification__c classification : classificationMapList) {
        if (classificationsMap.containsKey(classification.Legacy_Picklist__c) == false)
            classificationsMap.put(classification.Legacy_Picklist__c, new Map<String, String>());
        classificationsMap.get(classification.Legacy_Picklist__c).put(classification.Legacy_Picklist_Value__c, classification.HierarchyKey__c);
    }

    //
    // Build our set of hierarchy keys
    //

    Map<String, Classification__c> hierarchyKeysMap = new Map<String, Classification__c>();
    
    for(String fieldName : classificationsMap.keySet()) {
        for(String hierarchyKey : classificationsMap.get(fieldName).values()) {
            hierarchyKeysMap.put(hierarchyKey, null);
        }
    }
    
    for(Classification__c classification : [
        select HierarchyKey__c
          from Classification__c
         where HierarchyKey__c in :hierarchyKeysMap.keySet()
    ]) hierarchyKeysMap.put(classification.HierarchyKey__c, classification);
    
    //
    // Re-query the account
    //
    
    Account account = null;

    try {
        account = [
            select Id
                 , Additional_Countries_of_Operation__c
                 , Additional_Partnerships__c
                 , Application_Types__c
                 , Industry_Focus__c
                 , Middleware_Supported__c
                 , Operating_System_Supported__c
                 , Software_Focus__c
                 , Ownership
                 , Vertical__c
                 , Hardware_Platform__c
                 , Target_Market_Size__c
                 , Hardware_Focus__c
              from Account
             where Id  = :accountId
        ];
        
        List<PartnerClassification__c> pClsList = [
        	select Id
        	  from PartnerClassification__c
        	where Partner__c = :accountId
        ];
        if (pClsList.size() > 0 
        			&& account.Application_Types__c == null
        			&& account.Industry_Focus__c == null
        			&& account.Middleware_Supported__c == null
        			&& account.Operating_System_Supported__c == null
        			&& account.Software_Focus__c == null
        			&& account.Ownership == null
        			&& account.Vertical__c == null
        			&& account.Hardware_Platform__c == null
        			&& account.Target_Market_Size__c == null
        			&& account.Hardware_Focus__c == null
        			)
    	{
    		// We have classifications but none of the combos are set, STOP NOW
    		return;
    	}
    } catch (System.QueryException queryException) {
        //throw queryException; // @todo actual handling.
        return;
    } catch (System.DmlException dmlException) {
        //throw dmlException; // @todo actual handling.
        return;
    }
    
    //
    // Fetch old partner classifications that are referenced in our mapping
    //
    Map<String, PartnerClassification__c> existingClfns = new Map<String, PartnerClassification__c>();
    try {        
        for(PartnerClassification__c pClfn : [
            select Id, Classification__r.HierarchyKey__c
              from PartnerClassification__c
             where Partner__c = :accountId
               and Classification__r.HierarchyKey__c in :hierarchyKeysMap.keySet()
        ]) existingClfns.put(pClfn.Classification__r.HierarchyKey__c, pClfn); 
    } catch (System.QueryException queryException) {
        throw queryException; // @todo actual handling.
    } catch (System.DmlException dmlException) {
        throw dmlException; // @todo actual handling.
    }
    
    //
    // Add in new partner classifications
    //
 
    List<PartnerClassification__c> partnerClassificationList = new List<PartnerClassification__c>();
    
    for(String fieldName : classificationsMap.keySet()) {
        String fieldData = String.valueOf(account.get(fieldName));
        if (fieldData == null)
            continue;
        
        for(String picklistValue : classificationsMap.get(fieldName).keySet()) {
            String hierarchyKey = classificationsMap.get(fieldName).get(picklistValue);
            
            if (fieldData.contains(picklistValue) == false)
                continue;
            if (hierarchyKeysMap.containsKey(hierarchyKey) == false)
                system.assert(false, 'Missing hierarchy key => classification mapping for key: ' + hierarchyKey);
            
            if (existingClfns.containsKey(hierarchyKey)){
                // We already have this one, remove it from the list
                existingClfns.remove(hierarchyKey);
            } else {
                PartnerClassification__c partnerClassification = new PartnerClassification__c();
                partnerClassification.Partner__c = account.Id;
                partnerClassification.Classification__c = hierarchyKeysMap.get(hierarchyKey).Id;
                partnerClassification.ActivationDate__c = Date.today();
                partnerClassification.ExpirationDate__c = Date.today().addYears(1);
                partnerClassificationList.add(partnerClassification);
            }
        }
    }
    
    // If it is still in the list, it is no longer used
    if (existingClfns.size() != 0)
        delete existingClfns.values();
 
    try {
	    if (partnerClassificationList.size() != 0)
	        insert partnerClassificationList;
    }
    catch (System.DmlException ex) {
    	// we will ignore this for now
    }
}