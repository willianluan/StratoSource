@IsTest
private class Account_RollupPartnerStatusesTest {
    /**
     * This unit test requires that the appropriate partner types/tiers have already
     * been created in the system, and will fail if not present.
     *
     * The test account, however, is created. 
     */
    public static testmethod void testRollups() {
        // Create the test account
        Account account = new Account();
        account.Name = 'Partner Account';
        account.RecordTypeId = [
            select Id
              from RecordType
             where SObjectType = 'Account'
               and Name = 'NA Partner' 
        ].Id;
        account.BillingCountry = 'US';
        insert account;
        
        // test the rollup has no partner statuses
        system.assertEquals(null, [
            select PartnerStatuses__c
              from Account
             where Id = :account.Id
        ].PartnerStatuses__c);
        
        // Create the first partner status.
        PartnerStatus__c partnerStatus1 = new PartnerStatus__c();
        partnerStatus1.ActivationDate__c = Date.today();
        partnerStatus1.ApprovalStatus__c = 'Approved';
        partnerStatus1.ExpirationDate__c = Date.today().addDays(1);
        partnerStatus1.Partner__c = account.Id;

        partnerStatus1.PartnerTier__c = [
            select Id
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TIER.READY'
             limit 1 
        ].Id;

        partnerStatus1.PartnerType__c = [
            select Id
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TYPE.ISV'
             limit 1 
        ].Id;
        insert partnerStatus1;
        
        // confirm the status is active
        system.assertEquals('Active', [
            select ActivationStatus__c
              from PartnerStatus__c
             where Id = :partnerStatus1.Id
        ].ActivationStatus__c);
        
        // test the rollup is correct for a single partner status
        system.assertEquals([
            select CombinedName__c
              from PartnerStatus__c
             where Id = :partnerStatus1.Id
        ].CombinedName__c, [
            select PartnerStatuses__c
              from Account
             where Id = :account.Id
        ].PartnerStatuses__c);

        // Create the second partner status.
        PartnerStatus__c partnerStatus2 = new PartnerStatus__c();
        partnerStatus2.ActivationDate__c = Date.today();
        partnerStatus2.ApprovalStatus__c = 'Approved';
        partnerStatus2.ExpirationDate__c = Date.today().addDays(1);
        partnerStatus2.Partner__c = account.Id;

        partnerStatus2.PartnerTier__c = [
            select Id
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TIER.ADVANCED'
             limit 1 
        ].Id;

        partnerStatus2.PartnerType__c = [
            select Id
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TYPE.RESELLER'
             limit 1 
        ].Id;
        insert partnerStatus2;
        
        // confirm the status is active
        system.assertEquals('Active', [
            select ActivationStatus__c
              from PartnerStatus__c
             where Id = :partnerStatus2.Id
        ].ActivationStatus__c);
        
        // test the rollup is correct for two active partner status
        system.assertEquals([
            select CombinedName__c
              from PartnerStatus__c
             where Id = :partnerStatus2.Id
        ].CombinedName__c + ';' + [
            select CombinedName__c
              from PartnerStatus__c
             where Id = :partnerStatus1.Id
        ].CombinedName__c, [
            select PartnerStatuses__c
              from Account
             where Id = :account.Id
        ].PartnerStatuses__c);
        
        // Disable one status
        partnerStatus1.ActivationDate__c = Date.today().addDays(1);
        update partnerStatus1;

        // confirm the status is not yet active
        system.assertEquals('Pending Activation', [
            select ActivationStatus__c
              from PartnerStatus__c
             where Id = :partnerStatus1.Id
        ].ActivationStatus__c);

        // test the rollup is correct again for a single partner status
        system.assertEquals([
            select CombinedName__c
              from PartnerStatus__c
             where Id = :partnerStatus2.Id
        ].CombinedName__c, [
            select PartnerStatuses__c
              from Account
             where Id = :account.Id
        ].PartnerStatuses__c);
        
        // Delete the other status
        delete partnerStatus2;
        
        // test the rollup is correct again when all statuses are inactive or missing
        system.assertEquals(null, [
            select PartnerStatuses__c
              from Account
             where Id = :account.Id
        ].PartnerStatuses__c);
    }
}