@IsTest
private class AcctPicklistSyncTest {
	public static testmethod void test() {
		RecordType rt = [select Id from RecordType where SobjectType = 'Account' and Name='NA Partner']; 

		for (Account acct : [
			select	Id
			  from  Account
			 where  RecordTypeId = :rt.Id
			  limit 3
		]) {
			AcctPicklistSync__c item = new AcctPicklistSync__c(AccountId__c=acct.Id);
			insert item;
		}
			
	}
}