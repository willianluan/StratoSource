trigger OpportunityPartner_Legacy on OpportunityPartner__c (before insert,before update,after delete) {
    List<OpportunityPartner__c> needLegacy = new List<OpportunityPartner__c>();
    Set<Id> opportunityIds = new Set<Id>();
    Map<Id,OpportunityPartner__c> oldLegacyIdMap = new Map<Id,OpportunityPartner__c>();
    if(! Trigger.isInsert)
    {
        for(OpportunityPartner__c op : Trigger.old)
        {
            opportunityIds.add(op.Opportunity__c);
            oldLegacyIdMap.put(op.Legacy_PartnerId__c,op);
        }
        oldLegacyIdMap.remove(null);
    }
    Set<Id> newLegacyIds = new Set<Id>();
    if(! Trigger.isDelete)
    {
        for(OpportunityPartner__c op : Trigger.new)
        {
        	if(op.Partner__c == null)
        	{
        		op.addError('Partner is required.');
        		continue;
        	}
            opportunityIds.add(op.Opportunity__c);
            if(Trigger.isUpdate)
            {
                OpportunityPartner__c o = Trigger.oldMap.get(op.Id);
                if(op.Legacy_PartnerId__c == o.Legacy_PartnerId__c)
                {
                    if(op.Partner__c != o.Partner__c || op.PartnerType__c != o.PartnerType__c || op.PartnerTier__c != o.PartnerTier__c)
                    {
                        op.Legacy_PartnerId__c = null;
                    }
                }
            }
            String id = null;
            newLegacyIds.add((id=op.Legacy_PartnerId__c));
            if(id == null && op.RelationshipType__c != null)
            {
                needLegacy.add(op);
            }
        }
        oldLegacyIdMap.keySet().removeAll(newLegacyIds);
    }
    opportunityIds.remove(null);
    List<Partner> partners = new List<Partner>();
    List<OpportunityPartner__c> ops = new List<OpportunityPartner__c>();
    // find and clean-up orphaned legacy opportunity partner records.
    List<Id> partnerIdsToRemove = new List<Id>(oldLegacyIdMap.keySet());
    if(Trigger.isInsert && ! opportunityIds.isEmpty())
    {
        // It seems that adding one partner record automatically adds a reverse partner record.
        // Removing the reverse partner, also removes the partner record we added.   So there 
        // is no way to simply remove any partners we did not add.
        // Instead we simply look for opportunity Id's for which we have not added any partners.
        System.debug('Opportunity Ids to scan = '+opportunityIds);
        for(AggregateResult ar : [select Opportunity__c from OpportunityPartner__c where Opportunity__c in : opportunityIds and Legacy_PartnerId__c != null Group By Opportunity__c Having Count(Id) > 0 ])
        {
            // We have added one or more partners to this opportunity, so remove it from the list.
            opportunityIds.remove((Id)ar.get('Opportunity__c'));
        }
        System.debug('Opportunity Ids to clean = '+opportunityIds);
        // add any Partners associated to these opportunities to our remove list.
        partnerIdsToRemove.addAll(new Map<Id,Partner>([select Id from Partner where OpportunityId in :opportunityIds]).keySet());
    }
    // clean-up old partner records
    System.debug('Partners to remove='+partnerIdsToRemove);
    if(! partnerIdsToRemove.isEmpty())
    {
        for(Database.DeleteResult r : database.delete(partnerIdsToRemove,false))
        {
            Id legacyId = partnerIdsToRemove.remove(0);
            OpportunityPartner__c op = oldLegacyIdMap.get(legacyId);
            for(Database.Error e : r.getErrors()) {
                String m = e.getMessage();
                System.debug('legacyId='+legacyId+',error='+m);
                if(op != null)
                {
                    if(! m.contains('invalid cross reference'))
                    {
                        op.addError(e.getMessage());
                    }
                }
            }
        }
    }
    // to do: add new legacy opportunity partner objects
    if(! needLegacy.isEmpty())
    {
       /*
        Map<String,PartnerRole> partnerRoleMap = new Map<String,PartnerRole>{
            'Distributor'=>new PartnerRole(MasterLabel='Distributor', Id='01J30000002EOlyEAG'),
            'System Integrator'=>new PartnerRole(ReverseRole='Supplier', MasterLabel='System Integrator', Id='01J30000002EOm0EAG'),
            'Value Added Reseller'=>new PartnerRole(ReverseRole='Vendor', MasterLabel='Value Added Reseller', Id='01J30000002EOm1EAG'),
            'OEM'=>new PartnerRole(ReverseRole='Customer', MasterLabel='OEM', Id='01J300000038ZAOEA2'),
            'Training'=>new PartnerRole(ReverseRole='Supplier', MasterLabel='Training', Id='01J300000038ZAsEAM'),
            'Other'=>new PartnerRole(ReverseRole='Other', MasterLabel='Other', Id='01J300000038ZAxEAM'),
            'Advanced Partner'=>new PartnerRole(ReverseRole='Customer', MasterLabel='Advanced Partner', Id='01J30000003dC4lEAE'),
            'ISV'=>new PartnerRole(ReverseRole='Supplier', MasterLabel='ISV', Id='01J30000003dCeYEAU'),
            'Technology'=>new PartnerRole(ReverseRole='Vendor', MasterLabel='Technology', Id='01J30000003dCemEAE'),
            'Chip'=>new PartnerRole(ReverseRole='Supplier', MasterLabel='Chip', Id='01J60000007RvmnEAC')
        };
        */
        Map<String,String> partnerRoleNameMap = new Map<String,String>{
            'Distributor'=>'Distributor',
            'Global Chip'=>'Chip',
            'ISP.Training'=>'Training',            
            'ISP'=>'Other',
            'ISV'=>'ISV',
            'OEM'=>'OEM',
            'Reseller:Advanced'=>'Advanced Partner',
            'Reseller.'=>'Value Added Reseller',
            'Reseller'=>'Other',
            'SI'=>'System Integrator'};
        for(OpportunityPartner__c op : needLegacy)
        {
            String roleName = 'Distributor';
            if(! 'Financial'.equalsIgnoreCase(op.RelationshipType__c))
            {
                roleName = partnerRoleNameMap.get(op.PartnerTypeName__c+'.'+op.PartnerSubTypeName__c+':'+op.PartnerTierName__c);
                if(roleName == null)
                {
                    roleName = partnerRoleNameMap.get(op.PartnerTypeName__c+':'+op.PartnerTierName__c);
                    if(roleName == null)
                    {
                        roleName = partnerRoleNameMap.get(op.PartnerTypeName__c+'.'+op.PartnerSubTypeName__c);
                        if(roleName == null)
                        {
                            roleName = partnerRoleNameMap.get(op.PartnerTypeName__c);
                            if(roleName == null)
                            {
                        	    roleName = 'Other';
                            }
                        }
                    }
                }
            }
            if(roleName != null)
            {
                ops.add(op);
                partners.add(new Partner(OpportunityId=op.Opportunity__c,AccountToId=op.Partner__c,Role=roleName));
            }
        }
        if(! partners.isEmpty())
        {
            for(Database.SaveResult r : database.insert(partners,false))
            {
                Partner p = partners.remove(0);
                OpportunityPartner__c op = ops.remove(0);
                op.Legacy_PartnerId__c = p.Id;
                for(Database.Error e : r.getErrors())
                {
                    op.addError(e.getMessage());
                }
            }
        }
    }
}