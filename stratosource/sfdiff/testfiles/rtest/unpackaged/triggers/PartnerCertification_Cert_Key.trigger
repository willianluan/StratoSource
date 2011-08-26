trigger PartnerCertification_Cert_Key on PartnerTraining__c (before update, before insert) 
{
	for ( PartnerTraining__c newPartnerCertification : Trigger.new )
	{
		Classification__c clfn = [Select HierarchyKey__c From Classification__c Where ID=:newPartnerCertification.Certification__c];
		newPartnerCertification.Certification_Key__c = clfn.HierarchyKey__c;
	}
}