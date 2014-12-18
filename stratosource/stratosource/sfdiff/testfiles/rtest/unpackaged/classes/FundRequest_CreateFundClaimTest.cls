@IsTest
private class FundRequest_CreateFundClaimTest {
    public static testmethod void testConstructor() {
        new FundRequest_CreateFundClaim(new ApexPages.StandardController(new SFDC_MDF__c()));
    }

    public static testmethod void testGetFundRequest() {
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
        fundRequest.Total_Expenditure_of_Activity__c = 100.00;
        fundRequest.Estimated_Red_Hat_Funding_Requested__c = 100.00;
        insert fundRequest;
        
        FundRequest_CreateFundClaim instance = new FundRequest_CreateFundClaim(new ApexPages.StandardController(fundRequest));
        system.assert(null != instance.fundRequest, 'FundRequest property on instance is null.');
        system.assertEquals(fundRequest.Id, instance.fundRequest.Id);
        system.assertEquals(fundRequest.Account_Master__c, instance.fundRequest.Account_Master__c);
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
        fundRequest.Approval_Status_Partner__c = 'Approved'; // critical part
        insert fundRequest;
        
        system.assertEquals('Approved', [
            select Approval_Status_Partner__c
              from SFDC_MDF__c
             where Id = :fundRequest.Id
        ].Approval_Status_Partner__c, 'Approval_Status_Partner__c != Approved, as expected.');
        
        system.assert(null != new FundRequest_CreateFundClaim(new ApexPages.StandardController(fundRequest)).confirmUpdate());
    }

}