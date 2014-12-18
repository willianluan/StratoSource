@IsTest
private class FundClaim_CloseTest {
    public static FundClaim_Close instance {
        set;
        get;
    }
    
    public static testmethod void testConfirmUpdate() {
        Account account = new Account();
        account.Name = 'Account';
        insert account;
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = 100.00;
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
        
     //Changes made by AM   
        
        fundRequest.Oracle_Project_Code__c = '4609 - Non-Initiative Program';
        
    //End of changes made by AM  
        
        fundRequest.Total_Expenditure_of_Activity__c = 100.00;
        fundRequest.Estimated_Red_Hat_Funding_Requested__c = 100.00;
        fundRequest.Approval_Status__c = 'Pending First Approval';
        insert fundRequest;

        fundRequest.Approval_Status__c = 'Approved';
        update fundRequest;

        SFDC_MDF_Claim__c fundClaim = new SFDC_MDF_Claim__c();
        fundClaim.Account__c = mdf.Account_Master__c;
        fundClaim.Budget__c = mdf.Id;
        fundClaim.Fund_Request__c = fundRequest.Id;
        fundClaim.CurrencyIsoCode = 'EUR';
        fundClaim.Requested_Amount__c = 10.00;
        insert fundClaim;
        
        // Attach a proof of performance
        Attachment attachment = new Attachment();
        attachment.ParentId = fundClaim.Id;
        attachment.Name = 'Attachment';
        attachment.Body = Blob.valueOf('Attachment');
        insert attachment;
        
        // Move to pending approval
        fundClaim.Approval_Status__c = 'Pending First Approval';
        update fundClaim;
        
        // Move to approved
        fundClaim.Approval_Status__c = 'Approved';
        update fundClaim;

        instance = new FundClaim_Close(new ApexPages.StandardController(fundClaim));
        instance.upsertClosedClaim();
    }

}