@IsTest
private class FundRequest_CancelTest {
    public static FundRequest_Cancel instance {
        set;
        get;
    }
    
    public static void testConfirmUpdate(String globalRegion, String accountTeamMemberRole) {
        testConfirmUpdate(globalRegion, null, accountTeamMemberRole);
    }
       
    public static void testConfirmUpdate(String globalRegion, String subregion, String accountTeamMemberRole) {
        User user = [
             select Id
               from User
              where IsActive = true
              limit 1
        ];
        
        Account account = new Account();
        account.Name = 'Account';
        account.Global_Region__c = globalRegion;
        account.Subregion__c = subregion;
        insert account;
        
        AccountTeamMember accountTeamMember = new AccountTeamMember(AccountId = account.Id);
        accountTeamMember.UserId = user.Id;
        accountTeamMember.TeamMemberRole = accountTeamMemberRole;
        insert accountTeamMember;

        AccountShare accountShare = new AccountShare(AccountId = account.Id);
        accountShare.AccountAccessLevel = 'Edit';
        accountShare.OpportunityAccessLevel = 'None';
        accountShare.CaseAccessLevel = 'None';
        accountShare.UserOrGroupId = user.Id;
        insert accountShare;
        
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
        mdf.Channel_Account_Manager__c = user.Id;
        mdf.Channel_Marketing_Manager_Country__c = user.Id;
        mdf.Channel_Sales_Manager__c = user.Id;
        mdf.Marketing_Program_Manager__c = user.Id;
        mdf.Inside_Channel_Account_Manager__c = user.Id;
        insert mdf;
        
        SFDC_MDF__c fundRequest = new SFDC_MDF__c();
        fundRequest.Account_Master__c = mdf.Account_Master__c;
        fundRequest.Budget__c = mdf.Id;
        fundRequest.CurrencyIsoCode = 'USD';
        fundRequest.Total_Expenditure_of_Activity__c = 150.00;
        
    //Changes made by AM   
        
        fundRequest.Oracle_Project_Code__c = '4609 - Non-Initiative Program';
        
    //End of changes made by AM  
        
                
        fundRequest.Estimated_Red_Hat_Funding_Requested__c = 100.00;
        fundRequest.Approval_Status__c = 'Pending First Approval';
        fundRequest.Channel_Account_Manager__c = user.Id;
        fundRequest.Channel_Marketing_Manager_Country__c = user.Id;
        fundRequest.Marketing_Program_Manager__c = user.Id;
        fundRequest.Inside_Channel_Account_Manager__c = user.Id;
        insert fundRequest;

        fundRequest.Approval_Status__c = 'Approved';
        update fundRequest;

        instance = new FundRequest_Cancel(new ApexPages.StandardController(fundRequest));

        PageReference pageReference = instance.save();
        
        system.assertEquals(0, ApexPages.getMessages().size(), ApexPages.getMessages());
        system.assert(null != pageReference, 'Internal method must have failed.');
        
        system.assertEquals('Pending Cancellation', [
            select Approval_Status__c
              from SFDC_MDF__c
             where Id = :fundRequest.Id
        ].Approval_Status__c, 'Approval Status on Fund Request was not marked as Pending Cancellation.');
    }

    public static testmethod void testConfirmUpdate_NA() {
        testConfirmUpdate('NA', 'Channel Account Manager');
    }

    public static testmethod void testConfirmUpdate_NA_FedSled() {
        testConfirmUpdate('NA', 'Fed Sled', 'Marketing Program Manager');
    }

    public static testmethod void testConfirmUpdate_EMEA() {
        testConfirmUpdate('EMEA', 'Channel Marketing Manager - Country');
    }

    /* LATAM does not yet have an MDF cancellation process
     *
    public static testmethod void testConfirmUpdate_LATAM() {
        testConfirmUpdate('LATAM', 'Channel Account Manager');
    }
     */

    public static testmethod void testConfirmUpdate_APAC_GreaterChina() {
        testConfirmUpdate('APAC', 'Greater China', 'Channel Account Manager');
    }

    public static testmethod void testConfirmUpdate_APAC_Korea() {
        testConfirmUpdate('APAC', 'Korea', 'Channel Account Manager');
    }

    public static testmethod void testConfirmUpdate_APAC_Japan() {
        testConfirmUpdate('APAC', 'Japan', 'Channel Account Manager');
    }
}