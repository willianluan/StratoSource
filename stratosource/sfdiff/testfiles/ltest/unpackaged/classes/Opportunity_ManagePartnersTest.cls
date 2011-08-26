/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Opportunity_ManagePartnersTest {
	static Opportunity opportunity {
		get {
			if(opportunity == null)
			{
                RecordType recordType = [select Id,name from RecordType where name = 'Strategic' and SObjectType = 'Account' limit 1];
                Account account = new Account(name='account',RecordTypeId=recordType.Id,AccountClassification__c=recordType.name);
                insert account;
                account.RecordType = recordType;
                User xuser = [select Id from User where userRole.Name='EMEA Sales' limit 1];
                RecordType recordType2 = [select Id,name from RecordType where name like 'EMEA %' and SObjectType = 'Opportunity' limit 1];
                opportunity = new Opportunity(Name='Opportunity_ManagePartnersTest Test',
                    CloseDate=System.today(),StageName='Unqualified',
                    Owner=xuser,// DateOrderSubmitted__c=Datetime.newInstance(2009,1,1),
                    AccountId=account.Id,Country_of_Order__c='India',FulfillmentChannel__c='Direct - OEM',
                    RecordTypeId = recordType2.Id);
                insert opportunity;
                opportunity.RecordType = recordType2;
                opportunity.Account = account;
			}
			return opportunity;
		}
	}
	
	static OpportunityPartner__c oppPartner {
		get {
			if(oppPartner == null)
			{
                 Classification__c pType = null;
                 Classification__c pTier = null;
				 for(Classification__c c : [select Name from Classification__c where Name in ('Partner Type','Partner Tier') and Parent__c = null])
				 {
				 	  if(c.Name == 'Partner Type')
				 	  {
				 	  	  pType = c;
				 	  }
                      else if(c.Name == 'Partner Tier')
                      {
                          pTier = c;
                      }
				 }
				 if(pType == null)
				 {
				 	 pType=new Classification__c(Name='Partner Type');
				     insert pType;
				 }
                 if(pTier == null)
                 {
                     pTier = new Classification__c(Name='Partner Tier');
                     insert pTier;
                 }
				 Classification__c cTier = new Classification__c(Name='Child Tier',Parent__c=pTier.Id);
                 Classification__c cType = new Classification__c(Name='Child Type',Parent__c=pType.Id);
				 insert new List<Classification__c>{cTier,cType};
			     oppPartner = new OpportunityPartner__c(
			         Opportunity__c = opportunity.Id,
			         PartnerTier__c = cTier.Id,
			         PartnerType__c = cType.Id,
			         Partner__c = opportunity.AccountId,
			         RelationshipType__c = 'Financial'
			         );
			     insert oppPartner;
			}
			return oppPartner;
		}
	}
	
	static testMethod void testOppPartner()
	{
		System.assertNotEquals(null,oppPartner.Id);
	}

    static testMethod void testFinancialPartnerRequired()
    {
    	System.assertEquals(true,Opportunity_ManagePartners.isFinancialPartnerRequired(opportunity.Id));
    }

    static testMethod void testMessages() {
        System.assertEquals(false,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.ERROR));
        System.assertEquals(false,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.CONFIRM));
    	Opportunity_ManagePartners.addExceptionMessage('test');
    	System.assertEquals(true,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.ERROR));
    	Opportunity_ManagePartners.addConfirmationMessage();
        System.assertEquals(true,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.CONFIRM));
    }
    
    static testMethod void testCoverageTestStatic() {
    	for(String region : new List<String>{'APAC','EMEA','LATAM','NA'})
    	{
    		System.assertEquals(true,Opportunity_ManagePartners.accountRecordTypeIdByRegion.containsKey(region));    		
    	}
    	System.assertNotEquals(null,Opportunity_ManagePartners.completePartnerTierList);
        Id id = Opportunity_ManagePartners.rootPartnerTierId;
        System.assertNotEquals(null,Opportunity_ManagePartners.partnerTierMap);
        System.assertNotEquals(null,Opportunity_ManagePartners.completePartnerTypeList);
        id = Opportunity_ManagePartners.rootPartnerTypeId;
        System.assertNotEquals(null,Opportunity_ManagePartners.partnerTypeMap);
//        System.assertNotEquals(null,Opportunity_ManagePartners.relationshipTypePicklistentryList);
        System.assertNotEquals(null,Opportunity_ManagePartners.completePartnerStatusLists);
        System.assertNotEquals(null,Opportunity_ManagePartners.partnerStatusMaps);
//        System.assertNotEquals(null,Opportunity_ManagePartners.relationshipTypeMap);
    }
    
    static testMethod void testController() {
        ApexPages.StandardController controller = new ApexPages.StandardController(opportunity);
        Opportunity_ManagePartners extension = new Opportunity_ManagePartners(controller);
        System.assertEquals(opportunity.Id,extension.opportunity.Id);
        System.assertEquals(true,extension.isFinancialPartnerRequired);
        System.assertEquals(opportunity.AccountId,extension.account.Id);
        System.assertNotEquals(0,extension.relationshipTypeOptions.size());
        System.assertEquals(true,extension.getHasAvailableRelationshipTypeOptions());
        //System.assertEquals(false,extension.isEdit);
        extension.insertOpportunityPartner();
        System.assertNotEquals(0,extension.partnerInfoList.size());
        System.assertEquals(true,extension.isEdit);
        extension.editSelected();
        extension.cancelEdit(extension.partnerInfoList.get(0).id);
        //System.assertEquals(false,extension.isEdit);
        extension.insertOpportunityPartner();
        extension.cancel();
        Boolean b = extension.partnerInfoListIsEmpty;
        extension.saveOpportunityPartnerListAndInsert();
        extension.saveOpportunityPartnerListAndReturn();
        extension.removeSelected();
    }
    
    static testMethod void testControllerSave() {
        ApexPages.StandardController controller = new ApexPages.StandardController(opportunity);
        Opportunity_ManagePartners extension = new Opportunity_ManagePartners(controller);
        extension.insertOpportunityPartner();
        System.assertEquals(false,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.ERROR));
        extension.saveOpportunityPartnerListAndReturn();
        //System.assertEquals(true,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.ERROR));
    }
    
    static testMethod void testPartnerInfoCoverage() {
        ApexPages.StandardController controller = new ApexPages.StandardController(opportunity);
        Opportunity_ManagePartners extension = new Opportunity_ManagePartners(controller);
        extension.insertOpportunityPartner();
        Opportunity_PartnerInfo partnerInfo = extension.partnerInfoList.get(0);
        OpportunityPartner__c opportunityPartner = partnerInfo.getOpportunityPartner();
        System.assertEquals(true,partnerInfo.isSelected);
        System.assertEquals(true,partnerInfo.isEdit);
        System.assertEquals(true,partnerInfo.isNew);
        partnerInfo.isRequired = false;
        System.assertEquals(false,partnerInfo.isRequired);
        PartnerStatus__c partnerStatus = partnerInfo.partnerStatus;
        Id id = partnerInfo.partnerStatusId;
        id = partnerInfo.partnerTierId;
        String partnerTierName = partnerInfo.getPartnerTierName();
        id = partnerInfo.partnerTypeId;
        id = partnerInfo.partnerSubTypeId;
        String partnerTypeName = partnerInfo.getPartnerTypeName();
        String partnerSubTypeName = partnerInfo.getPartnerSubTypeName();
        System.assertNotEquals(null,partnerInfo.partnerTypeOptions);
        System.assertNotEquals(null,partnerInfo.partnerTierOptions);
        System.assertNotEquals(null,partnerInfo.partnerSubTypeOptions);
        System.assertNotEquals(null,partnerInfo.getPartnerOptions());
        System.assertEquals(false,partnerInfo.showAllRegions);
        partnerInfo.updateRelationshipType();
        partnerInfo.updateShowAllRegions();
        partnerInfo.updatePartnerType();
        partnerInfo.updatePartnerTier();
        partnerInfo.updatePartnerSubType();
        partnerInfo.cancelEdit();
    }    
}