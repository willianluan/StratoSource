public with sharing class AgreementControllerExt {

      public Agreement__c agreementInfo {get; set;}
      public List<Agreement_Country__c> agreementCountryList {get; set;}
      
      public List<Agreement_Country__c> deleteList {get; set;}
      public List<Agreement_Country__c> createList {get; set;}
      
      public AgreementControllerExt(ApexPages.StandardController controller) {
          Id agreementId = controller.getId();
          this.deleteList = new List<Agreement_Country__c>();
           this.createList = new List<Agreement_Country__c>();
          if (agreementId != null) {
              this.agreementInfo = [Select Version__c, Type__c, SubRegion__c, Region__c, PartnerType__c, OwnerId, Number__c, 
                               Name, IsSignatureRequired__c, Id, CurrencyIsoCode, ApprovalStatus__c, ActivationStatus__c, 
                               ActivationDate__c,ExpirationDate__c From Agreement__c where Id = :agreementId];
              this.agreementCountryList = [Select Name, Id, Country__c, Agreement__c From Agreement_Country__c Where Agreement__c =: agreementId];                  
          } else {
              this.agreementInfo = new Agreement__c();
              this.agreementCountryList = new List<Agreement_Country__c>();
          }             
      }
      
      public PageReference saveAgreement() {
          try {
              if (agreementInfo.Id == null) {
                  agreementInfo.ApprovalStatus__c ='draft'; 
              }
              upsert agreementInfo;
              System.debug('Agreement ID---->'+agreementInfo.Id);
              for (Agreement_Country__c agreementCountry : createList) {
                  agreementCountry.Agreement__c = agreementInfo.Id;
              }
              insert this.createList;
              delete this.deleteList;
              return new PageReference('/'+ agreementInfo.Id);
          } catch(Exception e) {
            System.debug(e);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
          }
          return null;
      }
      
      public PageReference cancelAgreement() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.DescribeSObjectResult r = gd.get('Agreement__c').getDescribe();
        String url = '/'+r.getKeyPrefix()+'/o';
        return new PageReference(url);
      }
      
      
      public List<SelectOption> getCountries() {
           List<SelectOption> countrySelectionList = new List<SelectOption>();
           List<Country__c> countryList = [Select c.Name, c.Id From Country__c c order by c.Global_Region__c , c.Name];
           for(Country__c country:countryList) {
               countrySelectionList.add(new SelectOption(country.Id, country.Name));    
           }
           return countrySelectionList;
      }
      
      public List<Id> getAgreementCountries() {
          List<Id> countryIdList = new List<Id>();
          for (Agreement_Country__c agreementCountry : agreementCountryList) {
              countryIdList.add(agreementCountry.Country__c);
          }
          return countryIdList;
      }
      
      public void setAgreementCountries( List<Id> countryIdList) {
          Set<Id> countrySet = new Set<Id>();
          countrySet.addAll(countryIdList);
            
          for (Agreement_Country__c agreementCountry : agreementCountryList) {
                if (countrySet.contains(agreementCountry.Id)) {
                    countrySet.remove(agreementCountry.Id);
                } else {
                    //has been deselected...add to delete list
                    this.deleteList.add(agreementCountry);
                }
            }
            //remaining - need to create
            for (Id countryId : countrySet) {
                this.createList.add(new Agreement_Country__c(Agreement__c = this.agreementInfo.Id,Country__c = countryId));
            }
      }      
      

}