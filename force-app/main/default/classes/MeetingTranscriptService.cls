public class MeetingTranscriptService {

    @AuraEnabled
    public static String sendBot2Meeting(String meetingUrl, String botName) {
        String result = '';
        try {
            String recallSendBotEndPoint = 'https://api.recall.ai/api/v1/bot';
            String token = '1b787731b2bef62dd5335b2148df0dd5bb03c412';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(recallSendBotEndPoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Token ' + token);
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, String> transcriptOption = new Map<String, String>();
            // transcriptOption.put('provider', 'assembly_ai');
            transcriptOption.put('provider', 'meeting_captions');
            
            Map<String, Object> reqBodyMap = new Map<String, Object>();
            reqBodyMap.put('meeting_url', meetingUrl);
            reqBodyMap.put('bot_name', botName);
            reqBodyMap.put('transcription_options', transcriptOption);
            
            String requestBody = JSON.serialize(reqBodyMap);
            req.setBody(requestBody);
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Handle the response
            
            if (res.getStatusCode() >= 200) {
                // File uploaded successfully
                System.debug('********* sendBot2Meeting successfully. Response: ' + res.getBody());
                result = res.getBody();
            } else {
                // Error handling
                System.debug('********* Error sendBot2Meeting. Status code: ' + res.getStatusCode());
                System.debug('********* Error message: ' + res.getBody());
                result = 'error';
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static String retrieveBot(String botID) {
        String result = '';
        try {
            String recallPoint = 'https://api.recall.ai/api/v1/bot/' + botID + '/';
            String token = '1b787731b2bef62dd5335b2148df0dd5bb03c412';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(recallPoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Token ' + token);
            req.setHeader('Content-Type', 'application/json');
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                // File uploaded successfully
                System.debug('********* Response: ' + res.getBody());
                result = res.getBody();
            } else {
                // Error handling
                System.debug('********* Error Status code: ' + res.getStatusCode());
                System.debug('********* Error message: ' + res.getBody());
                result = 'error';
            }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
        

    }

    @AuraEnabled
    public static String retrieveBotTranscriptByMeetingId(String meetingId) {
        List<Meeting__c> meetings = [SELECT Id, Bot_Id__c
                                    FROM Meeting__c 
                                    WHERE ID =: meetingID];

         Meeting__c m = meetings.get(0);
        String resBody;
        try{
            resBody = MeetingTranscriptService.retrieveBotTranscript(m.Bot_Id__c);
            m.Transcript_RTF__c = resBody;
            update m;
        }catch(Exception e) {
            System.debug('********* sendBot error message: ' + e);
        }

        return resBody;
    }

    @future (callout=true)
    public static void saveTranscript(String botID, String meetingId, String fileName) {
        String transcript = MeetingTranscriptService.retrieveBotTranscript(botID);
        MeetingTranscriptGetter.attachFileToMeeting(meetingId, fileName, transcript);
    }

    // @AuraEnabled()
    // public static String retrieveBotDetails(String botID) {
    //     String result = '';
    //     try {
    //         String recallEndPoint = 'https://api.recall.ai/api/v1/bot/' + botID + '/';
    //         String token = '1b787731b2bef62dd5335b2148df0dd5bb03c412';
            
    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint(recallEndPoint);
    //         req.setMethod('GET');
    //         req.setHeader('Authorization', 'Token ' + token);
    //         req.setHeader('Content-Type', 'application/json');
            
    //         // Send the request
    //         Http http = new Http();
    //         HttpResponse res = http.send(req);
            
    //         if (res.getStatusCode() == 200) {

    //             System.debug('********* Response: ' + res.getBody());
    //             result = res.getBody();
    //             RecallRetrieveBotResponse rbr = (RecallRetrieveBotResponse) JSON.deserialize(result, RecallRetrieveBotResponse.class);
    //         } else {
    //             // Error handling
    //             System.debug('********* Error Status code: ' + res.getStatusCode());
    //             System.debug('********* Error message: ' + res.getBody());
    //             result = 'error';
    //         }
    //     }catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }

    //     return result;
        

    // }

    @AuraEnabled()
    public static String retrieveBotTranscript(String botID) {
        String result = '';
        try {
            String recallEndPoint = 'https://api.recall.ai/api/v1/bot/' + botID + '/transcript';
            String token = '1b787731b2bef62dd5335b2148df0dd5bb03c412';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(recallEndPoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Token ' + token);
            req.setHeader('Content-Type', 'application/json');
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                // File uploaded successfully
                System.debug('********* Response: ' + res.getBody());
                result = res.getBody();
            } else {
                // Error handling
                System.debug('********* Error Status code: ' + res.getStatusCode());
                System.debug('********* Error message: ' + res.getBody());
                result = 'error';
            }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
        

    }

    @InvocableMethod(label='Send a bot' description='Send a bot to a meeting' category='Meeting')
    public static void sendBot(List<ID> meetingID) {
        List<Meeting__c> meetings = [SELECT Id, Bot_Name__c, Meeting_URL__c 
                                    FROM Meeting__c 
                                    WHERE ID IN: meetingID];
        

        Meeting__c m = meetings.get(0);
        String resBody;
        try{
            String botName = (!String.isBlank(m.Bot_Name__c)) ? m.Bot_Name__c : 'FieldKo Assistant';
            resBody = MeetingTranscriptService.sendBot2Meeting(m.Meeting_URL__c, m.Bot_Name__c);

            if(resBody != 'error'){
                SendBotRes sbr = (SendBotRes)JSON.deserializeStrict(resBody, SendBotRes.class);
                String botID = sbr.id;
                System.debug('********* botID: ' + botID);
                m.Bot_ID__c = botID;
                update m;
            }
            
        }catch(Exception e) {
            System.debug('********* sendBot error message: ' + e);
        }
    }

    public static Meeting__c createMeetingByRecallInfo(String botID){
        List<Meeting__c> meetings = [SELECT Id, Kinetics__Recall_Meeting_ID__c FROM Meeting__c WHERE Bot_ID__c =: botId];
        Meeting__c m;
        if(!meetings.isEmpty()){
            m = meetings.get(0);
        }else{
            m = new Meeting__c();
            m.Bot_ID__c = botId;
        }
        String retriveBotResString = MeetingTranscriptService.retrieveBot(botId);
        String meetingAuthToken;
        if(retriveBotResString != 'error'){
            RecallRetrieveBotResponse rbr = (RecallRetrieveBotResponse) JSON.deserializeStrict(retriveBotResString, RecallRetrieveBotResponse.class);
            // m.Bot_Recording__c = rbr.video_url;
            System.debug('********* rbr.calendar_meetings: ' + rbr.calendar_meetings);
            if(rbr.calendar_meetings != null){
                for(RecallRetrieveBotResponse.Calendar_meetings meeting: rbr.calendar_meetings){
                    m.Recall_Meeting_ID__c = meeting.id;
                    String calendarUserEmail = meeting.calendar_user.external_id;

                    if(calendarUserEmail != null){
                        User calendarUser = [SELECT ID, Recall_Google_Calendar_Auth_Token__c 
                                                    FROM User 
                                                    WHERE Email =: calendarUserEmail];
                        if(calendarUser != null){
                            meetingAuthToken = calendarUser.Recall_Google_Calendar_Auth_Token__c;
                        }
                    }
                }
            }

            m.Meeting_URL__c    = (String.isBlank(m.Meeting_URL__c))  ? rbr.meeting_url.meeting_id : m.Meeting_URL__c;
            m.Meeting_Platform__c = rbr.meeting_url.platform;

            if(rbr.meeting_metadata != null ){
                if(rbr.meeting_metadata.title != null){
                    m.Subject__c = rbr.meeting_metadata.title;
                }    
            }

            if(rbr.status_changes != null){
                for(RecallRetrieveBotResponse.Status_changes sc: rbr.status_changes){
                    if(sc.code == 'joining_call'){
                        Datetime startTime = MeetingServiceUtil.parseDateTime(sc.created_at);
                        m.Meeting_Date_Time__c = startTime;
                    }else if(sc.code == 'call_ended'){
                        Datetime endtime = MeetingServiceUtil.parseDateTime(sc.created_at);
                        m.Meeting_End_Time__c = endtime;
                    }
                }
            }
    
            String participantList = '';
            for(RecallRetrieveBotResponse.Meeting_participants p: rbr.meeting_participants){
                participantList = (participantList == '') ? p.name : ( participantList + '\n' + p.name) ; 
            }
            m.Meeting_Participants__c = participantList;

        }
        m.Bot_Status__c = 'done';
        
        try{
            
            if(m.Recall_Meeting_ID__c != null && meetingAuthToken != null){
                String getMeetingResString = RecallAIService.retrieveCalendarMeeting(m.Recall_Meeting_ID__c, meetingAuthToken);
                if(getMeetingResString != 'error'){
                    RecallGetMeetingRes getMeetingRes = (RecallGetMeetingRes) JSON.deserializeStrict(getMeetingResString, RecallGetMeetingRes.class);
                    m.Subject__c = getMeetingRes.title;
                }
                
            }
        }catch(Exception ex){
            // do nothing for now
        }
        
        upsert m;

        RecallAIService.startBotMediaAnalysisJob(botId);
        return m;
    }
 }