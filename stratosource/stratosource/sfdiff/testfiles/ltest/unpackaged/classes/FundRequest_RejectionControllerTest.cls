@IsTest
private class FundRequest_RejectionControllerTest {
    public static testmethod void testRejectionController() {
        Account account = new Account();
        account.Name = 'Account';
        account.isAccountActive__c = true;
        insert account;
        
        RecordType recordType = [
            select Id 
              from RecordType 
             where Name = 'MDF' 
               and SobjectType = 'SFDC_Budget__c'
        ];    
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'MDF';
        mdf.Account_master__c = account.Id;
        mdf.Active__c = true;
        mdf.RecordTypeId = recordType.Id;
        mdf.Allocated_Budget__c = 100;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = 'Q3';
        mdf.Start_Date__c = Date.newInstance(2009, 9, 1);
        mdf.End_Date__c = Date.newInstance(2009, 11, 30);
        insert mdf;
                        
        SFDC_MDF__c fundRequest = new SFDC_MDF__c();
        fundRequest.Name = 'Fund Request';
        fundRequest.Account_master__c = account.Id;
        fundRequest.Budget__c = mdf.Id;
        fundRequest.Total_Expenditure_of_Activity__c = 100;
        fundRequest.Estimated_Red_Hat_Funding_Requested__c = 100;
        insert fundRequest;
        
        FundRequest_RejectionController controller = new FundRequest_RejectionController(new ApexPages.StandardController(fundRequest));
        controller.saveRejectionReason();
   }
}