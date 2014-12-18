@IsTest
private class FundClaim_IsNumberOfAttendeesReqTest {
	public static final String EXPECTED_MSG = 'Based on the Activity Type selected, the Number of Attendees field is required. Please fill out to continue.';
    public class ExpectedExceptionNotThrownException extends Exception {}

    public static void executeWithException(String activityType, String globalRegion, Integer attendees) {
        try {
            execute(activityType, globalRegion, attendees);
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getMessage().contains(EXPECTED_MSG), e.getMessage());
        }
    }

    public static void execute(String activityType, String globalRegion, Integer attendees) {
        Integer currentQueries = 0;
        Integer requestAmount = 100;
        String requestCurrency = 'USD';
        Integer claimAmount = 100;
        String claimCurrency = 'USD';

        Account account = new Account();
        account.Name = 'Account';
        account.Global_Region__c = globalRegion;
        
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
        fundRequest.Activity_Type__c = activityType;

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
        fundClaim.Number_of_Attendees__c = attendees;

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
    
    // APAC tests

    public static testmethod void testRegionAPAC_WithAttendeesNull() {
        execute(null, 'APAC', null);
    }
     
    public static testmethod void testRegionAPAC_WithAttendeesZero() {
        execute(null, 'APAC', 0);
    }

    public static testmethod void testRegionAPAC_WithAttendeesNull_AchievingTrainingSkills() {
        executeWithException('Achieving Training Skills', 'APAC', null);
    }

    public static testmethod void testRegionAPAC_WithAttendeesNull_BuildingDemoCenter() {
        executeWithException('Building a Lab/Demo Center with Red Hat Solution Demonstration Capabilities', 'APAC', null);
    }

    public static testmethod void testRegionAPAC_WithAttendeesNull_ConductingJointCustomerVisits() {
        executeWithException('Conducting Joint Customer Visits with Red Hat on New Customers and Registering a Deal/Opportunity', 'APAC', null);
    }

    public static testmethod void testRegionAPAC_WithAttendeesNull_ConductingWebinars() {
        executeWithException('Conducting Webinars', 'APAC', null);
    }

    public static testmethod void testRegionAPAC_WithAttendeesNull_NonMatching() {
        execute('Non-Validated Activity Type', 'APAC', null);
    }

    public static testmethod void testRegionAPAC_WithAttendeesZero_AchievingTrainingSkills() {
        execute('Achieving Training Skills', 'APAC', 0);
    }

    public static testmethod void testRegionAPAC_WithAttendeesZero_BuildingDemoCenter() {
        execute('Building a Lab/Demo Center with Red Hat Solution Demonstration Capabilities', 'APAC', 0);
    }

    public static testmethod void testRegionAPAC_WithAttendeesZero_ConductingJointCustomerVisits() {
        execute('Conducting Joint Customer Visits with Red Hat on New Customers and Registering a Deal/Opportunity', 'APAC', 0);
    }

    public static testmethod void testRegionAPAC_WithAttendeesZero_ConductingWebinars() {
        execute('Conducting Webinars', 'APAC', 0);
    }

    public static testmethod void testRegionAPAC_WithAttendeesZero_NonMatching() {
        execute('Non-Validated Activity Type', 'APAC', 0);
    }

    // NA tests

    public static testmethod void testRegionNA_WithAttendeesNull() {
        execute(null, 'NA', null);
    }
     
    public static testmethod void testRegionNA_WithAttendeesZero() {
        execute(null, 'NA', 0);
    }

    public static testmethod void testRegionNA_WithAttendeesNull_AchievingTrainingSkills() {
        executeWithException('Achieving Training Skills', 'NA', null);
    }

    public static testmethod void testRegionNA_WithAttendeesNull_BuildingDemoCenter() {
        executeWithException('Building a Lab/Demo Center with Red Hat Solution Demonstration Capabilities', 'NA', null);
    }

    public static testmethod void testRegionNA_WithAttendeesNull_ConductingJointCustomerVisits() {
        executeWithException('Conducting Joint Customer Visits with Red Hat on New Customers and Registering a Deal/Opportunity', 'NA', null);
    }

    public static testmethod void testRegionNA_WithAttendeesNull_ConductingWebinars() {
        executeWithException('Conducting Webinars', 'NA', null);
    }

    public static testmethod void testRegionNA_WithAttendeesNull_NonMatching() {
        execute('Non-Validated Activity Type', 'NA', null);
    }

    public static testmethod void testRegionNA_WithAttendeesZero_AchievingTrainingSkills() {
        execute('Achieving Training Skills', 'NA', 0);
    }

    public static testmethod void testRegionNA_WithAttendeesZero_BuildingDemoCenter() {
        execute('Building a Lab/Demo Center with Red Hat Solution Demonstration Capabilities', 'NA', 0);
    }

    public static testmethod void testRegionNA_WithAttendeesZero_ConductingJointCustomerVisits() {
        execute('Conducting Joint Customer Visits with Red Hat on New Customers and Registering a Deal/Opportunity', 'NA', 0);
    }

    public static testmethod void testRegionNA_WithAttendeesZero_ConductingWebinars() {
        execute('Conducting Webinars', 'NA', 0);
    }

    public static testmethod void testRegionNA_WithAttendeesZero_NonMatching() {
        execute('Non-Validated Activity Type', 'NA', 0);
    }

    // LATAM tests

    public static testmethod void testRegionLATAM_WithAttendeesNull() {
        execute(null, 'LATAM', null);
    }
     
    public static testmethod void testRegionLATAM_WithAttendeesZero() {
        execute(null, 'LATAM', 0);
    }

    public static testmethod void testRegionLATAM_WithAttendeesNull_AchievingTrainingSkills() {
        executeWithException('Achieving Training Skills', 'LATAM', null);
    }

    public static testmethod void testRegionLATAM_WithAttendeesNull_BuildingDemoCenter() {
        executeWithException('Building a Lab/Demo Center with Red Hat Solution Demonstration Capabilities', 'LATAM', null);
    }

    public static testmethod void testRegionLATAM_WithAttendeesNull_ConductingJointCustomerVisits() {
        executeWithException('Conducting Joint Customer Visits with Red Hat on New Customers and Registering a Deal/Opportunity', 'LATAM', null);
    }

    public static testmethod void testRegionLATAM_WithAttendeesNull_ConductingWebinars() {
        executeWithException('Conducting Webinars', 'LATAM', null);
    }

    public static testmethod void testRegionLATAM_WithAttendeesNull_NonMatching() {
        execute('Non-Validated Activity Type', 'LATAM', null);
    }

    public static testmethod void testRegionLATAM_WithAttendeesZero_AchievingTrainingSkills() {
        execute('Achieving Training Skills', 'LATAM', 0);
    }

    public static testmethod void testRegionLATAM_WithAttendeesZero_BuildingDemoCenter() {
        execute('Building a Lab/Demo Center with Red Hat Solution Demonstration Capabilities', 'LATAM', 0);
    }

    public static testmethod void testRegionLATAM_WithAttendeesZero_ConductingJointCustomerVisits() {
        execute('Conducting Joint Customer Visits with Red Hat on New Customers and Registering a Deal/Opportunity', 'LATAM', 0);
    }

    public static testmethod void testRegionLATAM_WithAttendeesZero_ConductingWebinars() {
        execute('Conducting Webinars', 'LATAM', 0);
    }

    public static testmethod void testRegionLATAM_WithAttendeesZero_NonMatching() {
        execute('Non-Validated Activity Type', 'LATAM', 0);
    }

    // EMEA tests

    public static testmethod void testRegionEMEA_WithAttendeesNull() {
        execute(null, 'EMEA', null);
    }
     
    public static testmethod void testRegionEMEA_WithAttendeesZero() {
        execute(null, 'EMEA', 0);
    }

    public static testmethod void testRegionEMEA_WithAttendeesNull_AchievingTrainingSkills() {
        execute('Achieving Training Skills', 'EMEA', null);
    }

    public static testmethod void testRegionEMEA_WithAttendeesNull_BuildingDemoCenter() {
        execute('Building a Lab/Demo Center with Red Hat Solution Demonstration Capabilities', 'EMEA', null);
    }

    public static testmethod void testRegionEMEA_WithAttendeesNull_ConductingJointCustomerVisits() {
        execute('Conducting Joint Customer Visits with Red Hat on New Customers and Registering a Deal/Opportunity', 'EMEA', null);
    }

    public static testmethod void testRegionEMEA_WithAttendeesNull_ConductingWebinars() {
        execute('Conducting Webinars', 'EMEA', null);
    }

    public static testmethod void testRegionEMEA_WithAttendeesNull_NonMatching() {
        execute('Non-Validated Activity Type', 'EMEA', null);
    }

    public static testmethod void testRegionEMEA_WithAttendeesZero_AchievingTrainingSkills() {
        execute('Achieving Training Skills', 'EMEA', 0);
    }

    public static testmethod void testRegionEMEA_WithAttendeesZero_BuildingDemoCenter() {
        execute('Building a Lab/Demo Center with Red Hat Solution Demonstration Capabilities', 'EMEA', 0);
    }

    public static testmethod void testRegionEMEA_WithAttendeesZero_ConductingJointCustomerVisits() {
        execute('Conducting Joint Customer Visits with Red Hat on New Customers and Registering a Deal/Opportunity', 'EMEA', 0);
    }

    public static testmethod void testRegionEMEA_WithAttendeesZero_ConductingWebinars() {
        execute('Conducting Webinars', 'EMEA', 0);
    }

    public static testmethod void testRegionEMEA_WithAttendeesZero_NonMatching() {
        execute('Non-Validated Activity Type', 'EMEA', 0);
    }
}