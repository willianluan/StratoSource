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

    private Opportunity opportunity;
    
	public Opportunity_ManagePartners(ApexPages.StandardController controller)
	{
		this.controller = controller;
		this.opportunity = (Opportunity)controller.getRecord();
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

    static Map<String,Set<Id>> accountRecordTypeIdByRegion = null;
	public static Map<String,Set<Id>> getAccountRecordTypeIdByRegion()
	{
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
	
    static List<Classification__c>  completePartnerTierList = null;

	public static List<Classification__c>  getCompletePartnerTierList()
	{
		if(completePartnerTierList == null)
		{
			completePartnerTierList = getClassificationList(PARTNER_TIER_ROOTNAME);
		}
		return completePartnerTierList;
	}

	public static Id rootPartnerTierId {
		get {
			if(rootPartnerTierId == null)
			{
				Id retval = null;
                List<Classification__c>  xcompletePartnerTierList = getCompletePartnerTierList();
				if(! xcompletePartnerTierList.isEmpty())
				{
					retval = xcompletePartnerTierList.get(0).Id;
				}
				rootPartnerTierId = retval;
			}
			return rootPartnerTierId;
		}
	}

    static Map<Id,Classification__c> partnerTierMap = null;
    
	public static Map<Id,Classification__c> getPartnerTierMap()
	{
		if(partnerTierMap == null)
		{
			partnerTierMap = new Map<Id,Classification__c>(getCompletePartnerTierList());
		}
		return partnerTierMap;
	}

    static List<Classification__c>  completePartnerTypeList = null;
    
	public static List<Classification__c>  getCompletePartnerTypeList()
	{
		if(completePartnerTypeList == null)
		{
			completePartnerTypeList = getClassificationList(PARTNER_TYPE_ROOTNAME);
		}
		return completePartnerTypeList;
	}

	public static Id rootPartnerTypeId {
		get {
			if(rootPartnerTypeId == null)
			{
				Id retval = null;
				List<Classification__c> xcompletePartnerTypeList = getCompletePartnerTypeList();
				if(! xcompletePartnerTypeList.isEmpty())
				{
					retval = xcompletePartnerTypeList.get(0).Id;
				}
				rootPartnerTypeId = retval;
			}
			return rootPartnerTypeId;
		}
	}

    static Map<Id,Classification__c> partnerTypeMap = null;
    
	public static Map<Id,Classification__c> getPartnerTypeMap()
	{
		if(partnerTypeMap == null)
		{
			partnerTypeMap = new Map<Id,Classification__c>(getCompletePartnerTypeList());
		}
		return partnerTypeMap;
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

	static Boolean needsFill = true;

	static Map<Id,Id> partnerTypeIdByPartnerStatusIdMap = null;

	public static Map<Id,Id> getPartnerTypeIdByPartnerStatusIdMap()
	{
		if(needsFill) fillPartnerStatusMaps();
		return partnerTypeIdByPartnerStatusIdMap;
	}

	static Map<Id,Id> partnerTierIdByPartnerStatusIdMap = null;

	public static Map<Id,Id> getPartnerTierIdByPartnerStatusIdMap()
	{
		if(needsFill) fillPartnerStatusMaps();
		return partnerTierIdByPartnerStatusIdMap;
	}

	static Map<Id,Map<String,Map<Id,PartnerStatus__c>>> partnerStatusRecordTypeIdTypeHierarchyMap = null;

	public static Map<Id,Map<String,Map<Id,PartnerStatus__c>>> getPartnerStatusRecordTypeIdTypeHierarchyMap()
	{
		if(needsFill) fillPartnerStatusMaps();
		return partnerStatusRecordTypeIdTypeHierarchyMap;
	}

	static Map<Id,Map<Id,PartnerStatus__c>> partnerStatusMapByIdMap = null;

	public static Map<Id,Map<Id,PartnerStatus__c>> getPartnerStatusMapByIdMap()
	{
		if(needsFill) fillPartnerStatusMaps();
		return partnerStatusMapByIdMap;
	}

	static void fillPartnerStatusMaps() {
		if(needsFill)
		{
			needsFill = false;
			final Map<Id,PartnerStatus__c> retval = new Map<Id,PartnerStatus__c>();
			List<PartnerStatus__c> currentList;
			Set<Id> excludedIds = new Set<Id>();
			partnerTypeIdByPartnerStatusIdMap = new Map<Id,Id>();
			partnerTierIdByPartnerStatusIdMap = new Map<Id,Id>();
			partnerStatusMap = new Map<Id,PartnerStatus__c>();
			partnerStatusRecordTypeIdTypeHierarchyMap = new Map<Id,Map<String,Map<Id,PartnerStatus__c>>>();
			partnerStatusMapByIdMap = new Map<Id,Map<Id,PartnerStatus__c>>();
			Set<String> duplicates = new Set<String>();
			for(Datetime previousDatetime=Datetime.now();;)
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
							PartnerType__r.Name,
							LastModifiedDate
						from PartnerStatus__c
						where ActivationStatus__c = 'Active'
							and PartnerTier__c != null
							and PartnerType__c != null
							and Partner__c != null
							and LastModifiedDate <= :previousDatetime
							and (not Id in :excludedIds)
						order by LastModifiedDate desc,
							PartnerTier__r.Hierarchy__c asc,
							PartnerType__r.Hierarchy__c asc limit :rowsToQuery ];
				}
				if(rowsToQuery < 1 || currentList.isEmpty())
				{
					break;
				}
				for(PartnerStatus__c p : currentList)
				{
					String key = p.Partner__r.Name+':'+p.PartnerType__c+':'+p.PartnerTier__c;
					if(! duplicates.contains(key))
					{
						duplicates.add(key);
						partnerTypeIdByPartnerStatusIdMap.put(p.Id,p.PartnerType__c);
						partnerTierIdByPartnerStatusIdMap.put(p.Id,p.PartnerTier__c);
						Map<String,Map<Id,PartnerStatus__c>> m2 = partnerStatusRecordTypeIdTypeHierarchyMap.get(p.Partner__r.RecordTypeId);
						if(m2 == null)
						{
							partnerStatusRecordTypeIdTypeHierarchyMap.put(p.Partner__r.RecordTypeId,(m2 = new Map<String,Map<Id,PartnerStatus__c>>()));
						}
						Map<Id,PartnerStatus__c> m = m2.get(p.PartnerType__r.Hierarchy__c);
						if(m == null)
						{
							m2.put(p.PartnerType__r.Hierarchy__c,(m=new Map<Id,PartnerStatus__c>()));
						}
						m.put(p.Id,p);
						m = partnerStatusMapByIdMap.get(p.PartnerType__c);
						if(m == null)
						{
							partnerStatusMapByIdMap.put(p.PartnerType__c,(m=new Map<Id,PartnerStatus__c>()));
						}
						m.put(p.Id,p);
						m = partnerStatusMapByIdMap.get(p.PartnerTier__c);
						if(m == null)
						{
							partnerStatusMapByIdMap.put(p.PartnerTier__c,(m=new Map<Id,PartnerStatus__c>()));
						}
						m.put(p.Id,p);
					}
				}
				partnerStatusMap.putAll(new Map<Id,PartnerStatus__c>(currentList));
				previousDatetime = currentList.get(currentList.size()-1).LastModifiedDate;
				excludedIds.clear();
				for(Integer i=currentList.size();i-- > 0;)
				{
					PartnerStatus__c p = currentList.get(i);
					if(p.LastModifiedDate != previousDatetime)
					{
						break;
					}
					excludedIds.add(p.Id);
				}
			}
		}
	}

	static Map<Id,PartnerStatus__c> partnerStatusMap = null;

	public static Map<Id,PartnerStatus__c> getPartnerStatusMap() {
		if(needsFill) fillPartnerStatusMaps();
		return partnerStatusMap;
	}

    Map<String,Integer> relationshipTypeMap = null;
	private Map<String,Integer> getRelationshipTypeMap() {
		if(relationshipTypeMap == null)
		{
			relationshipTypeMap = new Map<String,Integer>();
			if(NO_FINANCIAL_PARTNER_CHANNELS.contains(opportunity.FulfillmentChannel__c))
			{
				relationshipTypeMap.put(FINANCIAL,1);
			}
			for(Opportunity_PartnerInfo partnerInfo : getPartnerInfoList())
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
	private void setRelationshipTypeMap(Map<String,Integer> value) {
		relationshipTypeMap = value;
		relationshipTypeOptions = null;
	}

	//
	// Opportunity and Account IDs
	//
	public Opportunity getOpportunity()
	{
		return opportunity;
	}

	public Boolean isFinancialPartnerRequired {
		get {
			return isFinancialPartnerRequired(opportunity.Id);
		}
	}

	public Account getAccount()
	{
		return opportunity.account;
	}

    private List<Opportunity_PartnerInfo> partnerInfoList = null;
    
	public List<Opportunity_PartnerInfo> getPartnerInfoList()
	{
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

	public void setPartnerInfoList(List<Opportunity_PartnerInfo> value) {
		partnerInfoList = value;
		setRelationshipTypeMap(null);
	}

	public Boolean getPartnerInfoListIsEmpty()
	{
		return getPartnerInfoList().isEmpty();
	}

    private List<SelectOption> relationshipTypeOptions = null;
    
	public List<SelectOption> getRelationshipTypeOptions()
	{
		if(relationshipTypeOptions == null)
		{
			final List<SelectOption> selectOptions = new List<SelectOption>();
			selectOptions.add(new SelectOption('', '--None--'));
			Boolean needsReseller = true;
			Map<String,Integer> xrelationshipTypeMap = getRelationshipTypeMap();
			for(Schema.Picklistentry entry : relationshipTypePicklistentryList)
			{
				final String value = entry.getValue();
				final SelectOption selectOption = new SelectOption(
					value, entry.getLabel());
				final Integer count = xrelationshipTypeMap.get(value);
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

	public Boolean getHasAvailableRelationshipTypeOptions()
	{
		Boolean retval = false;
		for(SelectOption selectOption : getRelationshipTypeOptions())
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
		List<Opportunity_PartnerInfo> xpartnerInfoList = getPartnerInfoList();
		for(Integer i=0;i<xpartnerInfoList.size();i++)
		{
			Opportunity_PartnerInfo partnerInfo = xpartnerInfoList.get(i);
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
						xpartnerInfoList.add(i,new Opportunity_PartnerInfo(this,opportunityPartner));
						i++;
					}
					catch (Exception e)
					{
						addExceptionMessage(e);
					}
				}
				xpartnerInfoList.remove(i);
				break;
			}
		}
	}

	public PageReference cancel()
	{
		setPartnerInfoList(null);
		addMessage(ApexPages.Severity.INFO, 'All changes were canceled.');
		return null;
	}

	public PageReference insertOpportunityPartner()
	{
		Opportunity_PartnerInfo partnerInfo = new Opportunity_PartnerInfo(this);
		List<Opportunity_PartnerInfo> xpartnerInfoList = getPartnerInfoList();
		xpartnerInfoList.add(null);
		xpartnerInfoList.add(0,partnerInfo);
		xpartnerInfoList.remove(xpartnerInfoList.size()-1);
		return null;
	}

	public PageReference editSelected()
	{
		for(Opportunity_PartnerInfo partnerInfo : getPartnerInfoList())
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
			for(Opportunity_PartnerInfo partnerInfo : getPartnerInfoList())
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
			for(Opportunity_PartnerInfo partnerInfo : getPartnerInfoList())
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
			setPartnerInfoList(null);
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
		List<Opportunity_PartnerInfo> xpartnerInfoList = getPartnerInfoList();
		if (xpartnerInfoList.isEmpty())
		{
			addExceptionMessage('Internal Error: the opportunityPartner list is empty.');
		}
		else
		{
			try
			{
				List<OpportunityPartner__c> opportunityPartnerList = new List<OpportunityPartner__c>();
				for(Opportunity_PartnerInfo partnerInfo : xpartnerInfoList)
				{
					OpportunityPartner__c opportunityPartner = partnerInfo.opportunityPartner;
					PartnerStatus__c partnerStatus = partnerInfo.getPartnerStatus();
					if(partnerStatus != null)
					{
						opportunityPartner.PartnerTier__c = partnerStatus.PartnerTier__c;
						opportunityPartner.PartnerType__c = partnerStatus.PartnerType__c;
					}
					if(partnerInfo.isEdit)
					{
						opportunityPartnerList.add(opportunityPartner);
					}
				}
				//insert opportunityPartnerList;
				upsert opportunityPartnerList;
				setPartnerInfoList(null);
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
}