/**
 * An apex page controller that exposes the company name and id
 **/
public class TrainingTabController {
    public String AccountId {get; set;}   
    public String CompanyName {get; set;}   
       
    public TrainingTabController() {
        User u = [select Id, Contact.AccountId from User where Id = :UserInfo.getUserId()];
        if (u.Contact.AccountId != null){
	        Account a = [select Id, Name from Account where Id = :u.Contact.AccountId];
    	    AccountId = u.Contact.AccountId;
        	CompanyName = a.Name;
        }
    }
  
    public PageReference training() {
      return null;
    }
    
     public static testMethod void TrainingTabController() {
      // Instantiate a new controller with all parameters in the page
      TrainingTabController controller = new TrainingTabController();
      controller.AccountId = 'xxx';       
      controller.CompanyName = 'Red Hat';       
    
      System.assertEquals(controller.training(),null); 
    }
}