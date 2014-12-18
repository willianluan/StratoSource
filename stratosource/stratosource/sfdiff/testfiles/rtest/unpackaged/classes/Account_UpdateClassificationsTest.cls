public class Account_UpdateClassificationsTest {
    
    private static testmethod void testClassificationsTrigger() {
//        Test.startTest();
        Account acct = createAccount(true);
  
        String hkey = 'PARTNER_CLASSIFICATION.APP_TYPE.CONSUMER';
        Classification__c consumerClfn = [select Id from Classification__c where HierarchyKey__c = :hkey];
        consumerClfn.Legacy_Picklist__c = 'Application_Types__c';
        consumerClfn.Legacy_Picklist_Value__c = 'Consumer';
        update consumerClfn;
        
        acct.Application_Types__c = 'Consumer';
        update acct;
        forceServiceMessagesToRunFuture(acct.Id, hkey);
//        Test.StopTest();
/*
        List<PartnerClassification__c> pClfn = [select Id, Classification__r.HierarchyKey__c from PartnerClassification__c where Partner__c = :acct.Id];
       // System.assertEquals(true, pClfn.size() > 0);
        for(PartnerClassification__c c : pClfn){
            System.debug('Partner Classification found: ' + c.Classification__r.HierarchyKey__c);
            if (hkey.equals(c.Classification__r.HierarchyKey__c)){
                // Test passes
                return;
            }
        }
        System.assertEquals(true,false,'No Consumer Classification associated to the Account');
*/
    }
    
    private static Account createAccount(boolean addAccountStatus){
        Account acct = new Account();
        acct.Name = 'Test Account';
        acct.FCPA_Check__c = 'Passed';
        acct.BillingCountry = 'US';
        
        acct.RecordTypeId = [select Id from RecordType where RecordType.Name = 'NA Partner' and SObjectType = 'Account'].Id;
        insert acct;
        acct.IsPartner = true;
        update acct;
  
        if (addAccountStatus){
            update acct;
            PartnerStatus__c o = new PartnerStatus__c();
            o.ActivationDate__c = Date.today();
            o.ExpirationDate__c = Date.today().addYears(1);
            o.ApprovalStatus__c = 'Approved';
            o.Partner__c = acct.Id;
            o.PartnerTier__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.READY'].Id;
            o.PartnerType__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV'].Id;
            insert o;
//            forceServiceMessagesToRunFuture();
        }
        
        return acct;
    }

    @future
    private static void forceServiceMessagesToRunFuture(Id id, String hkey) {
        List<ServiceMessage__c> sms = [select Id, Command__c, Payload__c from ServiceMessage__c where Command__c = '/account/update-classifications/copy-from-fields'];
        for (ServiceMessage__c sm: sms) {
        	if (sm.Payload__c.contains(id)) {
	            update sm;
        	}
        }
        
        List<PartnerClassification__c> pClfn = [select Id, Classification__r.HierarchyKey__c from PartnerClassification__c where Partner__c = :id];
       // System.assertEquals(true, pClfn.size() > 0);
        for(PartnerClassification__c c : pClfn){
            System.debug('Partner Classification found: ' + c.Classification__r.HierarchyKey__c);
            if (hkey.equals(c.Classification__r.HierarchyKey__c)){
                // Test passes
                return;
            }
        }
        System.assertEquals(true,false,'No Consumer Classification associated to the Account');

    }
}