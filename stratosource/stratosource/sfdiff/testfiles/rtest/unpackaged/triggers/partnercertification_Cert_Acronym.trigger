trigger partnercertification_Cert_Acronym on PartnerTraining__c (before update, before insert) 
{

for ( PartnerTraining__c newPartnerCertification : Trigger.new )
         {
 
// Set the Certification Acronym
 //      if( newPartnerCertification.Certification__r.HierarchyKey__c != 'PARTNER_TRAINING.RED_HAT.RED_HAT_CERTIFIED_ARCHITECT')
   //    { 
                   
       newPartnerCertification.Certification_Key__c = newPartnerCertification.Certification__r.HierarchyKey__c;
        update newPartnerCertification;

}
}