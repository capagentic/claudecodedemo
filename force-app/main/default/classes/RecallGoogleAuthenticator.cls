public class RecallGoogleAuthenticator {

    @AuraEnabled(cacheable=true)  
    public static String getUserEmail() {  
        List<User> users = [SELECT Email, Kinetics__Recall_Google_Calendar_Auth_Token__c FROM User WHERE Id =: UserInfo.getUserId()];
        User user;
        if(!users.isEmpty()){
            user = users.get(0);
        }
        Map<String, String> resMap = new Map<String, String>();
        resMap.put('userEmail', user.Email);
        
        String authToken; 
        if(!String.isBlank(user.Kinetics__Recall_Google_Calendar_Auth_Token__c)){
            String listOfCalendarResult = getListCalendarMeetings(user.Kinetics__Recall_Google_Calendar_Auth_Token__c);
            if(listOfCalendarResult == 'success'){
                authToken = user.Kinetics__Recall_Google_Calendar_Auth_Token__c;
            }else{
                
            }
        }
        resMap.put('recallCalendarAuthToken', authToken);
    
        return JSON.serialize(resMap);
    }

    @Future(callout=true)
    public static void getRecallCalendarAuthTokenFuture(String userId, String userEmail) {
        system.debug('getRecallCalendarAuthTokenFuture userId=' + userId);
        system.debug('getRecallCalendarAuthTokenFuture userEmail=' + userEmail);
        getRecallCalendarAuthToken(userEmail, userId);
    }

    @AuraEnabled
    public static String getRecallCalendarAuthToken(String userEmail, String userId) {
        String result = '';
        try {
            String recallEndPoint = 'https://api.recall.ai/api/v1/calendar/authenticate/';
            String token = '1b787731b2bef62dd5335b2148df0dd5bb03c412';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(recallEndPoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Token ' + token);
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, String> transcriptOption = new Map<String, String>();
            // transcriptOption.put('provider', 'assembly_ai');
            transcriptOption.put('provider', 'meeting_captions');
            
            Map<String, Object> reqBodyMap = new Map<String, Object>();
            reqBodyMap.put('user_id', userEmail);
            
            String requestBody = JSON.serialize(reqBodyMap);
            req.setBody(requestBody);
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Handle the response
            
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 400) {
                String resBody = res.getBody();
                Map<String, String> rMap = (Map<String, String>) JSON.deserialize(resBody, Map<String, String>.class);
                result = generateAuthUrl(rMap.get('token'));

                User u = new User();
                u.Id = (userId != null) ? userId : Userinfo.getUserId();
                u.Kinetics__Recall_Google_Calendar_Auth_Token__c = rMap.get('token');
                update u;
            } else {
                // Error handling
                System.debug('********* Error getRecallCalendarAuthToken. Status code: ' + res.getStatusCode());
                System.debug('********* Error getRecallCalendarAuthToken: ' + res.getBody());
                result = 'error';
            }
        } catch (Exception e) {
            System.debug('Error cause:' + e.getCause());
            System.debug('Error message:' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }

        
        return result;
    }

    private static String generateAuthUrl(String authToken){
        // String url = 'https://accounts.google.com/o/oauth2/v2/auth?scope=https://www.googleapis.com/auth/calendar.events.readonly https://www.googleapis.com/auth/userinfo.email&access_type=offline&prompt=consent&include_granted_scopes=true&response_type=code&redirect_uri=https://api.recall.ai/api/v1/calendar/google_oauth_callback/&client_id=647925677113-rp7msh737k8apclj9evokh87isc7bmie.apps.googleusercontent.com&state={"recall_calendar_auth_token":"{{recall_calendar_auth_token}}","google_oauth_redirect_url":"https://api.recall.ai/api/v1/calendar/google_oauth_callback/"}';
        String url = 'https://accounts.google.com/o/oauth2/v2/auth?scope=https://www.googleapis.com/auth/calendar.events.readonly https://www.googleapis.com/auth/userinfo.email&access_type=offline&prompt=consent&include_granted_scopes=true&response_type=code&redirect_uri=https://api.recall.ai/api/v1/calendar/google_oauth_callback/&client_id=647925677113-rp7msh737k8apclj9evokh87isc7bmie.apps.googleusercontent.com&state={"recall_calendar_auth_token":"{{recall_calendar_auth_token}}","google_oauth_redirect_url":"https://api.recall.ai/api/v1/calendar/google_oauth_callback/","success_url":"https://kinetics-dev-ed.lightning.force.com/lightning/n/Kinetics__Meeting_Bot_Management"}';
        // String url = 'https://accounts.google.com/o/oauth2/v2/auth?scope=https://www.googleapis.com/auth/calendar.events.readonly https://www.googleapis.com/auth/userinfo.email&access_type=offline&prompt=consent&include_granted_scopes=true&response_type=code&redirect_uri=https://kinetics-dev-ed.lightning.force.com/lightning/n/Kinetics__Meeting_Bot_Management&client_id=647925677113-rp7msh737k8apclj9evokh87isc7bmie.apps.googleusercontent.com&state={"recall_calendar_auth_token":"{{recall_calendar_auth_token}}","google_oauth_redirect_url":"https://kinetics-dev-ed.lightning.force.com/lightning/n/Kinetics__Meeting_Bot_Management"}';
        
        url = url.replace('{{recall_calendar_auth_token}}', authToken);
        return url;
    }

    @AuraEnabled
    public static String updateRecordingPreferences(String recallCalendarAuthToken) {
        String result = '';
        String botName = 'FieldKo Recorder';
        try {
            String recallEndPoint = 'https://api.recall.ai/api/v1/calendar/user/';
            String token = '1b787731b2bef62dd5335b2148df0dd5bb03c412';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(recallEndPoint);
            req.setMethod('PUT');
            req.setHeader('Authorization', 'Token ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-recallcalendarauthtoken', recallCalendarAuthToken);
            
            Map<String, Object> preferenceMap = new Map<String, Object>();
            preferenceMap.put('record_non_host', true);
            preferenceMap.put('record_recurring', true);
            preferenceMap.put('record_external', true);
            preferenceMap.put('record_internal', true);
            preferenceMap.put('record_confirmed', true);
            preferenceMap.put('record_only_host', true);
            preferenceMap.put('bot_name', botName);

            Map<String, Map<String, Object>> reqBodyMap = new Map<String, Map<String, Object>>();
            reqBodyMap.put('preferences', preferenceMap);
            
            String requestBody = JSON.serialize(reqBodyMap);
            req.setBody(requestBody);
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('********* Status code: ' + res.getStatusCode());
            // Handle the response
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 400) {
                System.debug('********* Success Response: ' + res.getBody());
            } else {
                System.debug('********* Error body:' + res.getBody());
                result = 'error';
               
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return result;
    }

    @AuraEnabled
    public static String deleteCalendarUser(String recallCalendarAuthToken) {
        String result = '';
        try {
            String recallEndPoint = 'https://api.recall.ai/api/v1/calendar/user/';
            String token = '1b787731b2bef62dd5335b2148df0dd5bb03c412';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(recallEndPoint);
            req.setMethod('DELETE');
            req.setHeader('Authorization', 'Token ' + token);
            req.setHeader('x-recallcalendarauthtoken', recallCalendarAuthToken);
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Handle the response
            
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 400) {
                System.debug('********* Success Response: ' + res.getBody());
                result = 'success';

                User u = new User();
                u.Id = Userinfo.getUserId();
                u.Kinetics__Recall_Google_Calendar_Auth_Token__c = '';
                update u;
            } else {
                System.debug('********* Error Status code: ' + res.getStatusCode());
                System.debug('********* Error body:' + res.getBody());
                result = 'error';
               
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return result;
    }

    @AuraEnabled
    public static String getListCalendarMeetings(String recallCalendarAuthToken) {
        String result = '';
        try {
            String recallEndPoint = 'https://api.recall.ai/api/v1/calendar/meetings/';
            // String token = '1b787731b2bef62dd5335b2148df0dd5bb03c412';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(recallEndPoint);
            req.setMethod('GET');
            // req.setHeader('Authorization', 'Token ' + token);
            req.setHeader('x-recallcalendarauthtoken', recallCalendarAuthToken);
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Handle the response
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 400) {
                System.debug('********* Success Response: ' + res.getBody());
                result = 'success';
            } else {
                System.debug('********* Error Status code: ' + res.getStatusCode());
                System.debug('********* Error body:' + res.getBody());
                result = 'error';
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return result;
    }
}