trigger FundRequest_OracleProjectCodeRequired on SFDC_MDF__c (after update) {

 for  ( SFDC_MDF__c FundRequest : Trigger.new )

    if  (FundRequest.Oracle_Project_Code__c == null && (FundRequest.Approval_Status__c == 'Pending Final Approval' || FundRequest.Approval_Status__c == 'Approved') )
    

                    {   
                        FundRequest.addError('A fund Request could not be approved without a Oracle Project Code');
                    }



}