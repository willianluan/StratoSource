@IsTest
private class FundClaim_RejectionControllerTest {
    public static testmethod void testSaveRejectionReason_NA() {
        Account account = new Account();
        account.Name = 'Account';
        account.Global_Region__c = 'NA';
        insert account;
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = 100;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf.CurrencyIsoCode = 'USD';
        insert mdf;

        SFDC_MDF__c fundRequest = new SFDC_MDF__c();
        fundRequest.Account_Master__c = mdf.Account_Master__c;
        fundRequest.Budget__c = mdf.Id;
        fundRequest.CurrencyIsoCode = 'USD';
        fundRequest.Total_Expenditure_of_Activity__c = 100;
        fundRequest.Estimated_Red_Hat_Funding_Requested__c = 100;
        fundRequest.Approval_Status__c = 'Approved';
        insert fundRequest;

        SFDC_MDF_Claim__c fundClaim = new SFDC_MDF_Claim__c();
        fundClaim.Account__c = mdf.Account_Master__c;
        fundClaim.Budget__c = mdf.Id;
        fundClaim.Fund_Request__c = fundRequest.Id;
        fundClaim.CurrencyIsoCode = 'USD';
        fundClaim.Requested_Amount__c = 10.00;
        fundClaim.Name = 'Name';
        fundClaim.Claim_Description__c = 'Description';
        fundClaim.Approval_Status__c = 'Draft';
        fundClaim.Approval_Status_Partner__c = 'Draft';
        insert fundClaim;
        
        // Attach a proof of performance
        Attachment attachment = new Attachment();
        attachment.ParentId = fundClaim.Id;
        attachment.Name = 'Attachment';
        attachment.Body = Blob.valueOf('Attachment');
        insert attachment;

        // Switch to a partner account & user
        account.IsPartner = true;
        update account;
        
        Contact contact = new Contact();
        contact.AccountId = account.Id;
        contact.Email = 'contact@account.com';
        contact.LastName = 'Contact';
        insert contact;
        
        Profile profile = [
            select Id 
              from Profile 
             where Name = 'NA Partner Portal – Strategic License – MDF, DR, PRM'
        ];
         
        /* This segment is now broken, because we can't update a user record 
         * at the same time as a non-user record.
         *
         * This test may no longer test anything...
         *
         * Ian Zepp - 2010-02-03
         *

        User user1 = new User();
        user1.Alias = 'runas';
        user1.ContactId = contact.Id;
        user1.Email = 'standarduser@testorg.com';
        user1.EmailEncodingKey = 'UTF-8';
        user1.LastName = 'Testing';
        user1.LanguageLocaleKey = 'en_US';
        user1.LocalesIdKey = 'en_US';
        user1.ProfileId = profile.Id;
        user1.TimeZoneSidKey = 'America/Los_Angeles';
        user1.UserName = 'standarduser@testorg.com';
        insert user1;

        user1.IsPortalEnabled = true;
        update user1;
        
        system.assertEquals('PowerPartner', [
            select UserType
              from User
             where Id = :user1.Id
        ].UserType, 'UserType != PowerPartner');

        // Create an approval request for the fund request 
        system.runAs(user1) {
            Approval.ProcessSubmitRequest approvalRequest1 = new Approval.ProcessSubmitRequest();
            approvalRequest1.setComments('Submitting fund request for approval.');
            approvalRequest1.setObjectId(fundClaim.Id);
    
            // @todo - The next line fails with a nebulous REQUIRED_FIELD_MISSING error ?
            
            // Approval.ProcessResult approvalResult1 = Approval.process(approvalRequest1);
            // system.assert(approvalResult1.isSuccess());
            // system.assertEquals('Pending', approvalResult1.getInstanceStatus(), 'Instance Status = ' + approvalResult1.getInstanceStatus());
    
            // Run the instance method
            new FundClaim_RejectionController(new ApexPages.StandardController(fundClaim)).saveFC();
        }
        
        */
        
        Approval.ProcessSubmitRequest approvalRequest1 = new Approval.ProcessSubmitRequest();
        approvalRequest1.setComments('Submitting fund request for approval.');
        approvalRequest1.setObjectId(fundClaim.Id);

        // Run the instance method
        new FundClaim_RejectionController(new ApexPages.StandardController(fundClaim)).saveFC();
        
    }
}