@IsTest
private class FundRequest_ApprovalProcessTest {
	public static String getFiscalQuarter() {
		Integer month = Date.today().month();
		
		if (month >= 3 && month < 6)
		    return 'Q1'; 
        if (month >= 6 && month < 9)
            return 'Q2'; 
        if (month >= 9 && month < 12)
            return 'Q3'; 
        if (month >= 12 || month < 3)
            return 'Q4'; 
        return 'XX';
	}
	
	public static Date getFiscalQuarterStartDate() {
		String quarter = getFiscalQuarter();
		
		if ('Q1' == quarter)
		    return Date.newInstance(Date.today().year(), 3, 1);
        if ('Q2' == quarter)
            return Date.newInstance(Date.today().year(), 6, 1);
        if ('Q3' == quarter)
            return Date.newInstance(Date.today().year(), 9, 1);
            
        // Special handling for red hat's odd fiscal years
        if ('Q4' == quarter && Date.today().month() == 12)
            return Date.newInstance(Date.today().year() - 0, 12, 1);
        if ('Q4' == quarter)
            return Date.newInstance(Date.today().year() - 1, 12, 1);

        return null;
	}
	
    public static Date getFiscalQuarterEndDate() {
        String quarter = getFiscalQuarter();
        
        if ('Q1' == quarter)
            return Date.newInstance(Date.today().year(), 5, 30);
        if ('Q2' == quarter)
            return Date.newInstance(Date.today().year(), 8, 30);
        if ('Q3' == quarter)
            return Date.newInstance(Date.today().year(), 11, 30);
            
        // Special handling for red hat's odd fiscal years
        if ('Q4' == quarter && Date.today().month() == 12)
            return Date.newInstance(Date.today().year() + 1, 2, 28); // ignore leap year handling
        if ('Q4' == quarter)
            return Date.newInstance(Date.today().year() + 0 , 2, 28);

        return null;
    }
    
	public static void execute(String globalRegion, String subregion) {
        Account account = new Account();
        account.Name = 'Account';
        account.Global_Region__c = globalRegion;
        account.Subregion__c = subregion;
        insert account;
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = 100;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = getFiscalQuarter();
        mdf.Start_Date__c = getFiscalQuarterStartDate();
        mdf.End_Date__c = getFiscalQuarterEndDate();
        mdf.CurrencyIsoCode = 'USD';
        insert mdf;

        SFDC_MDF__c fundRequest = new SFDC_MDF__c();
        fundRequest.Account_Master__c = mdf.Account_Master__c;
        fundRequest.Budget__c = mdf.Id;
        fundRequest.CurrencyIsoCode = 'USD';
        fundRequest.Total_Expenditure_of_Activity__c = 100;
        fundRequest.Estimated_Red_Hat_Funding_Requested__c = 100;
        insert fundRequest;

		// Create an approval request for the fund request 
		    
		Approval.ProcessSubmitRequest approvalRequest1 = new Approval.ProcessSubmitRequest();
		approvalRequest1.setComments('Submitting fund request for approval.');
		approvalRequest1.setObjectId(fundRequest.Id);

        Approval.ProcessResult approvalResult1 = Approval.process(approvalRequest1);
        system.assert(approvalResult1.isSuccess());
        system.assertEquals('Pending', approvalResult1.getInstanceStatus(), 'Instance Status = ' + approvalResult1.getInstanceStatus());
        
		// First, get the ID of the newly created item 
		    
		List<Id> workitemIds = approvalResult1.getNewWorkitemIds();
		
		// Instantiate the new ProcessWorkitemRequest object and populate it 
		    
		Approval.ProcessWorkitemRequest approvalRequest2 = new Approval.ProcessWorkitemRequest();
		approvalRequest2.setComments('Approving request - step 1.');
		approvalRequest2.setAction('Approve');
		approvalRequest2.setNextApproverIds(new Id[] { UserInfo.getUserId() });
		
		// Use the ID from the newly created item to specify the item to be worked 
		    
		approvalRequest2.setWorkitemId(workitemIds.get(0));
		
		// Submit the request for approval 
		    
		Approval.ProcessResult approvalResult2 =  Approval.process(approvalRequest2);
		system.assert(approvalResult2.isSuccess(), 'Result Status = ' + approvalResult2.isSuccess());
		system.assertEquals('Approved', approvalResult2.getInstanceStatus(), 'Instance Status = ' + approvalResult2.getInstanceStatus());
	} 
	
    public static testmethod void testCancelation_EMEA() {}
}