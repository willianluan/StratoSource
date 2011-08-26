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
			Opportunity__c = parent.opportunity.Id );
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

//	 Generate a list of PartnerStatus object filtered on 
//	 the selected region and relationship type.
	private List<List<PartnerStatus__c>> regionFilteredPartnerStatusLists {
		get {
			if(regionFilteredPartnerStatusLists == null)
			{
				final Set<Id> recordTypeIdSet = new Set<Id>();
				final String recordTypeName = parent.opportunity.RecordType.Name;
				for(String regionName : Opportunity_ManagePartners.accountRecordTypeIdByRegion.keySet())
				{
					if(recordTypeName == regionName || recordTypeName.startsWith(regionName+' ') || recordTypeName.contains(' '+regionName+' ') || recordTypeName.endsWith(' '+regionName))
					{
						recordTypeIdSet.addAll(Opportunity_ManagePartners.accountRecordTypeIdByRegion.get(regionName));
						break;
					}
				}
				if(recordTypeIdSet.isEmpty() || showAllRegions)
				{
					showAllRegions = true;
					for(Set<Id> ids : Opportunity_ManagePartners.accountRecordTypeIdByRegion.values())
					{
						recordTypeIdSet.addAll(ids);
					}
				}
				Pattern pat = getPartnerTypePattern(parent.opportunity.FulfillmentChannel__c,opportunityPartner.RelationshipType__c);
				final List<List<PartnerStatus__c>> retval = new List<List<PartnerStatus__c>>();
				List<PartnerStatus__c> currentList = null;
				for(List<PartnerStatus__c> partnerStatusList : Opportunity_ManagePartners.completePartnerStatusLists)
				{
					for(PartnerStatus__c p : partnerStatusList)
					{
						if((pat == null || pat.matcher(p.PartnerType__r.Hierarchy__c).matches())&&recordTypeIdSet.contains(p.Partner__r.RecordTypeId))
						{
							try
							{
								currentList.add(p);
							}
							catch(Exception e)
							{
								currentList = new List<PartnerStatus__c>();
								retval.add(currentList);
								currentList.add(p);
							}
						}
					}
				}
				regionFilteredPartnerStatusLists = retval;
			}
			return regionFilteredPartnerStatusLists;
		}
		set {
			regionFilteredPartnerStatusLists = value;
			filteredPartnerTypeIdSet = null;
		}
	}

//	 Use the regionFilteredPartnerStatusList to generate a set of 
//	 Partner Type Id's with associated Partner's.		
	private Set<Id> filteredPartnerTypeIdSet {
		get {
			if(filteredPartnerTypeIdSet == null)
			{
				final Set<Id> idSet = new Set<Id>();
				for(List<PartnerStatus__c> partnerStatusList : regionFilteredPartnerStatusLists)
				{
					for(PartnerStatus__c p : partnerStatusList)
					{
						addRecursive(Opportunity_ManagePartners.partnerTypeMap,idSet,p.PartnerType__c);
					}
				}
				filteredPartnerTypeIdSet = idSet;
			}
			return filteredPartnerTypeIdSet;
		}
		set {
			filteredPartnerTypeIdSet = value;
			typeFilteredPartnerStatusLists = null;
			partnerTypeList = null;
		}
	}

	private List<Classification__c>  partnerTypeList {
		get {
			if(partnerTypeList == null)
			{
				final List<Classification__c> retval = new List<Classification__c>();
				for(Classification__c c : Opportunity_ManagePartners.completePartnerTypeList)
				{
					if(filteredPartnerTypeIdSet.contains(c.Id))
					{
						retval.add(c);
					}
				}
				partnerTypeList = retval;
			}
			return partnerTypeList;
		}
		set {
			partnerTypeList = value;
			partnerTypeOptions = null;
			typeFilteredPartnerStatusLists = null;
		}
	}

//	 Generate a list of PartnerStatus object filtered on 
//	 the selected PartnerTypeId
	private List<List<PartnerStatus__c>> typeFilteredPartnerStatusLists {
		get {
			if(typeFilteredPartnerStatusLists == null)
			{
				final List<List<PartnerStatus__c>> retval = new List<List<PartnerStatus__c>>();
				List<PartnerStatus__c> currentList = null;
				final Set<Id> partnerTypeIdSet = getClassificationIdSet(
					partnerTypeList,partnerTypeId,Opportunity_ManagePartners.rootPartnerTypeId);
				for(List<PartnerStatus__c> partnerStatusList : regionFilteredPartnerStatusLists)
				{
					for(PartnerStatus__c p : partnerStatusList)
					{
						if(partnerTypeIdSet.contains(p.PartnerType__c))
						{
							try
							{
								currentList.add(p);
							}
							catch(Exception e)
							{
								currentList = new List<PartnerStatus__c>();
								retval.add(currentList);
								currentList.add(p);
							}
						}
					}
				}
				typeFilteredPartnerStatusLists = retval;
			}
			return typeFilteredPartnerStatusLists;
		}
		set {
			typeFilteredPartnerStatusLists = value;
			filteredPartnerTierIdSet = null;
		}
	}

//	 Use the typeFilteredPartnerStatusList to generate a set of 
//	 Partner Tier Id's with associated Partner's.		
	private Set<Id> filteredPartnerTierIdSet {
		get {
			if(filteredPartnerTierIdSet == null)
			{
				final Set<Id> idSet = new Set<Id>();
				for(List<PartnerStatus__c> partnerStatusList : typeFilteredPartnerStatusLists)
				{
					for(PartnerStatus__c p : partnerStatusList)
					{
						addRecursive(Opportunity_ManagePartners.partnerTierMap,idSet,p.PartnerTier__c);
					}
				}
				filteredPartnerTierIdSet = idSet;
			}
			return filteredPartnerTierIdSet;
		}
		set {
			filteredPartnerTierIdSet = value;
			partnerTierOptions = null;
			tierFilteredPartnerStatusLists = null;
		}
	}

//	 Generate a list of PartnerStatus object in the 
//	 typeFilteredPartnerStatusLists filtered on 
//	 the selected PartnerTierId.
	private List<List<PartnerStatus__c>> tierFilteredPartnerStatusLists {
		get {
			if(tierFilteredPartnerStatusLists == null)
			{
				final List<List<PartnerStatus__c>> retval = new List<List<PartnerStatus__c>>();
				List<PartnerStatus__c> currentList = null;
				final Set<Id> partnerTierIdSet = getClassificationIdSet(
					Opportunity_ManagePartners.completePartnerTierList,partnerTierId,Opportunity_ManagePartners.rootPartnerTierId);
				for(List<PartnerStatus__c> partnerStatusList : typeFilteredPartnerStatusLists)
				{
					for(PartnerStatus__c p : partnerStatusList)
					{
						if(partnerTierIdSet.contains(p.PartnerTier__c))
						{
							try
							{
								currentList.add(p);
							}
							catch(Exception e)
							{
								currentList = new List<PartnerStatus__c>();
								retval.add(currentList);
								currentList.add(p);
							}
						}
					}
				}
				tierFilteredPartnerStatusLists = retval;
			}
			return tierFilteredPartnerStatusLists;
		}
		set {
			tierFilteredPartnerStatusLists = value;
			filteredPartnerSubTypeIdSet = null;
		}
	}

//	 Use the tierFilteredPartnerStatusLists to generate a set of 
//	 Partner Sub-Type Id's with associated Partner's.		
	private Set<Id> filteredPartnerSubTypeIdSet {
		get {
			if(filteredPartnerSubTypeIdSet == null)
			{
				final Set<Id> retval = new Set<Id>();
				final Classification__c partnerType = Opportunity_ManagePartners.partnerTypeMap.get(partnerTypeId);
				if(partnerType != null)
				{
					retval.add(partnerTypeId);
					if(partnerType.HierarchyDepth__c == 2 && partnerType.Descendents__c > 0)
					{
						final Set<Id> idSet = new Set<Id>();
						for(List<PartnerStatus__c> partnerStatusList : tierFilteredPartnerStatusLists)
						{
							for(PartnerStatus__c p : partnerStatusList)
							{
								addRecursive(Opportunity_ManagePartners.partnerTypeMap,idSet,p.PartnerType__c);
							}
						}
						idSet.retainAll(getClassificationIdSet(partnerTypeList,partnerTypeId,null));
						retval.addAll(idSet);
					}
				}
				filteredPartnerSubTypeIdSet = retval;
			}
			return filteredPartnerSubTypeIdSet;
		}
		set {
			filteredPartnerSubTypeIdSet = value;
			partnerSubTypeOptions = null;
			fullyFilteredPartnerStatusLists = null;
		}
	}

//	 Generate a list of PartnerStatus object in the 
//	 tierFilteredPartnerStatusLists filtered on 
//	 the selected PartnerSubTypeId.
	private List<List<PartnerStatus__c>> fullyFilteredPartnerStatusLists {
		get {
			if(fullyFilteredPartnerStatusLists == null)
			{
				final List<List<PartnerStatus__c>> retval = new List<List<PartnerStatus__c>>();
				List<PartnerStatus__c> currentList = null;
				final Set<Id> partnerSubTypeIdSet = getClassificationIdSet(
					partnerTypeList,partnerSubTypeId,Opportunity_ManagePartners.rootPartnerTypeId);
				for(List<PartnerStatus__c> partnerStatusList : tierFilteredPartnerStatusLists)
				{
					for(PartnerStatus__c p : partnerStatusList)
					{
						if(partnerSubTypeIdSet.contains(p.PartnerType__c))
						{
							try
							{
								currentList.add(p);
							}
							catch(Exception e)
							{
								currentList = new List<PartnerStatus__c>();
								retval.add(currentList);
								currentList.add(p);
							}
						}
					}
				}
				fullyFilteredPartnerStatusLists = retval;
			}
			return fullyFilteredPartnerStatusLists;
		}
		set {
			fullyFilteredPartnerStatusLists = value;
		}
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
					for(Integer i=0;i<2;i++)
					{
						for(List<PartnerStatus__c> partnerStatusList : fullyFilteredPartnerStatusLists)
						{
							for(PartnerStatus__c partnerStatus : partnerStatusList)
							{
								if(partnerStatus.Partner__c == opportunityPartner.Partner__c)
								{
									partnerStatusId = partnerStatus.Id;
									String [] splitPartnerType = opportunityPartner.PartnerType__r.Hierarchy__c.split(' » ',3);
									if(splitPartnerType.size() >= 2)
									{
										for(Classification__c c : partnerTypeList)
										{
											String [] s = c.Hierarchy__c.split(' » ',3);
											if(s.size() == 2 && s[0] == splitPartnerType[0] && s[1] == splitPartnerType[1])
											{
												partnerTypeId = c.Id;
												updatePartnerType();
												break;
											}
										}
									}
									partnerTierId = partnerStatus.PartnerTier__c;
									updatePartnerTier();
									partnerSubTypeId = partnerStatus.PartnerType__c;
									updatePartnerSubType();
									return;
								}
							}
						}
						showAllRegions=true;
						updateShowAllRegions();
						regionFilteredPartnerStatusLists = null;
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

//	 Partner Status as set with partnerStatusId
	public PartnerStatus__c partnerStatus {
		get;
		set {
			Id id = null;
			if((partnerStatus = value) != null)
			{
				id = value.Partner__c;
				partnerStatusId = value.Id;
			}
			if(opportunityPartner.Partner__c != id)
			{
				opportunityPartner.Partner__c = id;
			}
		}
	}

	public Id partnerStatusId {
		get;
		set {
			if(partnerStatusId != value)
			{
				partnerStatusId = value;
				for(Map<Id,PartnerStatus__c> partnerStatusMap : Opportunity_ManagePartners.partnerStatusMaps)
				{
					if((partnerStatus = partnerStatusMap.get(value)) != null)
					{
						break;
					}
				}
			}
		}
	}

	public Id partnerTierId {
		get {
			if(! filteredPartnerTierIdSet.contains(partnerTierId))
			{
				partnerTierId = partnerTierOptions.get(0).getValue();
			}
			return partnerTierId;
		}
		set {
			if(partnerTierId != value)
			{
				partnerTierId = value;
				tierFilteredPartnerStatusLists = null;
			}
		}
	}

	public String getPartnerTierName()
	{
		return hierarchyName(opportunityPartner.PartnerTier__r);
	}

	public Id partnerTypeId {
		get {
			if(partnerTypeId == null)
			{
				partnerTypeId = partnerTypeOptions.get(0).getValue();				
			}
			return partnerTypeId;
		}
		set {
			if(partnerTypeId != value)
			{
				partnerTypeId = value;
				typeFilteredPartnerStatusLists = null;
				filteredPartnerTierIdSet = null;
				filteredPartnerSubTypeIdSet = null;
			}
		}
	}

	public Id partnerSubTypeId {
		get {
			if(! filteredPartnerSubTypeIdSet.contains(partnerSubTypeId))
			{
				partnerSubTypeId = partnerSubTypeOptions.get(0).getValue();			  
			}
			return partnerSubTypeId;
		}
		set {
			if(partnerSubTypeId != value)
			{
				partnerSubTypeId = value;
				fullyFilteredPartnerStatusLists = null;
			}
		}
	}

	public String getPartnerTypeName()
	{
		return getName(opportunityPartner.PartnerType__r,1);
	}

	public String getPartnerSubTypeName()
	{
		return getName(opportunityPartner.PartnerType__r,2);
	}

	public List<SelectOption> partnerSubTypeOptions {
		get {
			if(partnerSubTypeOptions == null)
			{
				final List<Classification__c> classificationList = new List<Classification__c>();
				for(Classification__c p : partnerTypeList)
				{
					if(filteredPartnerSubTypeIdSet.contains(p.Id))
					{
						classificationList.add(p);
					}
				}
				partnerSubTypeOptions = getOptionsList(
					classificationList,3,partnerTypeId);
			}
			return partnerSubTypeOptions;
		}
		set;
	}

	public Boolean getHasPartnerSubTypes()
	{
		return (partnerSubTypeOptions.size() > 1);
	}

	public List<SelectOption> partnerTypeOptions
	{
		get {
			if(partnerTypeOptions == null)
			{
				List<Classification__c> classificationList = new List<Classification__c>();
				for(Classification__c c : partnerTypeList)
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
		set;
	}

	public List<SelectOption> partnerTierOptions {
		get {
			if(partnerTierOptions == null)
			{
//		   Finally we prepare the list of used partner types
				final List<Classification__c> partnerTierList = new List<Classification__c>();
				for(Classification__c c : Opportunity_ManagePartners.completePartnerTierList)
				{
					if(filteredPartnerTierIdSet.contains(c.Id))
					{
						partnerTierList.add(c);
					}
				}
				partnerTierOptions = getOptionsList(
					partnerTierList,2,Opportunity_ManagePartners.rootPartnerTierId);
			}
			return partnerTierOptions;
		}
		set;
	}

	public List<SelectOption> getPartnerOptions()
	{
		List<SelectOption> retval = new List<SelectOption>();
		retval.add(new SelectOption('', '--None--'));
		Set<Id> partnerSet = new Set<Id>();
		if (opportunityPartner.RelationshipType__c != null)
		{
			Set<String> optionLabelSet = new Set<String>();
			for(List<PartnerStatus__c> partnerStatusList : fullyFilteredPartnerStatusLists)
			{
				for(PartnerStatus__c partnerStatus : partnerStatusList)
				{
					partnerSet.add(partnerStatus.Partner__c);
					String name = partnerStatus.Partner__r.Name;
					if(hasDescendents(Opportunity_ManagePartners.partnerTierMap.get(partnerTierId)))
					{
						name += ' ('+hierarchyName(partnerStatus.PartnerTier__r);
						if(hasDescendents(Opportunity_ManagePartners.partnerTypeMap.get(partnerSubTypeId)))
						{
							name += ', '+hierarchyName(partnerStatus.PartnerType__r);
						}
						name += ')';
					}
					else if(hasDescendents(Opportunity_ManagePartners.partnerTypeMap.get(partnerSubTypeId)))
					{
						name += ' ('+hierarchyName(partnerStatus.PartnerType__r)+')';
					}
					if(! optionLabelSet.contains(name))
					{
						optionLabelSet.add(name);
						try
						{
							if(retval.size() < 1000)
							{
							    retval.add(new SelectOption(partnerStatus.Id, name));
							}
						}
						catch(Exception e)
						{
							break;
						}
					}
				}
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
		regionFilteredPartnerStatusLists = null;
		partnerTypeId = null;
		partnerTierId = null;
		partnerSubTypeId = null;
		return updatePartnerType();
	}

	public PageReference updateShowAllRegions()
	{
		regionFilteredPartnerStatusLists = null;
		return updatePartnerType();
	}

	public PageReference updatePartnerType()
	{
		filteredPartnerTierIdSet = null;
		filteredPartnerSubTypeIdSet = null;
		typeFilteredPartnerStatusLists = null;
		return null;
	}

	public PageReference updatePartnerTier()
	{
		tierFilteredPartnerStatusLists = null;
		return null;
	}

	public PageReference updatePartnerSubType()
	{
		fullyFilteredPartnerStatusLists = null;
		return null;
	}

	public PageReference removeOpportunityPartner()
	{
		try
		{
			delete opportunityPartner;
			parent.partnerInfoList = null;
			Opportunity_ManagePartners.addConfirmationMessage();
		}
		catch (System.DmlException dmlException)
		{
			Opportunity_ManagePartners.addExceptionMessage(dmlException);
		}
		return null;
	}
}