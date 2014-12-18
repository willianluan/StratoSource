@IsTest
private class ServiceEndpoint_UpdateAccountTeamTest {
    public static testmethod void testGenerateCodeCoverage() {
          //select a partner account with a partner user
        User u = [Select ContactId, Contact.AccountId from User where ContactId != null limit 1];
        Account account = new Account(Id = u.Contact.AccountId, PrimaryPartnerUser__c = u.id);
        update account;
        
        PartnerStatus__c partnerStatus = new PartnerStatus__c();
        partnerStatus.Partner__c = account.Id;
        partnerStatus.PartnerTier__c = [
            select Id
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TIER.READY'
             limit 1
        ].Id;
        partnerStatus.PartnerType__c = [
            select Id
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TYPE.RESELLER'
             limit 1
        ].Id;
        partnerStatus.ActivationDate__c = Date.today();
        partnerStatus.ExpirationDate__c = Date.today().addYears(1);
        partnerStatus.ApprovalStatus__c = 'Approved';
        insert partnerStatus;
        
        // Build the service message
        DOM.Document serviceMessageDocument = new DOM.Document();
        DOM.XmlNode serviceMessageDocumentXml = serviceMessageDocument.createRootElement('envelope', System.Label.NS_SOAP, 'soap');
        DOM.XmlNode serviceMessageXml = serviceMessageDocumentXml.addChildElement('body', System.Label.NS_SOAP, null);
        serviceMessageXml.setNamespace('service', System.Label.NS_SERVICE);
        serviceMessageXml.setAttributeNS('generatedBy', 'ServiceEndpoint_UpdateAccountTeamTest', System.Label.NS_SERVICE, null);
        serviceMessageXml.setAttributeNS('convertedLeadId', '', System.Label.NS_SERVICE, null);
        serviceMessageXml.setAttributeNS('accountId', account.Id, System.Label.NS_SERVICE, null);
        
        ServiceMessage__c serviceMessage = new ServiceMessage__c();
        serviceMessage.Command__c = '/account/update-account-team';
        serviceMessage.Payload__c = serviceMessageDocument.toXmlString();
        insert serviceMessage;
        update serviceMessage;
        delete serviceMessage;
    }

}