public without sharing class OnboardingController {
    // ^ Sharing is DISABLED - write cautious code!

    public static final String ERROR_REQUIRED_FIELD = 'This field is required: ';

    public static final String PARAM_COMPANY = 'rhn-company-name';
    public static final String PARAM_EMAIL = 'rhn-email';
    public static final String PARAM_FIRST_NAME = 'rhn-first-name';
    public static final String PARAM_LAST_NAME = 'rhn-last-name';
    public static final String PARAM_COUNTRY_CODE = 'rhn-country-code';

    public static final String PARAM_FEDERATION_ID = 'federation-id';
    public static final String PARAM_PARTNER_ID = 'partner-id';
    public static final String PARAM_PARTNER_NAME = 'partner-name';
    public static final String PARAM_LEGACY = 'legacy';
    public static final String PARAM_LANGUAGE = 'language';
        
    public Country__c selectedCountry {get; set;}

    public String getDebugParams() {
        String params = '';
        
        for(String name : ApexPages.currentPage().getParameters().keySet())
            params += name + '=' + ApexPages.currentPage().getParameters().get(name) + '&';
            
        return params;
    }

    //
    // All of the describes are done up front, in a single exection. We are currently using
    // up 8 of 10 available getDescribe() calls.
    //
    
    public static final Map<String, List<Schema.PicklistEntry>> PICKLIST_ENTRIES = new Map<String, List<Schema.PicklistEntry>> {
        'Additional_Countries_Of_Operations__c' => Lead.Additional_Countries_Of_Operations__c.getDescribe().getPicklistValues(),
        'Additional_Partnerships__c' => Lead.Additional_Partnerships__c.getDescribe().getPicklistValues(),
        'Application_Types__c' => Lead.Application_Types__c.getDescribe().getPicklistValues(),
        'Industry_Focus__c' => Lead.Industry_Focus__c.getDescribe().getPicklistValues(),
        'Middleware_Supported__c' => Lead.Middleware_Supported__c.getDescribe().getPicklistValues(),
        'Operating_System_Supported__c' => Lead.Operating_System_Supported__c.getDescribe().getPicklistValues(),
        'Software_Focus__c' => Lead.Software_Focus__c.getDescribe().getPicklistValues(),
        'Target_Market_Size__c' => Lead.Target_Market_Size__c.getDescribe().getPicklistValues()
    };

    //
    // Handle the onboarding process as an extension.
    //

    public OnboardingController(ApexPages.StandardController controller) {
        this.controller = controller;
        LeadCompanyName = getParam(PARAM_COMPANY);
        if (LeadCompanyName == null || LeadCompanyName.equals('')){
            LeadCompanyName = getParam(PARAM_PARTNER_NAME) != null ? getParam(PARAM_PARTNER_NAME) : '';         
        }
        
        // Make sure the current request has a federation-id parameter
        // If not, send them to the rh.com login page
        FederationId = getParam(PARAM_FEDERATION_ID);
        if (federationId == null) {
            CurrentPageName = 'Login';
            return;
        }

		LanguageCode = getParam(PARAM_LANGUAGE);
		if (LanguageCode == null) {
			LanguageCode = 'en';
		}
        Language = getLocalePicklistName(LanguageCode, null);

        //
        // Copy the RHN information to the lead
        //

        getLead().FirstName = getParam(PARAM_FIRST_NAME);
        getLead().LastName = getParam(PARAM_LAST_NAME);
        getLead().Email = getParam(PARAM_EMAIL);
        getLead().Company = getParam(PARAM_COMPANY);
        getLead().RHNLogin__c = federationId;
        getLead().Onboarding_Language_Preference__c = LanguageCode;

        //
        // Load the countries and states
        //

        SelectableCountryList = [
            select Name, Abbreviation__c, Global_Region__c, Subregion__c,IsAgreementSignatureRequired__c, iso3166Alpha2__c
         , (select Name, Abbreviation__c from States__r order by Name asc)
              from Country__c order by Name asc
        ];

        //
        // Load the partner type objects
        //

        PartnerTypeISV = [
            select Name
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TYPE.ISV'
             limit 1
        ];

        PartnerTypeReseller = [
            select Name
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TYPE.RESELLER'
             limit 1
        ];

        PartnerTierReady = [
            select Name
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TIER.READY'
             limit 1
        ];

        //
        // Load other helpful data
        //

        PartnerGeneralIssuesRecordTypeId = [        
            select id
              from RecordType
             where sObjectType = 'Case'
               and Name = 'Partner General Issues' 
        ].id;
        
        if ('true'.equalsIgnoreCase(getParam(PARAM_LEGACY))) {
            PartnerId = getParam(PARAM_PARTNER_ID);
            PartnerName = getParam(PARAM_PARTNER_NAME);
        }
        
        //
        // Determine the initial action
        //       
        processInitialAction();
    }

    public ApexPages.StandardController controller {
        get;
        set;
    }

    public Lead getLead() {
        return (Lead) controller.getRecord();
    }
    
    public void setLead(Lead lead) {
        getLead().Partner_Onboarding_Status__c = lead.Partner_Onboarding_Status__c;
        getLead().Partner_Type__c = lead.Partner_Type__c;
        getLead().Account__c = lead.Account__c;
        getLead().Partner_Type__r = lead.Partner_Type__r;
        getLead().Company = lead.Company;
        getLead().Street = lead.Street;
        getLead().City = lead.City;
        getLead().State = lead.State;
        getLead().Country = lead.Country;
        getLead().PostalCode = lead.PostalCode;
        getLead().Global_Region__c = lead.Global_Region__c;
        getLead().Subregion__c = lead.Subregion__c;
        getLead().RHNLogin__c = lead.RHNLogin__c;
        getLead().Other_Countries__c = lead.Other_Countries__c;
        if (lead.Onboarding_Language_Preference__c != null) {
	        getLead().Onboarding_Language_Preference__c = lead.Onboarding_Language_Preference__c;
        }
    }
    
    private void clearLead() {
        getLead().Partner_Onboarding_Status__c = null;
        getLead().Partner_Type__c = null;
        getLead().Account__c = null;
        getLead().Partner_Type__r = null;
        getLead().Company = null;
        getLead().Street = null;
        getLead().City = null;
        getLead().State = null;
        getLead().Country = null;
        getLead().PostalCode = null;
        getLead().Other_Countries__c = null;
        getLead().Onboarding_Language_Preference__c = null;
    }

    //
    // All important page name
    //

    public String CurrentPageName {
        set;
        get;
    }
    
    public String LeadCompanyName {
        set;
        get;
    }

    public Integer CurrentStep {
        get {
            return new Map<String, Integer> {
                'Login' => 1,
                'JoinOrRegister' => 2,
                'JoinConfirm' => 4,
                'JoinThankYou' => 99,

                'RegisterPartner' => 3,
                'RegisterAgreements' => 3,
                'RegisterProfile' => 4,
                'RegisterDemographics' => 4,
                'RegisterThankYou' => 99,

                null => 1
            }.get(currentPageName);
        }
    }

    //
    // Accessors
    //

    public Boolean AgreementsAccepted {
        set;
        get;
    }
    
    public String agreementAcceptence {
        set;
        get;
    }

    public List<Country__c> SelectableCountryList {
        set;
        get;
    }

    public Classification__c PartnerTypeISV {
        set;
        get;
    }

    public Classification__c PartnerTypeReseller {
        set;
        get;
    }

    public Classification__c PartnerTierReady {
        set;
        get;
    }

    public Classification__c SelectedPartnerType {
        get {
            if (getLead().Partner_Type__c == PartnerTypeISV.Id)
                return PartnerTypeISV;
            if (getLead().Partner_Type__c == PartnerTypeReseller.Id)
                return PartnerTypeReseller;
            return null;
        }
    }
    
    public String PartnerGeneralIssuesRecordTypeId {
        set;
        get;
    }
    
    public String Language {
        set;
        get;
    }

    public String LanguageCode {
        set;
        get;
    }

    public String FederationId {
        set;
        get;
    }
    
    public String PartnerId {
        set;
        get;
    }
    
    public String PartnerName {
        set;
        get;
    }
    
    public Case OnboardingCase {
        set;
        get;
    }
    
    //
    // Helper methods
    //

    public List<SelectOption> SelectableCountryOptions {
        get {   	
        	return getSelectableCountryOptionsForLang();
        }
    }

	public List<SelectOption> getSelectableCountryOptionsForLang(){
            List<SelectOption> countryOptionList = new List<SelectOption>();
            
            Map<String, String> countryNames = new Map<String,String>();
            for(CountryTranslation__c cT: [select LanguageCode__c, CountryName__c, Country__r.Iso3166Alpha2__c 
            								from CountryTranslation__c where LanguageCode__c = :LanguageCode]){
            									
            	countryNames.put(cT.Country__r.Iso3166Alpha2__c, cT.CountryName__c);
            }

            for(Country__c country : SelectableCountryList){
            	String name = country.Name;
            	if (countryNames.get(country.Iso3166Alpha2__c) != null){
            		name = countryNames.get(country.Iso3166Alpha2__c);
            	}
                countryOptionList.add(new SelectOption(country.Abbreviation__c, name));
            }

            return countryOptionList;		
	}

    public List<SelectOption> SelectableStateOptions {
        get {
            List<SelectOption> stateOptionList = new List<SelectOption>();

            for(Country__c country : SelectableCountryList) {
                if (getLead().Country != country.Abbreviation__c)
                    continue;

                // add all of the states
                for(State__c state : country.States__r)
                    stateOptionList.add(new SelectOption(state.Abbreviation__c, state.Name));

                break;
            }

            return stateOptionList;
        }
    }

    public Integer SelectableStateOptionsSize {
        get {
            return SelectableStateOptions.size();
        }
    }
    
    private void processInitialAction() {
        if (!(handleExistingLead() 
                || handleExistingCase() 
                || handleExistingUser()
                || handleExistingContact()
                || handleLegacy())) {
            if (getExistingPartnerList().size() != 0) {
                CurrentPageName = 'JoinOrRegister';
            } else {
                CurrentPageName = 'RegisterPartner';
            }            
        }
    }
    
    public PageReference processRedirects() {
        if (CurrentPageName == 'RedirectToPRM') {
            PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/protected/federate.html');
            updateUserLocale();
            pageReference.setRedirect(true);
            return pageReference;
        } else if (CurrentPageName == 'RedirectToLegacyPC') {
            PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/partner');
            pageReference.setRedirect(true);
            return pageReference;
        } else if (CurrentPageName == 'Login') {
            PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/login.html');
            pageReference.getParameters().put('redirect', '/wapps/sfconnector/protected/partner.html');
            pageReference.setRedirect(true);
            return pageReference;
        } else if (CurrentPageName == 'BackToRedHat') {
            PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name);
            pageReference.setRedirect(true);
            return pageReference;
        }
        
        // return no page reference if the current page is not a redirect
        return null;
    }
    
    private Boolean canMigrate(String countryCode) {
        Country__c country = [
            select name
                 , abbreviation__c
                 , isMigrated__c
                 , Iso3166Alpha2__c
              from country__c
             where Iso3166Alpha2__c = :countryCode
        ];
        return country.isMigrated__c;
    }
    
    private Boolean handleExistingLead() {
        Integer existingLeads = [ 
            select count() 
              from Lead 
             where RHNLogin__c = :FederationId
               and RecordType.name = 'Partner Onboarding'
               and partner_onboarding_status__c in ('Rejected', 'Submitted', 'Pending', 'Pending Data Review')
        ];
        if (existingLeads > 0) {
            //  get the most recent onboarding lead for this federationID
            Lead lead = [
                select id
                     , partner_onboarding_status__c
                     , partner_type__c
                     , partner_type__r.Name
                     , account__c
                     , company
                     , street
                     , city
                     , state
                     , country
                     , postalCode
                     , global_region__c
                     , subregion__c
                     , RHNLogin__c
                     , Other_Countries__c
                     , Onboarding_Language_Preference__c
                  from lead
                 where RHNLogin__c = :FederationId
                   and RecordType.name = 'Partner Onboarding'
              order by createdDate desc
                 limit 1
            ];
            if (lead.partner_onboarding_status__c != 'Approved') {
                setLead(lead);
                CurrentPageName = 'DisplayLeadStatus';
                return true;
            }
        }
        return false;
    }
    
	private String getLocalePicklistName(String localeCode, String defaultName) {
		if (localeCode == null) {
			return (defaultName != null) ? defaultName : 'en';
		}
		localeCode = localeCode.toLowerCase();
		Map<String,String> listmap = new Map<String,String> {
			'en'	=> 'English',
			'zh_CN'	=> 'Chinese (simplified)',
			'zh_TW'	=> 'Chinese',
			'zh'	=> 'Chinese',
			'ja'	=> 'Japanese',
			'pt'	=> 'Portuguese',
			'ko'	=> 'Korean',
			'de'	=> 'German',
			'es'	=> 'Spanish',
			'fr'	=> 'French',
			'it'	=> 'Italian',
			'ru'	=> 'Russian'
		};
		for (String key : listmap.keySet()) {
			if (localeCode.startsWith(key)) {
				return listmap.get(key);
			}
		}
		return (defaultName != null) ? defaultName : 'en';
	}   
	
    private Boolean handleExistingCase() {
        Integer existingCases = [
            select count()
              from Case
             where redhatLoginName__c = :FederationId
               and recordType.name = 'Partner General Issues'
               and issue_type_classification__c = 'Partner Onboarding'
        ];
        if (existingCases > 0) {
            //  get the most recent partner onboarding case for this federationID
            OnboardingCase = [
               select id
                    , issue_type__c
                    , status
                    , caseNumber
                 from Case
                where redhatLoginName__c = :FederationId
                  and recordType.name = 'Partner General Issues'
                  and issue_type_classification__c = 'Partner Onboarding' 
             order by createdDate desc
                limit 1
            ];
            
            if (OnboardingCase.Status != 'Closed') {
                // setup the case so that the DisplayCaseStatus page can see it
                CurrentPageName = 'DisplayCaseStatus';
                return true;
            }
        }
        return false;
    }
    
    
    private Boolean handleExistingUser() {
        User user = getUserWithFederationId();
        if (user != null) {
            if (user.migratedOverride__c) {
                if (user.isActive) {
                    CurrentPageName = 'RedirectToPRM';
                } else {
                    CurrentPageName = 'ErrorUserIsInactive';
                }
            } else {
                if (canMigrate(user.contact.account.billingCountry)) {
                    if (user.isActive) {
                        CurrentPageName = 'RedirectToPRM';
                    } else {
                        CurrentPageName = 'ErrorUserIsInactive';
                    }                   
                } else {
                    CurrentPageName = 'RedirectToLegacyPC';
                } 
            }
            return true;
        }
        return false;
    }
    
    private void updateUserLocale(){
    	User user = getUserWithFederationId();
    	String code = getLanguageLocaleCode(user);
        if (user.LanguageLocaleKey != code) {
        	user.LanguageLocaleKey = code;
        	updateUserLocaleKey(user.Id, code); 	
        }
    }
    
    private static void updateUserLocaleKey(Id userId, String localeKey){
    	User user = new User(Id = userId);
		user.LanguageLocaleKey = localeKey;
    	update user;
    }
    
    private static boolean isValidLocale(String localeKey, List<Schema.PicklistEntry> locales) {
		for (Schema.PicklistEntry locale : locales) {
			if (locale.getValue() == localeKey) {
				return true;
			}			
		}
		return false;
    }
    
    private String getLanguageLocaleCode(User user) {
		Schema.DescribeFieldResult f = Schema.SObjectType.User.fields.LanguageLocaleKey;
		List<Schema.PicklistEntry> locales = f.getPicklistValues();
		if (isValidLocale(LanguageCode, locales)) {
			return LanguageCode;
		}
		String localeKey = LanguageCode;
        if (user.Contact.MailingCountry == null || user.Contact.MailingCountry.length() != 2) {
        	if (user.Contact.Account.BillingCountry != null && user.Contact.Account.BillingCountry.length() == 2) {
        		localeKey = LanguageCode + '_' + user.Contact.Account.BillingCountry;
        	}
        	else {
        		System.debug('** Valid country not found.  This should never happen');
        		return 'en_US';
        	}
        }
        else {
        	localeKey = LanguageCode + '_' + user.Contact.MailingCountry;
        }
		if (!isValidLocale(localeKey, locales)) {
			localeKey = 'en_US';
		}
		return localeKey;
    }

    private Boolean handleExistingContact() {
        Contact contact = getContactWithFederationId();
        if (contact != null) {
            if (canMigrate(contact.Account.BillingCountry)) {
                CurrentPageName = 'ErrorUserIsMissing';
            } else {
                CurrentPageName = 'RedirectToLegacyPC';
            }
            return true;
        }
        return false;
    }
    
    private Boolean handleLegacy() {
        if ('true'.equalsIgnoreCase(getParam(PARAM_LEGACY))) {
            if (canMigrate(getParam(PARAM_COUNTRY_CODE))) {
                CurrentPageName = 'ErrorMigrationNeeded';
            } else {
                CurrentPageName = 'RedirectToLegacyPC';
            }
            return true;
        }
        return false;
    }
    
    
    private User getUserWithFederationId() {
        User user = null;
        if (FederationId != null && [select count() from User where FederationIdentifier = :FederationId] > 0) {
            user = [
                select id
                     , Name
                     , IsActive
                     , FederationIdentifier
                     , contactId
                     , contact.accountId
                     , migratedOverride__c
                     , LanguageLocaleKey
                     , Contact.MailingCountry
                     , Contact.Account.BillingCountry
                  from User
                 where FederationIdentifier = :FederationId
                   and profile.name like '%Partner Portal%'
                   and isPortalEnabled = true
                   and ContactId != null
                 limit 1           
            ];
        }
        return user;
    }
    
    private Contact getContactWithFederationId() {
        Contact contact = null;
        if (federationId != null && [select count() from Contact where LoginName__c = :FederationId] > 0) {
            contact = [
                select id
                     , LoginName__c
                     , AccountId
                     , Name
                     , Account.BillingCountry
                  from Contact
                 where LoginName__c = :FederationId
                 limit 1
            ];
        }
        return contact;
    } 

    //
    // Page helpers
    //

    public static String getParam(String name) {
        return ApexPages.currentPage().getParameters().get(name);
    }

    public static void addMessage(String message, ApexPages.Severity severity) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }

    public static void addErrorMessage(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }

    public static void addExceptionMessage(Exception pageException) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Caught Exception: ' + pageException));
    }

    public Boolean getHasErrorMessages() {
        return ApexPages.hasMessages(ApexPages.Severity.ERROR);
    }

    //
    // Search for existing / similar partner names
    //

    public List<PartnerStatus__c> getExistingPartnerList() {
        try {
            //
            // Parse out the URL string
            //

            String partnerName = getParam(PARAM_COMPANY);
            partnerName = partnerName == null ? '' : EncodingUtil.urlDecode(partnerName, 'UTF-8');
            partnerName = partnerName.replace(' ', '%');
            partnerName = partnerName.replace('*', '%');
            partnerName = '%' + partnerName + '%';
            partnerName = partnerName.replace('%%', '%');

            if (partnerName == '%')
                return new List<PartnerStatus__c>();

            //
            // Fetch the partner statuses
            //

            return [
                select PartnerType__r.Name
                     , Partner__r.Name
                     , Partner__r.BillingStreet
                     , Partner__r.BillingCity
                     , Partner__r.BillingState
                     , Partner__r.BillingPostalCode
                     , Partner__r.BillingCountry
                     , Partner__r.PrimaryPartnerUser__c
                     , Partner__r.OwnerId
                     , Partner__r.Global_Region__c
                     , Partner__r.Subregion__c
                  from PartnerStatus__c
                 where Partner__r.Name like :partnerName
                   and ActivationStatus__c = 'Active'
              order by Partner__r.Name asc, PartnerType__r.Name asc
                 limit 1000
            ];
        } catch (System.DmlException dmlException) {
            addExceptionMessage(dmlException);
        } catch (System.QueryException queryException) {
            addExceptionMessage(queryException);
        }

        return new List<PartnerStatus__c>();
    }

    //
    // Find all relevant agreements
    //
    
    /*
    public List<Agreement__c> getRelevantAgreementList() {
        return [
            select Name
                 , IsSignatureRequired__c
                 , Version__c
                 , (select Name from Attachments)
              from Agreement__c
             where ActivationStatus__c = 'Active'
        ];
    }
    */
    
    public List<Agreement__c> getRelevantAgreementList() {
        List<Agreement__c> agreementList = new List<Agreement__c>();

        if (this.selectedCountry != null && getLead() != null && getLead().Partner_Type__c != null ) {
            system.assert(null != selectedCountry);
            system.assert(null != selectedCountry.id);
            system.assert(null != getLead().Partner_Type__c);
             
            // Here we are getting all the documents for a country.
			// We want all agreements for the Lead's preferred language and all non-specific ones             
            Set<Id> agreementIdSet = new Set<Id>();
            List<Agreement_Country__c> agreementCountryList = [
                Select Agreement__c
                     , Language__c 
                  From Agreement_Country__c
                 where Country__c = :this.selectedCountry.Id
                   and (Language__c = :Language or Language__c = null)  
                   and Agreement__r.PartnerType__c= : getLead().Partner_Type__c 
                   and Agreement__r.ActivationStatus__c='Active'
            ];
            for(Agreement_Country__c agreementCountry :agreementCountryList) {
                agreementIdSet.add(agreementCountry.Agreement__c);
            }
             
            if (agreementIdSet != null && agreementIdSet.size() > 0) {
                agreementList = [select Id,Name, IsSignatureRequired__c, Version__c, (select Name from Attachments) from Agreement__c where Id IN :agreementIdSet];
            }
             
            // Here we are getting all the global documents.
            // Prefer language-specific ones over the non-language defaults
            List<Agreement__c> globalAgreementListByLang  = [
                    select Id
                         , Language__c
                         , Name
                         , IsSignatureRequired__c
                         , Version__c
                         , (select Name from Attachments) 
                      from Agreement__c  
                     where Country_Count__c =0 
                       and (Language__c = :Language or Language__c = null)  
                       and ActivationStatus__c='Active' 
                       and PartnerType__c=: getLead().Partner_Type__c
            ];
            if (globalAgreementListByLang != null && globalAgreementListByLang.size() > 0) {
            	Integer languageCount = 0;
                for (Agreement__c globalAgreement :globalAgreementListByLang) {
                	if (globalAgreement.Language__c == Language) {
                    	agreementList.add(globalAgreement);
                    	languageCount++;
                	}
                }
                if (languageCount == 0) {
                	// found no language-specific ones, add the others
	                for (Agreement__c globalAgreement :globalAgreementListByLang) {
                    	agreementList.add(globalAgreement);
	                }
                }
            }
        }
       
        /*
        if (this.selectedCountry != null && getLead() != null && getLead().Partner_Type__c != null ) {
            agreementList = [Select Version__c, Type__c, SystemModstamp, SubRegion__c, Region__c, PartnerType__c, 
                             OwnerId, Number__c, Name, LastModifiedDate, LastModifiedById, IsSignatureRequired__c,
                             IsDeleted, Id, ExpirationDate__c, CurrencyIsoCode, CreatedDate, CreatedById, Country__c, 
                             ApprovalStatus__c, ActivationStatus__c, ActivationDate__c, 
                             (Select Agreement__c, Country__c 
                             From Agreement_Countries__r 
                             where country__c = : this.selectedCountry.Id), 
                             (select Name from Attachments)
                             From Agreement__c a 
                             where ActivationStatus__c = 'Active' AND PartnerType__c = : getLead().Partner_Type__c];
        } 
           
        
        if (this.selectedCountry != null && getLead() != null && getLead().Partner_Type__c != null ) {
             // Here we are getting all the documents for a country.
             Set<Id> agreementIdSet = new Set<Id>();
             List<Agreement_Country__c> agreementCountryList = [Select  a.Agreement__c From Agreement_Country__c a  where  a.Country__c = :this.selectedCountry.Id  and a.Agreement__r.PartnerType__c= : getLead().Partner_Type__c and  a.Agreement__r.ActivationStatus__c='Active']
             for(Agreement_Country__c agreementCountry :agreementCountryList) {
                 agreementIdSet.add(agreementCountry.Agreement__c);
             }
             if (agreementIdSet != null && agreementIdSet.size() > 0) {
                 agreementList = [select Id,Name, IsSignatureRequired__c, Version__c, (select Name from Attachments) from Agreement__c where Id =:agreementIdSet];
             }
             
             // Here we are getting all the global documents.
              List<Agreement__c> globalAgreementList  = [select Id,Name, IsSignatureRequired__c, Version__c, (select Name from Attachments) from Agreement__c  where  Country_Count__c =0 and ActivationStatus__c='Active' and PartnerType__c=: getLead().Partner_Type__c];
              if (globalAgreementList != null && globalAgreementList.size() > 0) {
                  for(Agreement__c globalAgreement :globalAgreementList) {
                      agreementList.add(globalAgreement);
                  }
              }
             
        }
        Select  a.Agreement__c From Agreement_Country__c a  where  a.Country__c ='a1LT0000000Ckay'  and a.Agreement__r.PartnerType__c='a1ST0000000Dzgi' and  a.Agreement__r.ActivationStatus__c='Active'
        String soql = 'select Id,Name, IsSignatureRequired__c, Version__c, (select Name from Attachments) from Agreement__c where ActivationStatus__c = \'Active\'';
        String whereClause ='';
        if (this.selectedCountry != null && getLead() != null && getLead().Partner_Type__c != null ) {
            Map<Id,Agreement__c> agreementMapById = new Map<Id,Agreement__c>(); 
            if (getLead() != null && getLead().Partner_Type__c != null) {
                 soql = soql + ' ' + 'AND PartnerType__c=\'' + getLead().Partner_Type__c + '\' ';
            }            
            if (this.selectedCountry != null) {
                whereClause = whereClause + 'Country__c=\''  + this.selectedCountry.Id + '\' ';
            }
            if (this.selectedCountry != null && selectedCountry.Global_Region__c != null) {
                whereClause = whereClause + ' ' + ' OR Region__c=\'' + selectedCountry.Global_Region__c + '\'';
            }
            if (this.selectedCountry != null && selectedCountry.Subregion__c != null) {
                whereClause = whereClause + ' ' + 'OR SubRegion__c=\'' + selectedCountry.Subregion__c + '\' ';
            }
            if (whereClause != null && whereClause.length() > 0) {
                whereClause = ' AND ( ' +whereClause + '  )' ;
                soql = soql + whereClause;
            }
            System.debug('SOQL---------->::' + soql);
            agreementList = Database.query(soql);
            for(Agreement__c aggreement : agreementList) {
                agreementMapById.put(aggreement.Id, aggreement);
            }
            agreementList = [select Id,Name, IsSignatureRequired__c, Version__c, (select Name from Attachments) from Agreement__c where ActivationStatus__c = 'Active' AND PartnerType__c=:getLead().Partner_Type__c AND Region__c='' AND Country__c='' AND SubRegion__c='' ];
            for(Agreement__c aggreement : agreementList) {
                agreementMapById.put(aggreement.Id, aggreement);
            }
            agreementList = agreementMapById.values();
        }
        */
        
        if (agreementList != null && agreementList.size() > 0) {
            System.debug('Agreement List---------->::' + agreementList.size());
        }
        return agreementList;
    }    
    
    //
    // Page References
    //

    public PageReference joinPartnerStart() {
        if (getParam('partner-status-id') == null) {
            addErrorMessage('Internal Error: required parameter "partner-status-id" is missing.');
        } else try {
            String partnerStatusId = getParam('partner-status-id');
            PartnerStatus__c status = [ 
               select PartnerType__r.Name
                     , Partner__r.Name
                     , Partner__r.BillingStreet
                     , Partner__r.BillingCity
                     , Partner__r.BillingState
                     , Partner__r.BillingPostalCode
                     , Partner__r.BillingCountry
                     , Partner__r.PrimaryPartnerUser__c
                     , Partner__r.OwnerId
                     , Partner__r.Global_Region__c
                     , Partner__r.Subregion__c
                  from PartnerStatus__c
                 where id = :partnerStatusId 
            ];
            
            getLead().Partner_Type__c = status.PartnerType__c;
            getLead().Account__c = status.Partner__c;
            getLead().Company = status.Partner__r.Name;
            getLead().Street = status.Partner__r.BillingStreet;
            getLead().City = status.Partner__r.BillingCity;
            getLead().State = status.Partner__r.BillingState;
            getLead().Country = status.Partner__r.BillingCountry;
            getLead().PostalCode = status.Partner__r.BillingPostalCode;
            getLead().Global_Region__c = status.Partner__r.Global_Region__c;
            getLead().Subregion__c = status.Partner__r.Subregion__c;
            //getLead().Other_Countries__c = getParam('company-other-country');
            currentPageName = 'JoinConfirm';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    public PageReference joinPartnerSubmit() {
        Savepoint pSavepoint = null;
        
        try {
            pSavepoint = Database.setSavepoint();
            insertOnboardingLead();
            currentPageName = 'JoinThankYou';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
            addErrorMessage('Lead Values: ' + getLead()); 
            Database.rollback(pSavepoint);
        }

        return null;
    }

    public PageReference joinPartnerCancel() {
        try {
            clearLead();
            currentPageName = 'JoinOrRegister'; // back to the beginning
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }
    
    //
    // Onboarding_RegisterPartner
    //

    public PageReference registerPartnerStart() {
        try {
            currentPageName = 'RegisterPartner';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    public PageReference registerPartnerSubmit() {
        if (getLead().Partner_Type__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Partner Type');
        } else if (getLead().Country == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Company Headquarters');
        } else try {
            if (canMigrate(getLead().Country)) {
                // Find and insert the global region
                for(Country__c country : SelectableCountryList) {
                    if (country.Abbreviation__c != getLead().Country)
                        continue;
    
                    getLead().Global_Region__c = country.Global_Region__c;
                    getLead().Subregion__c = country.Subregion__c;
                    getLead().Country__c = country.Id;
                    this.selectedCountry = country;
                    System.debug('this.selectedCountry.IsAgreementSignatureRequired__c :::::'+ this.selectedCountry.IsAgreementSignatureRequired__c);
                    break;
                }
                List<Agreement__c> agreementList = getRelevantAgreementList(); 
                if (agreementList != null && agreementList.size() > 0) {
                    currentPageName = 'RegisterAgreements';
                } else {
                     currentPageName = 'RegisterProfile';
                }
            } else {
                currentPageName = 'RedirectToLegacyPC';
                return processRedirects();
            }
        } catch (Exception pageException) {
            addErrorMessage('Partner Type ID: ' + getLead().Partner_Type__c);
            addErrorMessage('Caught: ' + pageException);
        }

        return null;
    }

    public PageReference registerPartnerCancel() {
        try {
            getLead().Partner_Type__c = null;
            getLead().Country = null;
            currentPageName = 'JoinOrRegister'; // back to the beginning
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    //
    // Onboarding_RegisterAgreements
    //

    public PageReference registerAgreementsSubmit() {
        System.debug('Partner Agreement Accepted--------->::'+ agreementAcceptence);
        if (getRelevantAgreementList() == null) {
            addErrorMessage('Internal Error: No agreements are available for your Partner Type and/or Country.'); 
        } else if (agreementAcceptence == null ) {
            addErrorMessage('Please accept or decline terms and conditions');
        } else {
            try {
                if (agreementAcceptence != null && agreementAcceptence.equalsIgnoreCase('Yes') ) {
                    AgreementsAccepted = true;
                }
                currentPageName = 'RegisterProfile';
            } catch (Exception pageException) {
                addExceptionMessage(pageException);
            }
        }

        return null;
    }

    public PageReference registerAgreementsCancel() {
        try {
            AgreementsAccepted = false;
            currentPageName = 'RegisterPartner';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    //
    // Onboarding_RegisterProfile
    //

    public PageReference registerProfileSubmit() {
        if (getLead().Street == '' || getLead().Street == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Company Address');
        } else if (getLead().Street.length() > 255) {
            addErrorMessage('Field value length too large: Maximum size for the Company Address field is 255 characters');
        } else if (getLead().City == '' || getLead().City == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Company City');
        } else if (getLead().City.length() > 40) {
            addErrorMessage('Field value length too large: Maximum size for the Company City field is 40 characters');
        } else if (getLead().State == null && SelectableStateOptionsSize != 0) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Company State/Province');
        } else if (getLead().PostalCode == '' || getLead().PostalCode == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Company Postal Code');
        } else if (getLead().PostalCode.length() > 20) {
            addErrorMessage('Field value length too large: Maximum size for the Company Postal Code field is 20 characters');
        } else if (getLead().Phone == '' || getLead().Phone == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Phone Number');
        } else if (getLead().Phone.length() > 40) {
            addErrorMessage('Field value length too large: Maximum size for the Phone Number field is 40 characters');
        } else if (getLead().Website == '' || getLead().Website == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Website');
        } else if (getLead().Website.length() > 255) {
            addErrorMessage('Field value length too large: Maximum size for the Website field is 255 characters');
        } else if (getLead().Industry_Focus__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Industry Focus');
        } else if (getLead().Do_they_act_in_any_government_position__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Government Position');
        } else if (getLead().Have_they_been_convicted__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Conviction Status');
        } else try {
            // Override the subregion if the selected state has a specified subregion.
            List<State__c> stateList = [
                select Subregion__c
                  from State__c
                 where Abbreviation__c = :getLead().State
                   and Subregion__c != null
            ];

            if (stateList.size() != 0)
                getLead().Subregion__c = stateList[0].Subregion__c;

            currentPageName = 'RegisterDemographics';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    public PageReference registerProfileCancel() {
        List<Agreement__c> agreementList = getRelevantAgreementList();
        if (agreementList != null && agreementList.size() > 0) {
            currentPageName = 'RegisterAgreements';
        } else {
            currentPageName = 'RegisterPartner';
        }
        
        return null;
    }

    //
    // Onboarding_RegisterDemographics
    //

    public PageReference registerDemographicsSubmit() {
        Savepoint pSavepoint = null;
        
        if (getLead().Company_Description__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Company Description');
        } else if (getLead().Company_Description__c.length() > 2000) {
            addErrorMessage('Company Description is limited to 2000 characters. Your description is ' + getLead().Company_Description__c.length() + ' characters long.');
        } else if (getLead().Number_of_Employees__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Number Of Employees');
        } else if (getLead().Total_Annual_Revenue__c == null) {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Total Annual Revenue');
        } else if (getLead().Target_Market_Size__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Target Market Size');
        } else if (getLead().Software_Focus__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Software Platform');
        } else if (getLead().Operating_System_Supported__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Operating System Expertise');
        } else if (getLead().Middleware_Supported__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Middleware Supported');
        } else if (getLead().Application_Types__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Application Types');
        } else if (getLead().Additional_Partnerships__c == '') {
            addErrorMessage(ERROR_REQUIRED_FIELD + 'Additional Partnerships');
        } else try {
            pSavepoint = Database.setSavepoint();
            insertOnboardingLead();
            currentPageName = 'RegisterThankYou';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
            Database.rollback(pSavepoint);
        }

        return null;
    }

    public PageReference registerDemographicsCancel() {
        try {
            currentPageName = 'RegisterProfile';
        } catch (Exception pageException) {
            addExceptionMessage(pageException);
        }

        return null;
    }

    public void insertOnboardingLead() {
        // Mark as submitted and set the proper profile and record type.
        getLead().Partner_Onboarding_Status__c = 'Submitted';
        getLead().Partner_Onboarding_Profile__c = 'Preapproved Portal User';
        getLead().Partner_Tier__c =	PartnerTierReady.Id;
        getLead().RecordTypeId = [
            select Id
              from RecordType
             where Name = 'Partner Onboarding'
               and SObjectType = 'Lead'
             limit 1
        ].Id;

        // If there is a referenced account AND that account has an associated
        // primary contact, then assign ownership to them
        //

        if (getLead().OwnerId == null && getLead().Account__c != null) {
            Account account = [
                 select PrimaryPartnerUser__r.IsActive
                      , OwnerId
                   from Account
                  where Id = :getLead().Account__c
                  limit 1
            ];

            if (account.PrimaryPartnerUser__r != null && account.PrimaryPartnerUser__r.IsActive == true) {
                getLead().OwnerId = account.PrimaryPartnerUser__r.Id;
            } else {
                getLead().OwnerId = account.OwnerId;
            }
        }
    
    

        //
        // If the owner id is still missing, then try to find the best owner from
        // the account team rules engine.
        //

        if (getLead().OwnerId == null) {
            String accountTeamQuery = '';
            accountTeamQuery += 'select User__c, Priority__c';
            accountTeamQuery += '  from AccountTeamRule__c';
            accountTeamQuery += ' where AccountAccessLevel__c = \'Owner\'';

            if (getLead().Global_Region__c != null) {
                accountTeamQuery += ' and (GlobalRegion__c = null or GlobalRegion__c = \'';
                accountTeamQuery += String.escapeSingleQuotes(getLead().Global_Region__c);
                accountTeamQuery += '\')';
            }

            if (getLead().Subregion__c != null) {
                accountTeamQuery += ' and (Subregion__c = null or Subregion__c = \'';
                accountTeamQuery += String.escapeSingleQuotes(getLead().Subregion__c);
                accountTeamQuery += '\')';
            }

            if (getLead().Country != null) {
                accountTeamQuery += ' and (Country__c = null or Country__r.Abbreviation__c = \'';
                accountTeamQuery += String.escapeSingleQuotes(getLead().Country);
                accountTeamQuery += '\')';
            }

            if (getLead().Partner_Tier__c != null) {
                accountTeamQuery += ' and (PartnerTier__c = null or PartnerTier__c = \'';
                accountTeamQuery += getLead().Partner_Tier__c;
                accountTeamQuery += '\')';
            }

            if (getLead().Partner_Type__c != null) {
                accountTeamQuery += ' and (PartnerType__c = null or PartnerType__c = \'';
                accountTeamQuery += getLead().Partner_Type__c;
                accountTeamQuery += '\')';
            }

            // Finish and execute
            accountTeamQuery += ' order by Priority__c desc limit 1';

            List<Sobject> objectList = Database.query(accountTeamQuery);

            if (objectList.size() != 0)
                getLead().OwnerId = ((AccountTeamRule__c) objectList[0]).User__c;
        }
        if (AgreementsAccepted == true) {
            getLead().Agree_To_Partner_TC__c = true;
        } else {
            getLead().Agree_To_Partner_TC__c = false;
        }

        // Push it
        insert getLead();

        // Build and submit the partner agreement relationship, but only when this is a 
        // new registration process.
        if (getLead().Account__c == null) {
            List<PartnerAgreement__c> partnerAgreementList = new List<PartnerAgreement__c>();
            List<Agreement__c> agreementList = getRelevantAgreementList();
            if (agreementList != null && agreementList.size() > 0) {
            for(Agreement__c agreement : getRelevantAgreementList()) {
                PartnerAgreement__c partnerAgreement = new PartnerAgreement__c();
                partnerAgreement.Agreement__c = agreement.Id;
                partnerAgreement.PartnerLead__c = getLead().Id;
                partnerAgreement.ActivationDate__c = Date.today();
    
                if (AgreementsAccepted == true)
                    partnerAgreement.PartnerApprovalStatus__c = 'Approved';
                else 
                    partnerAgreement.PartnerApprovalStatus__c = 'Declined';
    
                partnerAgreementList.add(partnerAgreement);
            }
                 insert partnerAgreementList;
            } else {
                getLead().No_Agreements__c = true;
                update getLead();
            }
        
        }

        
        // Submit
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Submitting request for approval.');
        approvalRequest.setObjectId(getLead().Id);

        // Ensure the approval was submitted properly
        Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
        system.assert(approvalResult.isSuccess(), approvalResult.getErrors());
        
        
        //OnboardingExecuteConversion.submitLeadForApprovalFuture(getLead().Id);
    }

    public PageReference activateUserSubmit() {
        User user = getUserWithFederationId();
        OnboardingCase = createPartnerOnboardingCase(FederationId
                , 'User Activation Request'
                , user.Name + ' has requested to be activated as a partner user'
                , 'This request might require clearing out the Federation ID field of an existing User record.'
                , user.contactId
                , user.contact.AccountId);
        CurrentPageName = 'DisplayCaseStatus';
        return null;
    }

    public PageReference activateUserCancel() {
        CurrentPageName = 'BackToRedHat';
        return processRedirects();
    }

    public PageReference convertContactSubmit() {
        // this might end up being code that actually converts the user
        // if that's so, where do we send them?  I guess to be federated
        // for now, create a case and submit it
        
        Contact contact = getContactWithFederationId();
        OnboardingCase = createPartnerOnboardingCase(FederationId
                , 'User Creation Request'
                , contact.Name + ' has requested to be converted to a partner user'
                , 'To convert the contact to a partner user, click the Contact Name associated with this case. ' +
                  'Then, click the "Enable Partner User" button on the Contact.'
                , contact.Id
                , contact.AccountId);
        CurrentPageName = 'DisplayCaseStatus';
        return null;
    }

    public PageReference convertContactCancel() {
        CurrentPageName = 'BackToRedHat';
        return processRedirects();
    }

    public PageReference migratePartnerSubmit() {
        OnboardingCase = createPartnerOnboardingCase(FederationId
                , 'Migration Request'
                , PartnerName + ' has requested to be migrated'
                , System.label.Red_Hat_Domain_Name + '/wapps/sfconnector/protected/admin/migration/step2?txtIds=' + PartnerId
                , null
                , null);
        CurrentPageName = 'DisplayCaseStatus';
        return null;
    }
    
    public PageReference migratePartnerCancel() {
        // send the user on to old partner center
        CurrentPageName = 'BackToRedHat';
        return processRedirects();
    }
    
    private Case createPartnerOnboardingCase(String federationId, String issueType, String subject, String description,
                String contactId, String accountId) {
        Case c = new Case();
        c.RecordTypeId = PartnerGeneralIssuesRecordTypeId;
        c.Issue_Type_Classification__c = 'Partner Onboarding';
        c.Issue_Type__c = issueType;
        c.Subject = subject;
        c.Description = description;
        c.Origin = 'Portal';
        c.RedHatLoginName__c = federationId;
        c.Status = 'New';
        c.Priority = 'Medium';
        
        if (accountId != null) {
            c.AccountId = accountId;
        }
        if (contactId != null) {
            c.ContactId = contactId;
        }
        
        Database.Dmloptions dmo = new Database.Dmloptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        c.setOptions(dmo);        

	    try {        
        insert c;
	    }
        catch (System.DmlException ex) {
			System.debug('----------------------->> RecordTypeId=' + c.RecordTypeId);
			System.debug('----------------------->> ContactId=' + c.ContactId);
			throw ex;
        }
        return [
            select Issue_Type__c
                 , CaseNumber
                 , Status
              from Case
             where ID = :c.ID              
        ];
    }

    //
    // Multi-select picklist conversion
    //

    public List<String> getSplitPicklistField(String values) {
        return values == null ? new List<String>() : values.split(';');
    }

    public List<SelectOption> getSelectOptions(List<Schema.PicklistEntry> picklistEntryList) {
        List<SelectOption> selectOptionList = new List<SelectOption>();

        for(Schema.PicklistEntry p : picklistEntryList)
            selectOptionList.add(new SelectOption(p.Value, p.Label));

        return selectOptionList;
    }

    public void setSelectOptionsValuesToField(String fieldName, List<String> valuesList) {
        String field = '';
    
        for(String value : valuesList) {
            if (field != '')
                field += ';';
            field += value;
        }
        
        getLead().put(fieldName, field);
    }

    // Industry focus

    public List<SelectOption> getIndustryFocusOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Industry_Focus__c'));
    }

    public List<String> getIndustryFocus() {
        return getSplitPicklistField(getLead().Industry_Focus__c);
    }

    public void setIndustryFocus(List<String> valuesList) {
        setSelectOptionsValuesToField('Industry_Focus__c', valuesList);
    }

    // Additional Countries Of Operations

    public List<SelectOption> getAdditionalCountriesOfOperationsOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Additional_Countries_Of_Operations__c'));
    }

    public List<String> getAdditionalCountriesOfOperations() {
        return getSplitPicklistField(getLead().Additional_Countries_Of_Operations__c);
    }

    public void setAdditionalCountriesOfOperations(List<String> valuesList) {
        setSelectOptionsValuesToField('Additional_Countries_Of_Operations__c', valuesList);
    }

    // Target Market Size

    public List<SelectOption> getTargetMarketSizeOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Target_Market_Size__c'));
    }

    public List<String> getTargetMarketSize() {
        return getSplitPicklistField(getLead().Target_Market_Size__c);
    }

    public void setTargetMarketSize(List<String> valuesList) {
        setSelectOptionsValuesToField('Target_Market_Size__c', valuesList);
    }
    
    // Software Focus

    public List<SelectOption> getSoftwareFocusOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Software_Focus__c'));
    }

    public List<String> getSoftwareFocus() {
        return getSplitPicklistField(getLead().Software_Focus__c);
    }

    public void setSoftwareFocus(List<String> valuesList) {
        setSelectOptionsValuesToField('Software_Focus__c', valuesList);
    }

    // Operating System Supported

    public List<SelectOption> getOperatingSystemSupportedOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Operating_System_Supported__c'));
    }

    public List<String> getOperatingSystemSupported() {
        return getSplitPicklistField(getLead().Operating_System_Supported__c);
    }

    public void setOperatingSystemSupported(List<String> valuesList) {
        setSelectOptionsValuesToField('Operating_System_Supported__c', valuesList);
    }

    // Middleware Supported

    public List<SelectOption> getMiddlewareSupportedOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Middleware_Supported__c'));
    }

    public List<String> getMiddlewareSupported() {
        return getSplitPicklistField(getLead().Middleware_Supported__c);
    }

    public void setMiddlewareSupported(List<String> valuesList) {
        setSelectOptionsValuesToField('Middleware_Supported__c', valuesList);
    }

    // Application Types

    public List<SelectOption> getApplicationTypesOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Application_Types__c'));
    }

    public List<String> getApplicationTypes() {
        return getSplitPicklistField(getLead().Application_Types__c);
    }

    public void setApplicationTypes(List<String> valuesList) {
        setSelectOptionsValuesToField('Application_Types__c', valuesList);
    }

    // Additional Partnerships

    public List<SelectOption> getAdditionalPartnershipsOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Additional_Partnerships__c'));
    }

    public List<String> getAdditionalPartnerships() {
        return getSplitPicklistField(getLead().Additional_Partnerships__c);
    }

    public void setAdditionalPartnerships(List<String> valuesList) {
        setSelectOptionsValuesToField('Additional_Partnerships__c', valuesList);
    }
    
/*  Moved to OnboardingController.cls
    public static testMethod void test() {
        User user  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
        //List<Classification__c> partnerTypeClassifications = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c From Classification__c c  where c.HierarchyRootName__c='Partner Type'and ReferenceKey__c=  'RESELLER' limit 1];
        List<Country__c> countryList = [select name, abbreviation__c, isMigrated__c, Iso3166Alpha2__c  from country__c where isMigrated__c = false limit 1];
        //List<Classification__c> isvPartnerClassification = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c From Classification__c c  where c.HierarchyRootName__c='Partner Type'and ReferenceKey__c=  'ISV' limit 1];
        Profile p = [select id,name from profile where name like '%NA Partner Portal%' limit 1];
        RecordType recordType = [Select r.Name, r.Id From RecordType r where r.Name='Partner Onboarding']; 
        RecordType caseRecordType = [Select r.Name, r.Id From RecordType r where r.name='Partner General Issues' limit 1];
        //List<Classification__c> partnerTierClassification = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c From Classification__c c  where c.HierarchyRootName__c='Partner Tier'and ReferenceKey__c=  'READY' limit 1];
        
        Classification__c partnerTypeClassification = new Classification__c();
        partnerTypeClassification.Name = 'Partner Type';
        insert partnerTypeClassification;
        
        Classification__c resellerClassification = new Classification__c();
        resellerClassification.Name = 'Reseller';
        resellerClassification.Parent__c = partnerTypeClassification.Id;
        insert resellerClassification;
        
        List<Classification__c> partnerTypeClassifications = new List<Classification__c>();
        
        partnerTypeClassifications.add(resellerClassification);
        
        Classification__c isvClassification = new Classification__c();
        isvClassification.Name = 'ISV';
        isvClassification.Parent__c = partnerTypeClassification.Id;
        insert isvClassification;
        
        List<Classification__c> isvPartnerClassification = new List<Classification__c>();
        isvPartnerClassification.add(isvClassification);
        
        
        Classification__c partnerTierClassificationObj = new Classification__c();
        partnerTierClassificationObj.Name = 'Partner Tier';
        insert partnerTierClassificationObj; 
        
        Classification__c readyClassification = new Classification__c();
        readyClassification.Name = 'Ready';
        readyClassification.Parent__c = partnerTierClassificationObj.Id;
        insert readyClassification;
        
        List<Classification__c> partnerTierClassification = new List<Classification__c>();
        partnerTierClassification.add(readyClassification);
        System.debug('Classification__c---------->'+[select Name from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV' limit 1]);
        
        
       
        Account account = new Account();
        account.Name ='Test Acc';
        account.Global_Region__c ='APAC';
        account.OwnerId = user.Id;
        account.BillingCountry ='US';
        insert account;
        
//        PartnerStatus__c partnerStatus = new PartnerStatus__c();
//        partnerStatus.ActivationDate__c = Date.today();
//        partnerStatus.ExpirationDate__c = Date.today().addYears(1);
//        partnerStatus.ApprovalStatus__c = 'Approved';
//        partnerStatus.Partner__c = account.Id;
//        partnerStatus.PartnerTier__c = partnerTierClassification.get(0).Id;
//        partnerStatus.PartnerType__c = partnerTypeClassifications.get(0).Id;
//        insert partnerStatus;
        
        test.starttest();
        
        Contact contact = new Contact();
        contact.FirstName = 'Test FS';
        contact.LastName ='Test LS';
        contact.Email = 'test@apprivo.com';
        contact.AccountId = account.Id;
        contact.LoginName__c ='123456789iuyt';
        insert contact;
        User user1  = new User(username = 'test1@redhat.com',LastName='lname',CommunityNickname='Test1', email = 'test1@redhat.com', alias = 'test1', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'RH',
        profileid = p.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US', FederationIdentifier='123456789iuyt',ContactId =contact.Id);
        insert user1;  
          
        Lead leadInfo = new Lead();
        leadInfo.Partner_Type__c =partnerTypeClassifications.get(0).Id;
        leadInfo.Account__c = account.Id;
        leadInfo.Company ='Apprivo';
        leadInfo.Street = '417 Montgomery';
        leadInfo.City = 'San Francisco';
        leadInfo.State ='CA';
        leadInfo.Country = 'US';
        leadInfo.PostalCode ='94104';
        leadInfo.Global_Region__c ='NA';
        leadInfo.SubRegion__c ='Southeast';
        leadInfo.RHNLogin__c='123456789iuyt';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Other_Countries__c ='Camaroon';
        leadInfo.Industry_Focus__c ='Aerospace';
        leadInfo.Do_they_act_in_any_government_position__c='Yes';
        leadInfo.Have_they_been_convicted__c='No';
        leadInfo.RecordTypeId = recordType.Id;
        
       
        ApexPages.currentPage().getParameters().put('rhn-first-name', 'Test FS');
        ApexPages.currentPage().getParameters().put('rhn-last-name', 'Test LS');
        ApexPages.currentPage().getParameters().put('rhn-company-name', 'Apprivo');
        ApexPages.currentPage().getParameters().put('rhn-email', 'test@apprivo.com');
        ApexPages.currentPage().getParameters().put('federation-id', '123456789iuyt');
        ApexPages.currentPage().getParameters().put('partner-id', '123456789');
        ApexPages.currentPage().getParameters().put('partner-name', 'Apprivo');
        ApexPages.currentPage().getParameters().put('legacy', 'Y');
        
        
        OnboardingController controller = new OnboardingController(new ApexPages.StandardController(leadInfo));
        Classification__c classification =controller.SelectedPartnerType;
        //System.assert(classification.Name == 'Reseller', 'Partner classifications are not correct');
        controller.getLead().Partner_Type__c = isvPartnerClassification.get(0).Id;
        classification =controller.SelectedPartnerType;
        //System.assert(classification.Name == 'ISV', 'Partner classifications are not correct');
        System.debug('Get Page Name--------->'+ controller.CurrentPageName);
        controller.setLead(leadInfo);
        //System.assert(controller.getLead() != null);
        
        System.debug('controller.getIndustryFocusOptions()=========>'+ controller.getIndustryFocusOptions());
        System.assert(controller.getIndustryFocusOptions()!= null, 'Industry focus options are empty');
        System.assert(controller.getIndustryFocus()!= null, 'Industry focus is empty');
        System.assert(controller.getAdditionalCountriesOfOperationsOptions()!= null, 'Additional countries are empty');
        System.assert(controller.getAdditionalCountriesOfOperations()!= null, 'Additional countries are empty');
        System.assert(controller.getTargetMarketSizeOptions()!= null, 'Target market options are empty');
        System.assert(controller.getTargetMarketSize() != null, 'Target market size is empty');
        System.assert(controller.getSoftwareFocusOptions() != null, 'Software Focus options are empty');
        System.assert(controller.getSoftwareFocus() != null, 'Software Focus is empty');
        System.assert(controller.getOperatingSystemSupportedOptions() != null, 'Operating System Supported Options ae empty');
        System.assert(controller.getOperatingSystemSupported() != null,'Operating Systems supported is empty');
        System.assert(controller.getMiddlewareSupportedOptions()!= null,'Middleware Supported options is empty');
        System.assert(controller.getMiddlewareSupported()!= null,'Middleware supported is empty');
        System.assert(controller.getApplicationTypesOptions() != null,'Application type options are empty');
        System.assert(controller.getApplicationTypes() != null ,'Application types are empty');
        System.assert(controller.getAdditionalPartnershipsOptions() != null,'Additional Partnership options are empty');
        System.assert(controller.getAdditionalPartnerships() != null,'Partnerships are empty');
        System.debug('Countries --------->'+ controller.SelectableCountryList);
        System.assert(controller.SelectableCountryList != null,'Countries are not loaded');
        System.assert(controller.SelectableCountryOptions != null,'Selectable countries are not loaded.');
        System.assert(controller.SelectableStateOptions != null,'Selectable states are not loaded.');
        
        controller.setMiddlewareSupported(controller.getMiddlewareSupported());
        controller.setApplicationTypes(controller.getApplicationTypes());
        controller.setTargetMarketSize(controller.getTargetMarketSize());
        controller.setAdditionalPartnerships(controller.getAdditionalPartnerships());
        controller.setAdditionalCountriesOfOperations(controller.getAdditionalCountriesOfOperations());
        controller.setOperatingSystemSupported(controller.getOperatingSystemSupported());
        controller.setSoftwareFocus(controller.getSoftwareFocus());
//        List<PartnerStatus__c> existingPartnerList = controller.getExistingPartnerList();
        controller.registerPartnerStart();
        //System.assert(controller.CurrentPageName == 'RegisterPartner','Invalid launch Page');

        // case 1 :: Partner Type and country are not specified.
        controller.getLead().Partner_Type__c = null;
        controller.getLead().Country__c = null;
        controller.registerPartnerSubmit();
        //System.assert(controller.CurrentPageName =='RegisterPartner', 'Partner onboarding cannot continue without specifying country and partner Type');
        // case 2 :: Partner Type and country are  specified ,country specified is not migrated.
        if (countryList != null) {
            controller.getLead().Country = countryList.get(0).Iso3166Alpha2__c;
            controller.getLead().Partner_Type__c =partnerTypeClassifications.get(0).Id;
            controller.registerPartnerSubmit();
            //System.assert(controller.CurrentPageName =='RedirectToLegacyPC', 'Partner should be redirected to legacy page');
        }
        // case 3 :: Partner Type and country are  specified ,should go to agreements page.
        controller.getLead().Country = 'US';
        controller.getLead().Partner_Type__c =partnerTypeClassifications.get(0).Id;
        List<Agreement__c> agreementList =controller.getRelevantAgreementList();
        controller.registerPartnerSubmit();
        //System.assert((agreementList != null && controller.CurrentPageName =='RegisterAgreements'), 'Partner should go to the agreements page');

//        controller.getLead().Country = 'US';
//        controller.registerPartnerSubmit();
//        System.assert((agreementList == null && controller.CurrentPageName !='RegisterProfile'), 'Partner should go to the profie page');
        

        controller.agreementAcceptence = null;
        controller.registerAgreementsSubmit();
        //System.assert(controller.CurrentPageName =='RegisterAgreements', 'Partner should be redirected to agreements page to accept the agreement page.');
        
        controller.agreementAcceptence = 'Yes';
        controller.registerAgreementsSubmit();
        
        //System.assert(controller.CurrentPageName =='RegisterProfile', 'Partner should be redirected to agreements page to accept the agreement page.');
        
        controller.getLead().Street='';
        controller.getLead().City ='';
        controller.getLead().State ='';
        controller.getLead().Phone ='';
        controller.getLead().PostalCode ='';
        controller.getLead().Website ='';
        controller.getLead().Industry_Focus__c ='';
        controller.getLead().Do_they_act_in_any_government_position__c = null;
        controller.getLead().Have_they_been_convicted__c = null;
        controller.registerProfileSubmit();

        //System.assert(controller.getHasErrorMessages(), 'Profile registration is not populated properly');
        
        controller.getLead().Street = '417 Montgomery';
        controller.getLead().City = 'San Francisco';
        controller.getLead().State ='CA';
        controller.getLead().PostalCode ='94104';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Industry_Focus__c ='Aerospace';
        controller.getLead().Do_they_act_in_any_government_position__c = 'Test';
        controller.getLead().Have_they_been_convicted__c = 'Test';
        controller.registerProfileSubmit();
        System.debug('Has Error Messages------>'+ controller.getHasErrorMessages());
        //System.assert(controller.getLead().Subregion__c != null, 'Sub region is not loaded onto lead on profile registration');
        
        controller.getLead().Company_Description__c ='';
        controller.getLead().Number_of_Employees__c ='';
        controller.getLead().Total_Annual_Revenue__c ='';
        controller.getLead().Target_Market_Size__c ='';
        controller.getLead().Software_Focus__c ='';
        controller.getLead().Operating_System_Supported__c ='';
        controller.getLead().Middleware_Supported__c ='';
        controller.getLead().Application_Types__c ='';
        controller.getLead().Additional_Partnerships__c ='';
        controller.registerDemographicsSubmit();
        //System.assert(controller.getHasErrorMessages(), 'Profile demo graphics is not populated properly');
        
        
        controller.getLead().Company_Description__c ='Test';
        controller.getLead().Number_of_Employees__c ='2';
        controller.getLead().Total_Annual_Revenue__c ='100';
        controller.getLead().Target_Market_Size__c ='100';
        controller.getLead().Software_Focus__c ='Test';
        controller.getLead().Operating_System_Supported__c ='Test';
        controller.getLead().Middleware_Supported__c ='Linux';
        controller.getLead().Application_Types__c ='SFW';
        controller.getLead().Additional_Partnerships__c ='Test';
        controller.registerDemographicsSubmit();
        System.debug('Page URL------>'+ controller.CurrentPageName);
        //System.assert(controller.CurrentPageName =='RegisterThankYou', 'Profile registration is completed . Not redirected to Thankyou page');
        
        controller.AgreementsAccepted = true;
        controller.joinPartnerStart();
        //System.assert(controller.getHasErrorMessages(), 'Partner details are not provided');
        //String partnerStatusId = partnerStatus.id;
        String partnerStatusId = null;
        ApexPages.currentPage().getParameters().put('partner-status-id', partnerStatusId);
        controller.joinPartnerStart();
        //System.assert(controller.CurrentPageName =='JoinConfirm', 'Partner details are provided, but not redirected to confirmation page');
        controller.joinPartnerCancel();
        
        
        leadInfo = new Lead();
        leadInfo.Partner_Type__c =partnerTypeClassifications.get(0).Id;
        leadInfo.Account__c = account.Id;
        leadInfo.Company ='Apprivo';
        leadInfo.Street = '417 Montgomery';
        leadInfo.City = 'San Francisco';
        leadInfo.State ='CA';
        leadInfo.Country = 'US';
        leadInfo.PostalCode ='94104';
        leadInfo.Global_Region__c ='NA';
        leadInfo.SubRegion__c ='Southeast';
        leadInfo.RHNLogin__c='123456789iuyt';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Other_Countries__c ='Camaroon';
        leadInfo.Industry_Focus__c ='Aerospace';
        leadInfo.Do_they_act_in_any_government_position__c='Yes';
        leadInfo.Have_they_been_convicted__c='No';
        leadInfo.RecordTypeId = recordType.Id;
        controller.setLead(leadInfo);
        controller.joinPartnerSubmit();
        //System.assert(controller.CurrentPageName !='JoinThankYou', 'Partner is not redirected to confirmation page');
        controller.migratePartnerSubmit();
        //System.assert(controller.CurrentPageName.equals('DisplayCaseStatus'));
       
        controller.activateUserSubmit();
        //System.assert(controller.CurrentPageName.equals('DisplayCaseStatus'));
        controller.convertContactSubmit();
        leadInfo.Company ='Apprivo';
        controller.registerProfileCancel();
        System.debug('Current Page Name------>'+ controller.CurrentPageName);
        //System.assert((controller.getRelevantAgreementList() != null && controller.CurrentPageName =='RegisterAgreements'),'Partner profile cancel redirect failure');
        
        controller.registerPartnerCancel();

//        System.assert(controller.CurrentPageName.equals('JoinOrRegister'),'Partner register cancel failed');
//        System.assert(controller.getLead().Partner_Type__c == null,'Partner registration cancel did not clear the values');
//        System.assert(controller.getLead().Country == null,'Partner registration cancel did not clear the values');

        
        controller.registerDemographicsCancel();
        //System.assert(controller.CurrentPageName.equals('RegisterProfile'),'Partner Demographics cancel failed');
        controller.registerAgreementsCancel();
        //System.assert(controller.CurrentPageName.equals('RegisterPartner'),'Partner registration cancel failed');
        controller.joinPartnerCancel();
        //System.assert(controller.CurrentPageName.equals('JoinOrRegister'),'Partner register cancel failed');
        controller.activateUserCancel();
        //System.assert(controller.CurrentPageName.equals('BackToRedHat'),'User activate failed');
        controller.convertContactCancel();
        //System.assert(controller.CurrentPageName.equals('BackToRedHat'),'User activate failed');
        controller.migratePartnerCancel();
       // System.assert(controller.CurrentPageName.equals('RedirectToLegacyPC'),'User migrate cancel failed');
        //controller.insertOnboardingLead();
        
        ApexPages.currentPage().getParameters().remove('federation-id');
        controller = null;
        controller = new OnboardingController(new ApexPages.StandardController(leadInfo));
        System.debug('Current Page Name--------->'+ controller.CurrentPageName);
        //System.assert(controller.CurrentPageName == 'Login','Invalid launch Page');
        controller.processRedirects();
        controller.migratePartnerCancel();
        controller = null;
        
        Account account1 = new Account();
        account1.Name ='Test Acc';
        account1.Global_Region__c ='APAC';
        account1.OwnerId = user.Id;
        account1.BillingCountry ='US';
        insert account1;

//        PartnerStatus__c partnerStatus = new PartnerStatus__c();
//        partnerStatus.Partner__c= account1.Id;
//        partnerStatus.PartnerTier__c = partnerTierClassification.get(0).Id;
//        partnerStatus.PartnerType__c =isvPartnerClassification.get(0).Id;
//        partnerStatus.ActivationDate__c = System.today();
//		  partnerStatus.ActivationStatus__c='Active';
//        insert partnerStatus;

        Contact contact1 = new Contact();
        contact1.FirstName = 'Test FS';
        contact1.LastName ='Test LS';
        contact1.Email = 'test@apprivo.com';
        contact1.AccountId = account.Id;
        contact1.LoginName__c ='esrao78965432';
        insert contact1;
        User user2  = new User(username = 'test2@redhat.com',LastName='lname',CommunityNickname='Test2', email = 'test2@redhat.com', alias = 'test2', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'Apprivo',
        profileid = p.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US', FederationIdentifier='esrao78965432',ContactId =contact1.Id,migratedOverride__c=true);
        insert user2;    
        Lead leadInfo1 = new Lead();
        leadInfo1.LastName ='LS1';
        leadInfo1.Partner_Type__c =isvPartnerClassification.get(0).Id;
        leadInfo1.Account__c = account.Id;
        leadInfo1.Company ='Apprivo';
        leadInfo1.Street = '417 Montgomery';
        leadInfo1.City = 'San Francisco';
        leadInfo1.State ='CA';
        leadInfo1.Country = 'US';
        leadInfo1.PostalCode ='94104';
        leadInfo1.Global_Region__c ='NA';
        leadInfo1.SubRegion__c ='Southeast';
        leadInfo1.RHNLogin__c='esrao78965432';
        leadInfo1.Phone ='4156325768';
        leadInfo1.Website ='www.apprivo.com';
        leadInfo1.Other_Countries__c ='Camaroon';
        leadInfo1.Industry_Focus__c ='Aerospace';
        leadInfo1.Do_they_act_in_any_government_position__c='Yes';
        leadInfo1.Have_they_been_convicted__c='No';
        leadInfo1.RecordTypeId = recordType.Id;
        leadInfo1.partner_onboarding_status__c ='New';
        insert leadInfo1;
        
       
        Case c = new Case();
        c.RecordTypeId = caseRecordType.Id;
        c.Issue_Type_Classification__c = 'Partner Onboarding';
        c.redhatLoginName__c ='esrao78965432';
        c.Status = 'New';
        insert c;   
        ApexPages.currentPage().getParameters().clear();    
        ApexPages.currentPage().getParameters().put('rhn-first-name', 'Test FS');
        ApexPages.currentPage().getParameters().put('rhn-last-name', 'Test LS');
        ApexPages.currentPage().getParameters().put('rhn-email', 'test@apprivo.com');
        ApexPages.currentPage().getParameters().put('federation-id', 'esrao78965432');
        ApexPages.currentPage().getParameters().put('partner-id', '123456789');
        ApexPages.currentPage().getParameters().put('partner-name', 'Apprivo');
        ApexPages.currentPage().getParameters().put('legacy', 'Y');
       
        controller = new OnboardingController(new ApexPages.StandardController(leadInfo1));
        System.debug('controller.CurrentPageName' + controller.CurrentPageName);
        controller.setLead(leadInfo1);

        
        ApexPages.currentPage().getParameters().clear();    
        ApexPages.currentPage().getParameters().put('rhn-first-name', 'Test FS');
        ApexPages.currentPage().getParameters().put('rhn-last-name', 'Test LS');
        ApexPages.currentPage().getParameters().put('rhn-email', 'test@apprivo.com');
        ApexPages.currentPage().getParameters().put('federation-id', 'esrao78965432');
        ApexPages.currentPage().getParameters().put('partner-id', '123456789');
        ApexPages.currentPage().getParameters().put('partner-name', 'Apprivo');
        ApexPages.currentPage().getParameters().put('company-name','Apprivo');
        ApexPages.currentPage().getParameters().put('legacy', 'Y');
        Lead leadInfo2 = new Lead();
        leadInfo2.LastName ='LS1';
        leadInfo2.Partner_Type__c =isvPartnerClassification.get(0).Id;
        leadInfo2.Account__c = account.Id;
        leadInfo2.Company ='Apprivo';
        leadInfo2.Street = '417 Montgomery';
        leadInfo2.City = 'San Francisco';
        leadInfo2.State ='CA';
        leadInfo2.Country = 'US';
        leadInfo2.PostalCode ='94104';
        leadInfo2.Global_Region__c ='NA';
        leadInfo2.SubRegion__c ='Southeast';
        leadInfo2.RHNLogin__c='esrao78965432';
        leadInfo2.Phone ='4156325768';
        leadInfo2.Website ='www.apprivo.com';
        leadInfo2.Other_Countries__c ='Camaroon';
        leadInfo2.Industry_Focus__c ='Aerospace';
        leadInfo2.Do_they_act_in_any_government_position__c='Yes';
        leadInfo2.Have_they_been_convicted__c='No';
        leadInfo2.RecordTypeId = recordType.Id;
        leadInfo2.partner_onboarding_status__c ='New';
        controller = null;
        controller = new OnboardingController(new ApexPages.StandardController(leadInfo2));
        controller.setLead(leadInfo2);
        controller.joinPartnerStart();
        System.debug('controller.CurrentPageName' + controller.CurrentPageName);
        controller.getLead().Company ='Apprivo';
        controller.insertOnboardingLead();

        test.stopTest();
     }
*/

}