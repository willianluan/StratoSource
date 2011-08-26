@IsTest
private class FundClaim_ApprovalProcessTest {
    public class ExpectedExceptionNotThrownException extends Exception {}
    
    public static CurrencyConverter currencyConverter = new CurrencyConverter();

    public static Decimal convert(String sourceCurrency, String targetCurrency, Decimal sourceAmount) {
        currencyConverter.setSourceCurrency(sourceCurrency);
        currencyConverter.setSourceAmount(sourceAmount);
        currencyConverter.setTargetCurrency(targetCurrency);
        return currencyConverter.getTargetAmountByCurrencyType();
    }
    
	public static void testProcess(String requestCurrency, Decimal requestAmount, String claimCurrency, Decimal claimAmount) {
        Integer currentQueries = 0;

        Account account = new Account();
        account.Name = 'Account';

        currentQueries = Limits.getQueries();
        insert account;
        system.assert(Limits.getQueries() - currentQueries <= 20, 'Excessive trigger SOQL queries detected');

        //
        // Create the MDF budget
        //
        
        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = requestAmount;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf.CurrencyIsoCode = requestCurrency;

        currentQueries = Limits.getQueries();
        insert mdf;		
        system.assert(Limits.getQueries() - currentQueries <= 20, 'Excessive trigger SOQL queries detected');

        //
        // Create the fund request
        //
        
        SFDC_MDF__c fundRequest = new SFDC_MDF__c();
        fundRequest.Account_Master__c = mdf.Account_Master__c;
        fundRequest.Budget__c = mdf.Id;
        fundRequest.CurrencyIsoCode = requestCurrency;
        fundRequest.Total_Expenditure_of_Activity__c = requestAmount;
        fundRequest.Estimated_Red_Hat_Funding_Requested__c = requestAmount;
        fundRequest.Approval_Status__c = 'Pending First Approval';

        currentQueries = Limits.getQueries();
        insert fundRequest;
        system.assert(Limits.getQueries() - currentQueries <= 20, 'Excessive trigger SOQL queries detected');

        //
        // Move fund request to approved
        //
        
        fundRequest.Approval_Status__c = 'Approved';

        currentQueries = Limits.getQueries();
        update fundRequest;
        system.assert(Limits.getQueries() - currentQueries <= 20, 'Excessive trigger SOQL queries detected');
        
        //
        // Create a fund claim
        //
        
        SFDC_MDF_Claim__c fundClaim = new SFDC_MDF_Claim__c();
        fundClaim.Account__c = mdf.Account_Master__c;
        fundClaim.Budget__c = mdf.Id;
        fundClaim.Fund_Request__c = fundRequest.Id;
        fundClaim.CurrencyIsoCode = claimCurrency;
        fundClaim.Requested_Amount__c = claimAmount;

        currentQueries = Limits.getQueries();
        insert fundClaim;
        system.assert(Limits.getQueries() - currentQueries <= 20, 'Excessive trigger SOQL queries detected');
        
        //
        // Attach a proof of performance
        //
        
        Attachment attachment = new Attachment();
        attachment.ParentId = fundClaim.Id;
        attachment.Name = 'Attachment';
        attachment.Body = Blob.valueOf('Attachment');
        insert attachment;
        
        //
        // Move to pending approval
        //
        
        fundClaim.Approval_Status__c = 'Pending First Approval';

        currentQueries = Limits.getQueries();
        update fundClaim;
        system.assert(Limits.getQueries() - currentQueries <= 20, 'Excessive trigger SOQL queries detected');
        
        //
        // Move to approved
        //
        
        fundClaim.Approval_Status__c = 'Approved';

        currentQueries = Limits.getQueries();
        update fundClaim;
        system.assert(Limits.getQueries() - currentQueries <= 20, 'Excessive trigger SOQL queries detected');	
    }
    
    // Scenario: 
    //
    // Create a budget in USD, a fund request in USD, and then a fund claim for the 
    // equivilent amount in EUR. Should not fail.
    //
    
    public static testmethod void testFundRequest_USD_FundClaim_EUR_IsBelowThreshold() {
        testProcess('USD', 100, 'EUR', convert('USD', 'EUR', 90));
    }

    public static testmethod void testFundRequest_USD_FundClaim_EUR_IsAtThreshold() {
        testProcess('USD', 100, 'EUR', convert('USD', 'EUR', 100));
    }

    public static testmethod void testFundRequest_USD_FundClaim_EUR_IsAboveThreshold() {
        try {
            testProcess('USD', 100, 'EUR', convert('USD', 'EUR', 105));
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Request Amount is less than the Estimated Red Hat Funding Requested on the Fund Request.'));
        }
    }

    // Scenario: 
    //
    // Create a budget in USD, a fund request in USD, and then a fund claim for the 
    // more than requested amount in USD. Should fail.
    //
    
    public static testmethod void testFundRequest_USD_FundClaim_USD_IsAboveThreshold_01() {
        try {
            testProcess('USD', 100, 'USD', 101);
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Request Amount is less than the Estimated Red Hat Funding Requested on the Fund Request.'));
        }
    }

    public static testmethod void testFundRequest_USD_FundClaim_USD_IsAboveThreshold_05() {
        try {
            testProcess('USD', 100, 'USD', 105);
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Request Amount is less than the Estimated Red Hat Funding Requested on the Fund Request.'));
        }
    }

    public static testmethod void testFundRequest_USD_FundClaim_USD_IsAboveThreshold_99() {
        try {
            testProcess('USD', 100, 'USD', 199);
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Request Amount is less than the Estimated Red Hat Funding Requested on the Fund Request.'));
        }
    }

}