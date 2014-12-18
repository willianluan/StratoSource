public with sharing class Opportunity_ManagePartners {
	public static final String FINANCIAL = 'Financial';
	public static final String INFLUENCING = 'Influencing';
	public static final String OTHER = 'Other';
	public static final String PARTNER_TIER_ROOTNAME = 'Partner Tier';
	public static final String PARTNER_TYPE_ROOTNAME = 'Partner Type';
	// this value needs to be true if the reseller validation rules are activated
	public static Boolean RESELLER_REQUIRED = false;
	public static final Set<String> FINANCIAL_PARTNER_CHANNELS = new Set<String>{
		'Direct – OEM', 'Direct - OEM', 'Direct - VAR/VAD',
		'Indirect – OEM Preload', 'Indirect - OEM Preload',
		'Indirect - VAR/VAD', 'Indirect – VAR/VAD',
		'Direct - Carahsoft', 'Direct - DLT', 'Direct - GTSI' };	
    public static final Set<String> NO_FINANCIAL_PARTNER_CHANNELS = new Set<String>{
        'Direct - End Customer', 'Indirect - Internal Commissions Credit',
        'Indirect – Webstore', 'Indirect - Webstore' };
    public static final Set<String> NA_EMEA_RESELLER_PARTNER_CHANNELS = new Set<String>{
        'Indirect - VAR/VAD', 'Indirect – VAR/VAD' };
    public static final Set<String> NA_RESELLER_PARTNER_CHANNELS = new Set<String>{
    	'Indirect – OEM Preload', 'Indirect - OEM Preload',
        'Indirect - VAR/VAD', 'Indirect – VAR/VAD',
        'Indirect - Internal Commissions Credit',
        'Indirect - Visible Renewals' };
    public static final Set<String> NA_RESELLER_PROFILE_NAME_EXCLUDES = new Set<String>{
        'NA Business Affairs', 'NA Fed Bus Dev',
        'NA Partner Portal Strategic License', 'NA Sales - EDU DLT',      
        'NA Sales - FED SLED' };
    public static Set<Id> NA_RESELLER_PROFILE_IDS {
    	get {
    		if(NA_RESELLER_PROFILE_IDS == null)
    		{
    		    NA_RESELLER_PROFILE_IDS = (new Map<Id,Profile>([
                    select Id from Profile 
                    where (Name like 'NA %' or Name like 'NA-%' or Name like '% NA %') and
                        (not Name in :NA_RESELLER_PROFILE_NAME_EXCLUDES) ])).keySet();
    		}
    		return NA_RESELLER_PROFILE_IDS;
    	}
    }
    
    public static Set<Id> NA_EMEA_USER_ROLE_IDS {
        get {
        	if(NA_EMEA_USER_ROLE_IDS == null)
        	{
        	    NA_EMEA_USER_ROLE_IDS = (new Map<Id,Profile>()).keySet();
        	}
        	return NA_EMEA_USER_ROLE_IDS;
        }
    }
    
	public static final Map<String,Schema.RecordTypeInfo> accountRecordTypeInfosByName =
		Account.SObjectType.getDescribe().getRecordTypeInfosByName();
	private static final Map<String,PartnerStatus__c> partnerStatusByRegion = new Map<String,PartnerStatus__c>();
		
	// A default limit of 1 is applied.  So we only need to specify the limits
	// for values allowed more than 1 record.
	public static Map<String,Integer> RELATIONAL_TYPE_LIMITS = new Map<String,Integer> {
		INFLUENCING=>5
	};
	
	//
	// private vars
	//	
	private ApexPages.StandardController controller;
		
	
	public Opportunity_ManagePartners(ApexPages.StandardController controller)
	{
		this.controller = controller;
	}
   
    public static Boolean isFinancialPartnerRequired(Opportunity opp)
    {
        return (
            (opp.FinancialPartnerName__c == null || opp.FinancialPartnerName__c == '') 
            && (! opp.StageName.startsWith('Closed'))
            && FINANCIAL_PARTNER_CHANNELS.contains(opp.FulfillmentChannel__c));
    }
    
    public static Boolean isFinancialPartnerRequired(Id oppId)
    {
        return isFinancialPartnerRequired([select FinancialPartnerName__c, FulfillmentChannel__c, StageName from Opportunity where Id = :oppId]);
    }
	
	// standard page methods
	private static String getPageParam(String name)
	{
		return ApexPages.currentPage().getParameters().get(name);
	}
	
	private static void addMessage(ApexPages.Severity severity, String message) {
		ApexPages.addMessage(new ApexPages.Message(severity, message));
	}
	
	private static void addMessage(String message)
	{
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
	}
	
	public static void addExceptionMessage(Exception e)
	{
		ApexPages.addMessages(e);
	}

	public static void addExceptionMessage(String message)
	{
		addMessage(ApexPages.Severity.ERROR, message);
	}

	public static void addConfirmationMessage()
	{
		addMessage(ApexPages.Severity.CONFIRM, 'Changes have been saved successfully.');
	}
	
	public static Boolean hasMessages(ApexPages.Severity severity)
	{
		for(ApexPages.Message message : ApexPages.getMessages())
		{
			if (message.getSeverity() == severity)
			{
				return true;
			}
		}
		return false;
	}
	
	private static List<Classification__c> getClassificationList(String rootName)
	{
		return [
			select 
			  Id,
			  Hierarchy__c, 
              Name, 
			  HierarchyDepth__c, 
			  Descendents__c,
			  Parent__c
			from Classification__c
			where IsActive__c = true and HierarchyRootName__c = :rootName
			order by Hierarchy__c asc ];
	}

	public static Map<String,Set<Id>> accountRecordTypeIdByRegion {
		get {
			if(accountRecordTypeIdByRegion == null)
			{
				Map<String,Set<Id>> retval = new Map<String,Set<Id>>();
				for(String name :  accountRecordTypeInfosByName.keySet())
				{
					Schema.RecordTypeInfo accountRecordTypeInfo = accountRecordTypeInfosByName.get(name);
					String region = name;
					if(name.startsWith('APAC '))
					{
						region = 'APAC';
					}
					else if(name.startsWith('EMEA '))
					{
						region = 'EMEA';
					}
					else if(name.startsWith('LATAM '))
					{
						region = 'LATAM';
					}
					else if(name.startsWith('NA '))
					{
						region = 'NA';
					}
					Set<Id> idSet = retval.get(region);
					if(idSet == null)
					{
						idSet = new Set<Id>();
						retval.put(region,idSet);
					}
					idSet.add(accountRecordTypeInfo.getRecordTypeId());
				}
				accountRecordTypeIdByRegion = retval;
			}
			return accountRecordTypeIdByRegion;
		}
	}
	
	public static List<Classification__c>  completePartnerTierList {
		get {
			if(completePartnerTierList == null)
			{
				completePartnerTierList = getClassificationList(PARTNER_TIER_ROOTNAME);
			}
			return completePartnerTierList;
		}
	}
	
	public static Id rootPartnerTierId {
		get {
			if(rootPartnerTierId == null)
			{
				Id retval = null;
				if(! completePartnerTierList.isEmpty())
				{
					retval = completePartnerTierList.get(0).Id;
				}
				rootPartnerTierId = retval;
			}
			return rootPartnerTierId;
		}
	}
	
	public static Map<Id,Classification__c> partnerTierMap {
		get {
			if(partnerTierMap == null)
			{
				partnerTierMap = new Map<Id,Classification__c>(completePartnerTierList);
			}
			return partnerTierMap;
		}
	}
	
	public static List<Classification__c>  completePartnerTypeList {
		get {
			if(completePartnerTypeList == null)
			{
				completePartnerTypeList = getClassificationList(PARTNER_TYPE_ROOTNAME);
			}
			return completePartnerTypeList;
		}
	}
	
	public static Id rootPartnerTypeId {
		get {
			if(rootPartnerTypeId == null)
			{
				Id retval = null;
				if(! completePartnerTypeList.isEmpty())
				{
					retval = completePartnerTypeList.get(0).Id;
				}
				rootPartnerTypeId = retval;
			}
			return rootPartnerTypeId;
		}
	}
	
	public static Map<Id,Classification__c> partnerTypeMap {
		get {
			if(partnerTypeMap == null)
			{
				partnerTypeMap = new Map<Id,Classification__c>(completePartnerTypeList);
			}
			return partnerTypeMap;
		}
		set;
	}
	
	private static List<Schema.Picklistentry> relationshipTypePicklistentryList {
		get {
			if(relationshipTypePicklistentryList == null)
			{
				relationshipTypePicklistentryList = OpportunityPartner__c.RelationshipType__c.getDescribe().getPicklistValues();
			}
			return relationshipTypePicklistentryList;
		}
	}
	
	public static List<List<PartnerStatus__c>> completePartnerStatusLists {
		get {
			if(completePartnerStatusLists == null)
			{
				final List<List<PartnerStatus__c>> retval = new List<List<PartnerStatus__c>>();
				List<PartnerStatus__c> currentList;
				Set<Id> excludedIds = new Set<Id>();
				for(String previousName='';;)
				{
					Integer rowsToQuery = 1000;
					Integer currentLimit = Limits.getLimitQueryRows()-Limits.getQueryRows();
					if(currentLimit-20 < rowsToQuery)
					{
						rowsToQuery = currentLimit-20;
					}
					if(rowsToQuery >= 1)
					{
					   currentList = [
						  select Id, 
							   Partner__c, 
							   Partner__r.Name,
							   Partner__r.RecordTypeId,
							   PartnerTier__c,
							   PartnerTier__r.Hierarchy__c,
                               PartnerTier__r.Name,
							   PartnerType__c,
							   PartnerType__r.Hierarchy__c,
                               PartnerType__r.Name
						  from PartnerStatus__c
						 where ActivationStatus__c = 'Active'
						       and PartnerTier__c != null
						       and PartnerType__c != null
						       and Partner__c != null
							   and Partner__r.Name >= :previousName
							   and (not Id in :excludedIds)
					  order by Partner__r.Name asc,
							   PartnerTier__r.Hierarchy__c asc,
							   PartnerType__r.Hierarchy__c asc limit :rowsToQuery ];
					}
					if(rowsToQuery < 1 || currentList.isEmpty())
					{
						  break;
					}
					retval.add(currentList);
					previousName = currentList.get(currentList.size()-1).Partner__r.Name;
					excludedIds.clear();
					for(Integer i=currentList.size();i-- > 0;)
					{
						PartnerStatus__c p = currentList.get(i);
						if(p.Partner__r.Name != previousName)
						{
							break;
						}
						excludedIds.add(p.Id);
					}
				}
				completePartnerStatusLists = retval;
			}
			return completePartnerStatusLists;
		}
	}
	
	public static List<Map<Id,PartnerStatus__c>> partnerStatusMaps {
		get {
			if(partnerStatusMaps == null)
			{
				final List<Map<Id,PartnerStatus__c>> retval = new List<Map<Id,PartnerStatus__c>>();
				for(List<PartnerStatus__c> partnerStatusList : completePartnerStatusLists)
				{
					retval.add(new Map<Id,PartnerStatus__c>(partnerStatusList));
				}
				partnerStatusMaps = retval;
			}
			return partnerStatusMaps;
		}
	}
		
	private Map<String,Integer> relationshipTypeMap {
		get {
			if(relationshipTypeMap == null)
			{
				relationshipTypeMap = new Map<String,Integer>();
                if(NO_FINANCIAL_PARTNER_CHANNELS.contains(opportunity.FulfillmentChannel__c))
                {
                    relationshipTypeMap.put(FINANCIAL,1);
                }
				for(Opportunity_PartnerInfo partnerInfo : partnerInfoList)
				{
					OpportunityPartner__c opportunityPartner = partnerInfo.opportunityPartner;
					if(opportunityPartner.Id != null)
					{
                        Integer count = relationshipTypeMap.get(opportunityPartner.RelationshipType__c);
                        relationshipTypeMap.put(opportunityPartner.RelationshipType__c,(count == null)?1:(count+1));
					}
				}
			}
			return relationshipTypeMap;
		}
		set {
			relationshipTypeMap = value;
			relationshipTypeOptions = null;
		}
	}
	
	//
	// Opportunity and Account IDs
	//
	public Opportunity opportunity {
		get {
			return (Opportunity) controller.getRecord();
		}
	}
	
	public Boolean isFinancialPartnerRequired {
		get {
			return isFinancialPartnerRequired(opportunity.Id);
		}
	}
	
	public Account account {
		get {
			return opportunity.Account;
		}
	}
/*	
	public Boolean showAllRegions {
		get {
			return (showAllRegions == true);
		}
		set;
	}
*/	
	public List<Opportunity_PartnerInfo> partnerInfoList {
		get {
			if(partnerInfoList == null)
			{
				partnerInfoList = new List<Opportunity_PartnerInfo>();
				final List<OpportunityPartner__c> opportunityPartnerList = new List<OpportunityPartner__c>();
				try
				{
					opportunityPartnerList.addAll([
						select Id,
						  Partner__c,
						  PartnerTier__c,
						  PartnerTier__r.Hierarchy__c,
                          PartnerTier__r.Name,
						  PartnerType__c,
						  PartnerType__r.Hierarchy__c,
                          PartnerType__r.Name,
						  RelationshipType__c
						from OpportunityPartner__c
						where Opportunity__c = :opportunity.Id
						order by RelationshipType__c asc, Name asc ]);
				} 
				catch (System.DmlException dmlException)
				{
					addExceptionMessage(dmlException);
				}
				Boolean hasFinancial = false;
				for(OpportunityPartner__c opportunityPartner : opportunityPartnerList)
				{
				    hasFinancial = hasFinancial || (opportunityPartner.RelationshipType__c == FINANCIAL);
					partnerInfoList.add(new Opportunity_PartnerInfo(this,opportunityPartner));
				}
                partnerInfoList.add(null);
				if((! hasFinancial)&& isFinancialPartnerRequired(opportunity))
				{
					Opportunity_PartnerInfo p = new Opportunity_PartnerInfo(this);
					partnerInfoList.add(0,p);
					p.opportunityPartner.RelationshipType__c = FINANCIAL;
					p.isRequired=true;
				}
				partnerInfoList.remove(partnerInfoList.size()-1);
			}
			return partnerInfoList;
		}
		set {
			partnerInfoList = value;
			relationshipTypeMap = null;			
		}
	}
	
	public Boolean partnerInfoListIsEmpty {
		get {
			return partnerInfoList.isEmpty();
		}
	}
	
	public List<SelectOption> relationshipTypeOptions {
		get {
			if(relationshipTypeOptions == null)
			{			
				final List<SelectOption> selectOptions = new List<SelectOption>();
				selectOptions.add(new SelectOption('', '--None--'));
				Boolean needsReseller = true;
				for(Schema.Picklistentry entry : relationshipTypePicklistentryList)
				{
					final String value = entry.getValue();
					final SelectOption selectOption = new SelectOption(
						value, entry.getLabel());
					final Integer count = relationshipTypeMap.get(value);
					Boolean disabled = (!needsReseller)&&value.startsWith('Reseller ');
					if(count != null)
					{
						Integer valueLimit = RELATIONAL_TYPE_LIMITS.get(value);
                        disabled = disabled || (valueLimit == null)||(count >= valueLimit);
					}
					else if(needsReseller)
					{
						needsReseller = ! value.startsWith('Reseller ');
					}
                    selectOption.setDisabled(disabled);
					selectOptions.add(selectOption);
				}
				relationshipTypeOptions = selectOptions;
			}
			return relationshipTypeOptions;
		}
		set;
	}

	public Boolean getHasAvailableRelationshipTypeOptions()
	{
		Boolean retval = false;
		for(SelectOption selectOption : relationshipTypeOptions)
		{
			if(! selectOption.getDisabled())
			{
				String value = selectOption.getValue();
				if(value != null && value != '')
				{
					retval=true;
					break;
				}
			}
		}
		return retval;
	}
	
	public void cancelEdit(Integer id)
	{
		for(Integer i=0;i<partnerInfoList.size();i++)
		{
			Opportunity_PartnerInfo partnerInfo = partnerInfoList.get(i);
			if(id == partnerInfo.id)
			{
				if(! partnerInfo.isNew)
				{
					try
                    {
					    OpportunityPartner__c opportunityPartner = [
					        select Id,
                              Partner__c,
                              PartnerTier__c,
                              PartnerTier__r.Hierarchy__c,
                              PartnerTier__r.Name,
                              PartnerType__c,
                              PartnerType__r.Hierarchy__c,
                              PartnerType__r.Name,
                              RelationshipType__c
                           from OpportunityPartner__c
                           where Id = :partnerInfo.opportunityPartner.Id ];
                        partnerInfoList.add(i,new Opportunity_PartnerInfo(this,opportunityPartner));
                        i++;
				    }
                    catch (Exception e)
                    {
                        addExceptionMessage(e);
                    }
				}
				partnerInfoList.remove(i);
				break;
			}
		}
	}
	
/*
	public PageReference cancelInsertOpportunityPartner()
	{
		if (partnerInfoList.isEmpty())
		{
			addExceptionMessage('Internal Error: the opportunityPartner list is already empty.');
		}
		else 
		{
			final OpportunityPartner__c partner = partnerInfoList.get(0).opportunityPartner;
			if (partner.Id != null)
			{
				addExceptionMessage('Integer Error: the first opportunityPartner in the opportunityPartner list is from an update, not an insert.');
			}
			else 
			{
				partnerInfoList.remove(0);
			}
		}
		return null;
	}
*/

	public PageReference cancel()
	{
		partnerInfoList = null;
		addMessage(ApexPages.Severity.INFO, 'All changes were canceled.');
		return null;
	}

	public PageReference insertOpportunityPartner()
	{
		Opportunity_PartnerInfo partnerInfo = new Opportunity_PartnerInfo(this);
		partnerInfoList.add(null);
        partnerInfoList.add(0,partnerInfo);
        partnerInfoList.remove(partnerInfoList.size()-1);
		return null;
	}

    public PageReference editSelected()
    {
        for(Opportunity_PartnerInfo partnerInfo : partnerInfoList)
        {
        	if(partnerInfo.isSelected)
        	{
        		partnerInfo.isEdit = true;
        	}
        }
        return null;
    }
    
    public Boolean isEdit {
    	get {
    		Boolean retval = false;
    		for(Opportunity_PartnerInfo partnerInfo : partnerInfoList)
    		{
    			if(partnerInfo.isEdit)
    			{
    				retval = true;
    				break;
    			}
    		}
    		return retval;
    	}
    }
    
    public PageReference removeSelected()
    {
        try
        {
            List<OpportunityPartner__c> opportunityPartnerList = new List<OpportunityPartner__c>();
            for(Opportunity_PartnerInfo partnerInfo : partnerInfoList)
            {
                if(partnerInfo.isSelected)
                {
                	if(partnerInfo.opportunityPartner.RelationshipType__c == FINANCIAL && FINANCIAL_PARTNER_CHANNELS.contains(opportunity.FulfillmentChannel__c))
                	{
                		addExceptionMessage(Schema.SObjectType.Opportunity.Fields.FinancialPartnerName__c.getLabel()+' is required.');
                	}
                	else
                	{
                        opportunityPartnerList.add(partnerInfo.opportunityPartner);
                	}
                }
            }
            partnerInfoList = null;
            if(! opportunityPartnerList.isEmpty())
            {
                delete opportunityPartnerList;
            }
        }
        catch (System.DmlException dmlException)
        {
            addExceptionMessage(dmlException);
        }
        return null;
    }
    
	public PageReference saveOpportunityPartnerList()
	{
		if (partnerInfoList.isEmpty())
		{
			addExceptionMessage('Internal Error: the opportunityPartner list is empty.');
		}
		else
		{
			try
			{
				List<OpportunityPartner__c> opportunityPartnerList = new List<OpportunityPartner__c>();
				for(Opportunity_PartnerInfo partnerInfo : partnerInfoList)
				{
					OpportunityPartner__c opportunityPartner = partnerInfo.opportunityPartner;
					if(partnerInfo.partnerStatus != null)
					{
						opportunityPartner.PartnerTier__c = partnerInfo.partnerStatus.PartnerTier__c;
						opportunityPartner.PartnerType__c = partnerInfo.partnerStatus.PartnerType__c;
					}
					if(partnerInfo.isEdit)
					{
						opportunityPartnerList.add(opportunityPartner);
					}
				}
				//insert opportunityPartnerList;
				upsert opportunityPartnerList;
				partnerInfoList = null;
				addConfirmationMessage();
			}
			catch (System.DmlException dmlException)
			{
				addExceptionMessage(dmlException);
			}
		}
		return null;
	}

	public PageReference saveOpportunityPartnerListAndInsert()
	{
		saveOpportunityPartnerList();
		return hasMessages(ApexPages.Severity.ERROR)?null:insertOpportunityPartner();
	}

	public PageReference saveOpportunityPartnerListAndReturn()
	{
		saveOpportunityPartnerList();
		return hasMessages(ApexPages.Severity.ERROR)?null:(new PageReference('/' + opportunity.Id));
	}
/*
	public PageReference refreshOpportunityPartnerList()
	{
		partnerInfoList = null;
		return null;
	}
*/
}