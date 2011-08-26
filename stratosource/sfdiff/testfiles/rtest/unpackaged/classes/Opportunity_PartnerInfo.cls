public with sharing class Opportunity_PartnerInfo {
	private static final Map<String,Pattern> partnerTypePatternMap = new Map<String,Pattern>();
	private static Integer nextId = 1;
	public final OpportunityPartner__c opportunityPartner;
	private final Opportunity_ManagePartners parent;
	public Integer id;

	public Opportunity_PartnerInfo(Opportunity_ManagePartners parent)
	{
		this.parent = parent;
		this.opportunityPartner = new OpportunityPartner__c(
			Opportunity__c = parent.getOpportunity().Id );
		this.id = (nextId++);
	}

	public Opportunity_PartnerInfo(Opportunity_ManagePartners parent,OpportunityPartner__c opportunityPartner)
	{
		this.parent = parent;
		this.opportunityPartner = opportunityPartner;
		this.id = (nextId++);
	}

	public static Pattern getPartnerTypePattern(String channel,String rt)
	{
		Pattern retval = null;
		if(channel != null && rt != null)
		{
			final String key = channel+':'+rt;
			retval = partnerTypePatternMap.get(key);
			if(retval == null)
			{
				retval = Pattern.compile('.*');
				if(rt == Opportunity_ManagePartners.FINANCIAL)
				{
					if(Opportunity_ManagePartners.NO_FINANCIAL_PARTNER_CHANNELS.contains(channel))
					{
						retval = Pattern.compile('^$');
					}
					else if(channel.contains('VAR/VAD'))
					{
						retval = Pattern.compile('^Partner Type » ((Distributor|ISP|ISV|SI|Reseller)( » .*)*)$');
					}
					else if(channel.endsWith(' OEM') || channel.contains(' OEM '))
					{
						retval = Pattern.compile('^Partner Type » OEM( » .*)*$');
					}
					else if(channel.endsWith(' DLT') || channel.endswith('Carahsoft'))
					{
						retval = Pattern.compile('^Partner Type » (Distributor|Reseller)( » .*)*$');
					}
				}
				else if(rt == Opportunity_ManagePartners.INFLUENCING)
				{
					retval = Pattern.compile('^Partner Type » ((Global Chip|ISV|OEM|SI)( » .*)*)$');
				}
				else if(rt.startsWith('Reseller '))
				{
					retval = Pattern.compile('^Partner Type » ((Distributor|ISP|Reseller|ISV|OEM|SI)( » .*)*)$');
				}
				partnerTypePatternMap.put(key,retval);
			}
		}
		return retval;
	}

	private static void addRecursive(Map<Id,Classification__c> classificationMap,Set<Id> idSet,Id id)
	{
		if(! idSet.contains(id))
		{
			Classification__c c = classificationMap.get(id);
			if(c != null)
			{
				idSet.add(id);
				addRecursive(classificationMap,idSet,c.Parent__c);
			}
		}   
	}

	private static Set<Id> getClassificationIdSet(
		List<Classification__c> classificationList,Id id,Id defaultId)
	{
		final Set<Id> retval = new Set<Id>();
		for(Integer i=0;i < classificationList.size();i++)
		{
			final Classification__c start = classificationList.get(i);
			if(start.Id == id)
			{
				Classification__c c = start;
				do
				{
					retval.add(c.Id);
					if(++i >= classificationList.size())
					{
						break;
					}
					c = classificationList.get(i);
				} while(c.HierarchyDepth__c > start.HierarchyDepth__c);
				break;
			}
		}
		if(retval.contains(defaultId))
		{
			retval.add(null);
		}
		return retval;
	}

	private static List<SelectOption> getOptionsList(
		List<Classification__c> classificationList, 
		Integer depth, 
		String defaultValue)
	{
		List<SelectOption> selectOptions = new List<SelectOption>();
		Set<String> labels = new Set<String>();
		selectOptions.add(new SelectOption(defaultValue,'--None--'));
		if(classificationList != null)
		{
			for(Classification__c c : classificationList)
			{
				String [] hierarchy = c.Hierarchy__c.split(' » ',depth);
				String label = '--None--';
				if(hierarchy.size() >= depth)
				{
					label = hierarchy[depth-1];
				}
				if(label != null)
				{
					selectOptions.add(new SelectOption(c.Id,label));
					labels.add(label);
				}
			}
			if(labels.contains('--None--'))
			{
				selectOptions.remove(0);
			}
		}
		return selectOptions;
	}

	private static String getName(Classification__c c,Integer depth)
	{
		String retval = '';
		if(c != null && c.Hierarchy__c != null)
		{
			final String [] hierarchy = c.Hierarchy__c.split(' » ',3);
			if(hierarchy.size() > depth)
			{
				retval = hierarchy[depth];
			}
		}
		return retval;
	}

	private static Boolean hasDescendents(Classification__c value)
	{
		return (value != null)&&(value.Descendents__c != null)&&(value.Descendents__c > 0);
	}

	private static String hierarchyName(Classification__c classification)
	{
		String retval = null;
		if(classification != null)
		{
			String [] hierarchy = classification.Hierarchy__c.split(' » ',2);
			if(hierarchy.size() > 1)
			{
				retval = hierarchy[1];
			}
		}
		return retval;
	}
	
	private void regionFilteredPartnerStatusMapClear()
	{
		regionFilteredPartnerStatusMap = null;
		filteredPartnerTypeIdSet = null;
		typeFilteredPartnerStatusMap = null;
		filteredPartnerTierIdSet = null;
		partnerTierOptions = null;
		tierFilteredPartnerStatusMap = null;
		filteredPartnerSubTypeIdSet = null;
		fullyFilteredPartnerStatusMap = null;
		partnerSubTypeOptions = null;
		partnerTypeList = null;
		partnerTypeOptions = null;
	}

	transient Map<Id,PartnerStatus__c> regionFilteredPartnerStatusMap = null;
	
//	 Generate a list of PartnerStatus object filtered on 
//	 the selected region and relationship type.
	private Map<Id,PartnerStatus__c> getRegionFilteredPartnerStatusMap()
	{
		if(regionFilteredPartnerStatusMap == null)
		{
			final Set<Id> recordTypeIdSet = new Set<Id>();
			final String recordTypeName = parent.getOpportunity().RecordType.Name;
			Map<String,Set<Id>> accountRecordTypeIdByRegion = Opportunity_ManagePartners.getAccountRecordTypeIdByRegion();
			for(String regionName : accountRecordTypeIdByRegion.keySet())
			{
				if(recordTypeName == regionName || recordTypeName.startsWith(regionName+' ') || recordTypeName.contains(' '+regionName+' ') || recordTypeName.endsWith(' '+regionName))
				{
					recordTypeIdSet.addAll(accountRecordTypeIdByRegion.get(regionName));
					break;
				}
			}
			if(recordTypeIdSet.isEmpty() || showAllRegions)
			{
				showAllRegions = true;
				for(Set<Id> ids : accountRecordTypeIdByRegion.values())
				{
					recordTypeIdSet.addAll(ids);
				}
			}
			Pattern pat = getPartnerTypePattern(parent.getOpportunity().FulfillmentChannel__c,opportunityPartner.RelationshipType__c);
			final Map<Id,PartnerStatus__c> retval = new Map<Id,PartnerStatus__c>();
			List<PartnerStatus__c> currentList = null;
			Map<Id,Map<String,Map<Id,PartnerStatus__c>>> m = Opportunity_ManagePartners.getPartnerStatusRecordTypeIdTypeHierarchyMap().clone();
			m.keySet().retainAll(recordTypeIdSet);
			for(Map<String,Map<Id,PartnerStatus__c>> m2 : m.values())
			{
				for(String partnerTypeHierarchy : m2.keySet())
				{
					if(pat == null || pat.matcher(partnerTypeHierarchy).matches())
					{
				   		retval.putAll(m2.get(partnerTypeHierarchy));
					}
				}
			}
			regionFilteredPartnerStatusMap = retval;
		}
		return regionFilteredPartnerStatusMap;
	}

	transient Set<Id> filteredPartnerTypeIdSet = null;
	
//	 Use the regionFilteredPartnerStatusList to generate a set of 
//	 Partner Type Id's with associated Partner's.		
	private Set<Id> getFilteredPartnerTypeIdSet()
	{
		if(filteredPartnerTypeIdSet == null)
		{
			final Set<Id> idSet = new Set<Id>();
			Map<Id,Id> m =  Opportunity_ManagePartners.getPartnerTypeIdByPartnerStatusIdMap().clone();
			m.keySet().retainAll(getRegionFilteredPartnerStatusMap().keySet());
			Map<Id,Classification__c> partnerTypeMap = Opportunity_ManagePartners.getPartnerTypeMap();			
			for(Id xpartnerTypeId : new Set<Id>(m.values()))
			{
				addRecursive(partnerTypeMap,idSet,xpartnerTypeId);
			}
			filteredPartnerTypeIdSet = idSet;
		}
		return filteredPartnerTypeIdSet;
	}

	transient List<Classification__c>  partnerTypeList = null;
	
	private List<Classification__c>  getPartnerTypeList()
	{
		if(partnerTypeList == null)
		{
			final List<Classification__c> retval = new List<Classification__c>();
			for(Classification__c c : Opportunity_ManagePartners.getCompletePartnerTypeList())
			{
				if(getFilteredPartnerTypeIdSet().contains(c.Id))
				{
					retval.add(c);
				}
			}
			partnerTypeList = retval;
		}
		return partnerTypeList;
	}

	transient Map<Id,PartnerStatus__c> typeFilteredPartnerStatusMap = null;
	
//	 Generate a list of PartnerStatus object filtered on 
//	 the selected PartnerTypeId
	private Map<Id,PartnerStatus__c> getTypeFilteredPartnerStatusMap()
	{
		if(typeFilteredPartnerStatusMap == null)
		{
			final Set<Id> partnerTypeIdSet = getClassificationIdSet(
				getPartnerTypeList(),partnerTypeId,Opportunity_ManagePartners.rootPartnerTypeId);
			Map<Id,PartnerStatus__c> retval = new Map<Id,PartnerStatus__c>();
			Map<Id,Map<Id,PartnerStatus__c>> partnerStatusMapByIdMap=Opportunity_ManagePartners.getPartnerStatusMapByIdMap();
			for(Id xpartnerTypeId : partnerTypeIdSet)
			{
			  	Map<Id,PartnerStatus__c> m = partnerStatusMapByIdMap.get(xpartnerTypeId);
			   	if(m != null)
			   	{
			   		retval.putAll(m);
			   	}
			}
			retval.keySet().retainAll(getRegionFilteredPartnerStatusMap().keySet());
			typeFilteredPartnerStatusMap = retval;
		}
		return typeFilteredPartnerStatusMap;
	}

	transient Set<Id> filteredPartnerTierIdSet = null;
	
//	 Use the typeFilteredPartnerStatusList to generate a set of 
//	 Partner Tier Id's with associated Partner's.		
	private Set<Id> getFilteredPartnerTierIdSet()
	{
		if(filteredPartnerTierIdSet == null)
		{
			final Set<Id> idSet = new Set<Id>();
			Map<Id,Id> m =  Opportunity_ManagePartners.getPartnerTierIdByPartnerStatusIdMap().clone();
			m.keySet().retainAll(getTypeFilteredPartnerStatusMap().keySet());
			Map<Id,Classification__c> partnerTierMap = Opportunity_ManagePartners.getPartnerTierMap();
			for(Id xpartnerTierId : new Set<Id>(m.values()))
			{
				addRecursive(partnerTierMap,idSet,xpartnerTierId);
			}
			filteredPartnerTierIdSet = idSet;
		}
		return filteredPartnerTierIdSet;
	}

	transient Map<Id,PartnerStatus__c> tierFilteredPartnerStatusMap = null;
	
//	 Generate a list of PartnerStatus object in the 
//	 typeFilteredPartnerStatusLists filtered on 
//	 the selected PartnerTierId.
	private Map<Id,PartnerStatus__c> getTierFilteredPartnerStatusMap()
	{
		if(tierFilteredPartnerStatusMap == null)
		{
			List<PartnerStatus__c> currentList = null;
			final Set<Id> partnerTierIdSet = getClassificationIdSet(
				Opportunity_ManagePartners.getCompletePartnerTierList(),getPartnerTierId(),Opportunity_ManagePartners.rootPartnerTierId);
			partnerTierIdSet.retainAll(Opportunity_ManagePartners.getPartnerStatusMapByIdMap().keySet());
			Map<Id,PartnerStatus__c> retval = new Map<Id,PartnerStatus__c>();
			Map<Id,Map<Id,PartnerStatus__c>> partnerStatusMapByIdMap = Opportunity_ManagePartners.getPartnerStatusMapByIdMap();
			for(Id xpartnerTierId : partnerTierIdSet)
			{
			   	Map<Id,PartnerStatus__c> m = partnerStatusMapByIdMap.get(xpartnerTierId);
			   	if(m != null)
			   	{
					retval.putAll(m);
			   	}
			}
			retval.keySet().retainAll(getTypeFilteredPartnerStatusMap().keySet());
			tierFilteredPartnerStatusMap = retval;
		}
		return tierFilteredPartnerStatusMap;
	}

	transient Set<Id> filteredPartnerSubTypeIdSet = null;
	
//	 Use the tierFilteredPartnerStatusMap to generate a set of 
//	 Partner Sub-Type Id's with associated Partner's.		
	private Set<Id> getFilteredPartnerSubTypeIdSet()
	{
		if(filteredPartnerSubTypeIdSet == null)
		{
			final Set<Id> retval = new Set<Id>();
			Id xpartnerTypeId = getPartnerTypeId();
			final Classification__c partnerType = Opportunity_ManagePartners.getPartnerTypeMap().get(xpartnerTypeId);
			if(partnerType != null)
			{
				retval.add(xpartnerTypeId);
				if(partnerType.HierarchyDepth__c == 2 && partnerType.Descendents__c > 0)
				{
					final Set<Id> idSet = new Set<Id>();
					Map<Id,Id> m = Opportunity_ManagePartners.getPartnerTypeIdByPartnerStatusIdMap().clone();
					m.keySet().retainAll(getTierFilteredPartnerStatusMap().keySet());
					Map<Id,Classification__c> partnerTypeMap = Opportunity_ManagePartners.getPartnerTypeMap();			
					for(Id xxpartnerTypeId : new Set<Id>(m.values()))
					{
						addRecursive(partnerTypeMap,idSet,xxpartnerTypeId);
					}
					idSet.retainAll(getClassificationIdSet(getPartnerTypeList(),xpartnerTypeId,null));
					retval.addAll(idSet);
				}
			}
			filteredPartnerSubTypeIdSet = retval;
		}
		return filteredPartnerSubTypeIdSet;
	}

	transient Map<Id,PartnerStatus__c> fullyFilteredPartnerStatusMap = null;
	
//	 Generate a list of PartnerStatus object in the 
//	 tierFilteredPartnerStatusMap filtered on 
//	 the selected PartnerSubTypeId.
	private Map<Id,PartnerStatus__c> getFullyFilteredPartnerStatusMap()
	{
		if(fullyFilteredPartnerStatusMap == null)
		{
			List<PartnerStatus__c> currentList = null;
			final Set<Id> partnerSubTypeIdSet = getClassificationIdSet(
				getPartnerTypeList(),partnerSubTypeId,Opportunity_ManagePartners.rootPartnerTypeId);
			Map<Id,PartnerStatus__c> retval = getTierFilteredPartnerStatusMap().clone();
			Map<Id,Map<Id,PartnerStatus__c>> partnerStatusMapByIdMap = Opportunity_ManagePartners.getPartnerStatusMapByIdMap();
			Id xpartnerSubTypeId = getPartnerSubTypeId();
			if(xpartnerSubTypeId != getPartnerTypeId())
			{
				Map<Id,PartnerStatus__c> m = partnerStatusMapByIdMap.get(xpartnerSubTypeId);
				if(m != null)
				{
					retval.keySet().retainAll(m.keySet());
				}
			}
			fullyFilteredPartnerStatusMap = retval;
		}
		return fullyFilteredPartnerStatusMap;
	}

//	 Accessor to the OpportunityPartner object
	public OpportunityPartner__c getOpportunityPartner()
	{
		return opportunityPartner;
	}

	public Boolean isSelected {
		get { 
			if(isSelected == null)
			{
				isSelected = isEdit;
			}
			return isSelected;
		}
		set;
	}

	public Boolean isEdit {
		get {
			return (isEdit == true) || isNew;
		}
		set {
			if(value != isEdit)
			{
				if((isEdit = value) == true)
				{
					showAllRegions=false;
					updateShowAllRegions();
					if(opportunityPartner.Partner__c != null) for(Integer i=0;i<2;i++)
					{
						PartnerStatus__c xpartnerStatus = getFullyFilteredPartnerStatusMap().get(opportunityPartner.Partner__c);
						if(xpartnerStatus != null)
						{
							setPartnerStatusId(xpartnerStatus.Id);
							String [] splitPartnerType = opportunityPartner.PartnerType__r.Hierarchy__c.split(' » ',3);
							if(splitPartnerType.size() >= 2)
							{
								for(Classification__c c : getPartnerTypeList())
								{
									String [] s = c.Hierarchy__c.split(' » ',3);
									if(s.size() == 2 && s[0] == splitPartnerType[0] && s[1] == splitPartnerType[1])
									{
										setPartnerTypeId(c.Id);
										updatePartnerType();
										break;
									}
								}
							}
							setPartnerTierId(xpartnerStatus.PartnerTier__c);
							updatePartnerTier();
							setPartnerSubTypeId(xpartnerStatus.PartnerType__c);
							updatePartnerSubType();
							return;
						}
						showAllRegions=true;
						updateShowAllRegions();
						regionFilteredPartnerStatusMapClear();
					}
				}
			}   
		}
	}

	public Boolean isRequired {
		get {
			return (isRequired == true);
		}
		set;
	}

	public Boolean isNew {
		get {
			return (opportunityPartner.Id == null);
		}
	}

    private PartnerStatus__c partnerStatus = null;
    
//	 Partner Status as set with partnerStatusId
	public PartnerStatus__c getPartnerStatus()
	{
		return partnerStatus;
	}
	public void setPartnerStatus(PartnerStatus__c value )
	{
		Id id = null;
		if((partnerStatus = value) != null)
		{
			id = value.Partner__c;
			setPartnerStatusId(value.Id);
		}
		if(opportunityPartner.Partner__c != id)
		{
			opportunityPartner.Partner__c = id;
		}
	}

    private Id partnerStatusId = null;
	public Id getPartnerStatusId()
	{
		return partnerStatusId;
	}
	public void setPartnerStatusId(Id value)
	{
		if(partnerStatusId != value)
		{
			partnerStatusId = value;
			setPartnerStatus(Opportunity_ManagePartners.getPartnerStatusMap().get(value));
		}
	}

    private Id partnerTierId = null;

	public Id getPartnerTierId()
	{
		if(! getFilteredPartnerTierIdSet().contains(partnerTierId))
		{
			partnerTierId = getPartnerTierOptions().get(0).getValue();
		}
		return partnerTierId;
	}
	public void setPartnerTierId(Id value)
	{
		if(partnerTierId != value)
		{
			partnerTierId = value;
			tierFilteredPartnerStatusMap = null;
			filteredPartnerSubTypeIdSet = null;
			fullyFilteredPartnerStatusMap = null;
			partnerSubTypeOptions = null;
		}
	}

	public String getPartnerTierName()
	{
		return hierarchyName(opportunityPartner.PartnerTier__r);
	}

    private Id partnerTypeId = null;
    
	public Id getPartnerTypeId()
	{
		if(partnerTypeId == null)
		{
			partnerTypeId = getPartnerTypeOptions().get(0).getValue();				
		}
		return partnerTypeId;
	}
	public void setPartnerTypeId(Id value) {
		if(partnerTypeId != value)
		{
			partnerTypeId = value;
			typeFilteredPartnerStatusMap = null;
			filteredPartnerTierIdSet = null;
			partnerTierOptions = null;
			tierFilteredPartnerStatusMap = null;
			filteredPartnerSubTypeIdSet = null;
			fullyFilteredPartnerStatusMap = null;
			partnerSubTypeOptions = null;
		}
	}

	private Id partnerSubTypeId = null;
	
	public Id getPartnerSubTypeId()
	{
		if(! getFilteredPartnerSubTypeIdSet().contains(partnerSubTypeId))
		{
			fullyFilteredPartnerStatusMap = null;
			partnerSubTypeId = getPartnerSubTypeOptions().get(0).getValue();			  
		}
		return partnerSubTypeId;
	}
	
	public void setPartnerSubTypeId(Id value)
	{
		partnerSubTypeId = value;
	}

	public String getPartnerTypeName()
	{
		return getName(opportunityPartner.PartnerType__r,1);
	}

	public String getPartnerSubTypeName()
	{
		return getName(opportunityPartner.PartnerType__r,2);
	}

	transient List<SelectOption> partnerSubTypeOptions = null;
	
	public List<SelectOption> getPartnerSubTypeOptions()
	{
		if(partnerSubTypeOptions == null)
		{
			final List<Classification__c> classificationList = new List<Classification__c>();
			for(Classification__c p : getPartnerTypeList())
			{
				if(getFilteredPartnerSubTypeIdSet().contains(p.Id))
				{
					classificationList.add(p);
				}
			}
			partnerSubTypeOptions = getOptionsList(
				classificationList,3,getPartnerTypeId());
		}
		return partnerSubTypeOptions;
	}

	public Boolean getHasPartnerSubTypes()
	{
		return (getPartnerSubTypeOptions().size() > 1);
	}

	transient List<SelectOption> partnerTypeOptions = null;

	public List<SelectOption> getPartnerTypeOptions()
	{
		if(partnerTypeOptions == null)
		{
			List<Classification__c> classificationList = new List<Classification__c>();
			for(Classification__c c : getPartnerTypeList())
			{
				if(c.HierarchyDepth__c <= 2)
				{
					classificationList.add(c);
				}
			}
			partnerTypeOptions = getOptionsList(
				classificationList,2,Opportunity_ManagePartners.rootPartnerTypeId);
		}
		return partnerTypeOptions;
	}

	transient List<SelectOption> partnerTierOptions = null;
	
	public List<SelectOption> getPartnerTierOptions()
	{
		if(partnerTierOptions == null)
		{
			final List<Classification__c> partnerTierList = new List<Classification__c>();
			for(Classification__c c : Opportunity_ManagePartners.getCompletePartnerTierList())
			{
				if(getFilteredPartnerTierIdSet().contains(c.Id))
				{
					partnerTierList.add(c);
				}
			}
			partnerTierOptions = getOptionsList(
				partnerTierList,2,Opportunity_ManagePartners.rootPartnerTierId);
		}
		return partnerTierOptions;
	}

	public List<SelectOption> getPartnerOptions()
	{
		List<SelectOption> retval = new List<SelectOption>();
		retval.add(new SelectOption('', '--None--'));
		Set<Id> partnerSet = new Set<Id>();
		if (opportunityPartner.RelationshipType__c != null)
		{
			Map<String,SelectOption> retvalMap = new Map<String,SelectOption>();
			Map<String,String> hierarchyDescriptionMap = new Map<String,String>();
			Map<Id,Classification__c> partnerTierMap = Opportunity_ManagePartners.getPartnerTierMap();
			Map<Id,Classification__c> partnerTypeMap = Opportunity_ManagePartners.getPartnerTypeMap();
			
			Integer i = 999;
			Id xpartnerSubTypeId = getPartnerSubTypeId();
			Id xpartnerTierId = getPartnerTierId();
			for(PartnerStatus__c xpartnerStatus : getFullyFilteredPartnerStatusMap().values())
			{
				partnerSet.add(xpartnerStatus.Partner__c);
				String name = xpartnerStatus.Partner__r.Name;
				String key = ''+xpartnerStatus.PartnerType__c+xpartnerStatus.PartnerTier__c;
				String s = hierarchyDescriptionMap.get(key);
				if(s == null)
				{
					if(hasDescendents(partnerTierMap.get(xpartnerTierId)))
					{
						s = ' ('+xpartnerStatus.PartnerTier__r.Name;
						if(hasDescendents(partnerTypeMap.get(xpartnerSubTypeId)))
						{
						   s += ', '+hierarchyName(xpartnerStatus.PartnerType__r);
						}
						s += ')';
					}
					else if(hasDescendents(partnerTypeMap.get(xpartnerSubTypeId)))
					{
						s += ' ('+hierarchyName(xpartnerStatus.PartnerType__r)+')';
					}
					else
					{
						s = '';
					}
					hierarchyDescriptionMap.put(key,s);
				}
				name += s;
				key = name.toLowerCase()+'\n'+name;
				if(! retvalMap.containsKey(key))
				{
					retvalMap.put(key,new SelectOption(xpartnerStatus.Id, name));
					if(--i == 0) break;
				}
			}
			List<String> keys = new List<String>(retvalMap.keySet());
			keys.sort();
			for(String key : keys)
			{				 
				retval.add(retvalMap.get(key));
			}
		}
		if(! partnerSet.contains(opportunityPartner.Partner__c))
		{
			opportunityPartner.Partner__c = null;
		}
		return retval;
	}

	public Boolean showAllRegions {
		get {
			return (showAllRegions == true);
		}
		set;
	}


	public PageReference cancelEdit()
	{
		parent.cancelEdit(id);
		return null;
	}

	public PageReference updateRelationshipType()
	{
		regionFilteredPartnerStatusMapClear();
		setPartnerTypeId(null);
		setPartnerTierId(null);
		setPartnerSubTypeId(null);
		return updatePartnerType();
	}

	public PageReference updateShowAllRegions()
	{
		regionFilteredPartnerStatusMapClear();
		return updatePartnerType();
	}

	public PageReference updatePartnerType()
	{
		typeFilteredPartnerStatusMap = null;
		filteredPartnerTierIdSet = null;
		partnerTierOptions = null;
		tierFilteredPartnerStatusMap = null;
		filteredPartnerSubTypeIdSet = null;
		fullyFilteredPartnerStatusMap = null;
		partnerSubTypeOptions = null;
		return null;
	}

	public PageReference updatePartnerTier()
	{
		tierFilteredPartnerStatusMap = null;
		filteredPartnerSubTypeIdSet = null;
		fullyFilteredPartnerStatusMap = null;
		partnerSubTypeOptions = null;
		return null;
	}

	public PageReference updatePartnerSubType()
	{
		fullyFilteredPartnerStatusMap = null;
		return null;
	}

	public PageReference removeOpportunityPartner()
	{
		try
		{
			delete opportunityPartner;
			parent.setPartnerInfoList(null);
			Opportunity_ManagePartners.addConfirmationMessage();
		}
		catch (System.DmlException dmlException)
		{
			Opportunity_ManagePartners.addExceptionMessage(dmlException);
		}
		return null;
	}
}