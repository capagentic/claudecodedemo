
public class RecallAuthTokenRenewalScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        // Your logic here
        System.debug('Scheduled job executed at: ' + DateTime.now());

        List<User> users = [SELECT Email, ID, Kinetics__Recall_Google_Calendar_Auth_Token__c 
                        FROM User 
                        WHERE Kinetics__Recall_Google_Calendar_Auth_Token__c != null];

        for(User u: users){
            String email = u.Email;
            String userId = u.Id;
            RecallGoogleAuthenticator.getRecallCalendarAuthTokenFuture(userId, email);
        }
    }
}