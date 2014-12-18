trigger Account_IsPartnerValidation on Account (before update, before insert) {
         
      for ( Account newAccounts : Trigger.new )
      
      
      
            {
            
            if ( newAccounts.MigrationSource__c == null || newAccounts.MigrationSource__c != 'Onboarded' )
            {
         

            // Check to see if the status of the old and new account values are the same.
                    if  (newAccounts.IsPartner && newAccounts.PartnerStatuses__c.contains('Unaffiliated') )
                    {   
                        newAccounts.addError('An unaffiliated partner cannot be enabled in the Partner Center Portal');
                    }
           }         
                   
      }
}