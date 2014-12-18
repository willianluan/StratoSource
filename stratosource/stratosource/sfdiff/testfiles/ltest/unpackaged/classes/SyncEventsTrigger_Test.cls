public with sharing class SyncEventsTrigger_Test {
  
    public static testmethod void testAccountSyncEventTrigger(){
        // Test Create   
        Account o = createAccount();
        String id = o.Id;

        SyncEvent__c sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;
            
        // NO CREATE Event for Account
        
        // Test Update
        o.AccountNumber = '000000';
        update o;
        sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;     
    }
    
    public static testmethod void testAccountSyncEventTriggerNoAccountStatus(){
        // Test Create   
        Account o = createAccount(false);
        String id = o.Id;
        // NO CREATE Event for Account
        
        // Test Update
        o.AccountNumber = '000000';
        update o;
        System.assertEquals(0, countSyncEventForObject(o));                    
        
        // Test Delete
        delete o;
        System.assertEquals(0, countSyncEventForObject(o));                    
    }
    
    public static testmethod void testMigragtedAccountSyncEventTrigger(){
        // Test Create   
        Account o = createAccount();
        String id = o.Id;
            
        // NO CREATE Event for Account
            
        SyncEvent__c sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;
        
        // Test Update
        o.AccountNumber = '000000';
        o.MigrationSource__c = 'Legacy Partner Center New';
        update o;
        sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;
    }
    
    public static testmethod void testPartnerStatusSyncEventTrigger(){
        // Test Create   
        Account acct = createAccount();
        
        PartnerStatus__c o = new PartnerStatus__c();
        o.ActivationDate__c = Date.today();
        o.Partner__c = acct.Id;
        o.ApprovalStatus__c = 'Approved';
        o.PartnerTier__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.READY'].Id;
        o.PartnerType__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV'].Id;
        insert o;
        String id = o.Id;
            
        SyncEvent__c sE = getSyncEventForObject(o);                    
        System.assertEquals('CREATE', sE.EventType__c);                    
        delete sE;

        // Test Update
        o.ActivationDate__c = Date.today().addDays(-4);
        update o;
        System.assertEquals(true, acct.RedHatSyncable__c);
        sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;
        
        // Test Delete
        delete o;
        sE = getSyncEventForObject(id);
        System.assertEquals('DELETE', sE.EventType__c);                    
        delete sE;
                            
    }
    
    public static testmethod void testPartnerClassificationSyncEventTrigger(){
        // Test Create   
        Account acct = createAccount();
        
        
        PartnerClassification__c o = new PartnerClassification__c();
        o.Partner__c = acct.Id;
        o.Classification__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_CLASSIFICATION.INDUSTRY_MARKETS.ALL_INDUSTRIES_HORIZONTAL_APPLICATION'].Id;
        o.ActivationDate__c = date.today();
        insert o;
        String id = o.Id;
            
        SyncEvent__c sE = getSyncEventForObject(o);                    
        System.assertEquals('CREATE', sE.EventType__c);                    
        delete sE;

        // Test Update
        o.ActivationDate__c = date.today().addDays(5);
        update o;
        sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;
        
        // Test Delete
        delete o;
        sE = getSyncEventForObject(id);
        System.assertEquals('DELETE', sE.EventType__c);                    
        delete sE;
                            
    }
    
    public static testmethod void testPartnerLogoSyncEventTrigger(){
        // Test Create   
        Account acct = createAccount();
        
        
        PartnerLogo__c o = new PartnerLogo__c();
        o.Partner__c = acct.Id;
        insert o;
        String id = o.Id;
            
        SyncEvent__c sE = getSyncEventForObject(o);                    
        System.assertEquals('CREATE', sE.EventType__c);                    
        delete sE;

        // Test Update
        update o;
        sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;
        
        // Test Delete
        delete o;
        sE = getSyncEventForObject(id);
        System.assertEquals('DELETE', sE.EventType__c);                    
        delete sE;
                            
    }    

    public static testmethod void testPartnerProductSyncEventTrigger(){
        // Test Create   
        Account acct = createAccount();
        
        
        PartnerProduct__c o = new PartnerProduct__c();
        o.Partner__c = acct.Id;
        o.Name = 'Partner Product Test 1';
        insert o;
        String id = o.Id;
            
        SyncEvent__c sE = getSyncEventForObject(o);                    
        System.assertEquals('CREATE', sE.EventType__c);                    
        delete sE;

        // Test Update
        o.Name = 'Partner Product Test 1 Updated';
        update o;
        sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;
        
        // Test Delete
        delete o;
        sE = getSyncEventForObject(id);
        System.assertEquals('DELETE', sE.EventType__c);                    
        delete sE;
                            
    }    
    
    public static testmethod void testPartnerProductLogoSyncEventTrigger(){
        // Test Create   
        Account acct = createAccount();
        
        PartnerProduct__c prod = new PartnerProduct__c();
        prod.Partner__c = acct.Id;
        prod.Name = 'Partner Product Test 1';
        insert prod;
        

        PartnerProductLogo__c o = new PartnerProductLogo__c();
        o.PartnerProduct__c = prod.Id;
        o.ActivationDate__c = date.today();
        insert o;
        String id = o.Id;
            
        SyncEvent__c sE = getSyncEventForObject(o);                    
        System.assertEquals('CREATE', sE.EventType__c);                    
        delete sE;

        // Test Update
        o.ActivationDate__c = date.today().addDays(5);
        update o;
        sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;
        
        // Test Delete
        delete o;
        sE = getSyncEventForObject(id);
        System.assertEquals('DELETE', sE.EventType__c);                    
        delete sE;
        delete prod;
                            
    }  
      
    public static testmethod void testPartnerProductScreenshotSyncEventTrigger(){
        // Test Create   
        Account acct = createAccount();
        
        PartnerProduct__c prod = new PartnerProduct__c();
        prod.Partner__c = acct.Id;
        prod.Name = 'Partner Product Test 1';
        insert prod;
        

        PartnerProductScreenshot__c o = new PartnerProductScreenshot__c();
        o.PartnerProduct__c = prod.Id;
        insert o;
        String id = o.Id;
            
        SyncEvent__c sE = getSyncEventForObject(o);                    
        System.assertEquals('CREATE', sE.EventType__c);                    
        delete sE;

        // Test Update
        Attachment at = new Attachment();
        at.ParentId = o.Id;
        at.Name = 'Phony Screenshot';
        at.Body = blob.valueOf('aaaa');
        insert at;
        update o;
        sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);    
        delete sE;
        
        // Test Delete
        String paramsShouldBe = 'PartnerProductScreenshot__c.PartnerProduct__c=' + o.PartnerProduct__c + '&PartnerProductScreenshot__c.Partner__c=' + (acct.Id + '').substring(0, 15);                
        delete o;
        sE = getSyncEventForObject(id);
        System.assertEquals('DELETE', sE.EventType__c);                    
        System.assertEquals(paramsShouldBe, sE.EventParams__c);    
        delete sE;
        delete prod;
                            
    }    
    
    public static testmethod void testPartnerProductClassificationSyncEventTrigger(){
        // Test Create   
        Account acct = createAccount();
        
        PartnerProduct__c prod = new PartnerProduct__c();
        prod.Partner__c = acct.Id;
        prod.Name = 'Partner Product Test 1';
        insert prod;
        

        PartnerProductClassification__c o = new PartnerProductClassification__c();
        o.PartnerProduct__c = prod.Id;
        o.ActivationDate__c = date.today();
        o.Classification__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_PRODUCT_CLASSIFICATION.LANGUAGE.CHINESE'].Id;
        insert o;
        String id = o.Id;
            
        SyncEvent__c sE = getSyncEventForObject(o);                    
        System.assertEquals('CREATE', sE.EventType__c);                    
        delete sE;

        // Test Update
        o.ActivationDate__c = date.today().addDays(5);
        update o;
        sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;
        
        // Test Delete
        delete o;
        sE = getSyncEventForObject(id);
        System.assertEquals('DELETE', sE.EventType__c);                    
        delete sE;
        delete prod;
                            
    }    
    
    public static testmethod void testClassificationSyncEventTrigger(){
        // Test Create   
        Classification__c o = new Classification__c();
        o.Name = 'Test Classification';
        insert o;
        String id = o.Id;
            
        SyncEvent__c sE = getSyncEventForObject(o);                    
        System.assertEquals('CREATE', sE.EventType__c);                    
        delete sE;

        // Test Update
        o.Name = 'Test Classification Updated';
        update o;
        sE = getSyncEventForObject(o);
        System.assertEquals('UPDATE', sE.EventType__c);                    
        delete sE;
        
        // Test Delete
        delete o;
        sE = getSyncEventForObject(id);
        System.assertEquals('DELETE', sE.EventType__c);                    
        delete sE;
                                
    } 
    
    public static Account createAccount(){        
        return createAccount(true);
    }
    
    public static Account createAccount(boolean addAccountStatus){
        Account acct = new Account();
        acct.Name = 'Test Account';
        acct.RecordTypeId = [select Id from RecordType where RecordType.Name = 'NA Partner'].Id;
        insert acct;
  
        if (addAccountStatus){
            acct.RedHatSyncable__c = true;
            update acct;
            delete getSyncEventsForObject(acct);
            PartnerStatus__c o = new PartnerStatus__c();
            o.ActivationDate__c = Date.today();
            o.ApprovalStatus__c = 'Approved';
            o.Partner__c = acct.Id;
            o.PartnerTier__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.READY'].Id;
            o.PartnerType__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV'].Id;
            insert o;
        }
        
        return acct;
    }
    
    public static void makePartnerUser(String id, String contactId){
        User u = [select User.Id, User.ContactId from User where User.Id = :id];
        u.IsPortalEnabled = true;
        update u;
        u.ContactId = contactId;
        update u;
    }
    
    public static SyncEvent__c getSyncEventForObject(String Id){
        return [select EventParams__c, Id, CreatedDate, Name, EventType__c,
                    ObjectId__c, ObjectType__c, StatusMessage__c, SyncStatus__c
                    from SyncEvent__c where ObjectId__c = :Id];
    }
    
    public static List<SyncEvent__c> getSyncEventsForObject(String Id){
        return [select EventParams__c, Id, CreatedDate, Name, EventType__c,
                    ObjectId__c, ObjectType__c, StatusMessage__c, SyncStatus__c
                    from SyncEvent__c where ObjectId__c = :Id];
    }
    
    public static Integer countSyncEventForObject(String Id){
        return [select count()
                    from SyncEvent__c where ObjectId__c = :Id];
    }

    public static SyncEvent__c getSyncEventForObject(SObject o){
        return getSyncEventForObject(o.Id);
    }
    
    public static List<SyncEvent__c> getSyncEventsForObject(SObject o){
        return getSyncEventsForObject(o.Id);
    }
    
    public static Integer countSyncEventForObject(SObject o){
        return countSyncEventForObject(o.Id);
    }
    
}