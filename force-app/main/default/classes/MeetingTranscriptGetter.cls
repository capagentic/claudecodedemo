public without sharing class  MeetingTranscriptGetter {
    public class Request {
        @InvocableVariable(label='meetingID' required=true)
        public Id meetingId;

        @InvocableVariable(label='botID' required=true)
        public String botId;
    }

    public class Response {
        @InvocableVariable
        public String responseMessage;
    }

    // @InvocableMethod(label='Get meeting transcript from Recall' description='Get meeting transcript from Recall' category='Meeting')
    // public static List<Response> getTranscript(List<Request> requests) {
    //     String botId;
    //     String meetingId;
    //     if(!requests.isEmpty()){
    //         Request req = requests.get(0);
    //         botId = req.botId;
    //         meetingId = req.meetingId;
    //     }
        
        
        

    //     List<Response> responses = new List<Response>();
    //     Response res = new Response();
    //     try {
    //         String transcript = MeetingTranscriptService.retrieveBotTranscript(botID);
    //         attachFileToMeeting(meetingId, 'meeting transcript', transcript);

    //         res.responseMessage = 'Meeting transcript saved successfully'; 
    //         responses.add(res);
    //     } catch (DmlException e) {
            
    //         res.responseMessage = 'Error saving transcript: ' + e.getMessage(); 
    //         responses.add(res);
    //     }
    //     return responses;
    // }

    public static void attachFileToMeeting(String meetingId, String fileName, String fileContent) {
        system.debug('attachFileToMeeting');
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName; // Filename needs extension, e.g., 'file.txt'
        cv.VersionData = Blob.valueOf(fileContent); // Convert string to blob
        cv.IsMajorVersion = true;
        insert cv;

        // Salesforce automatically creates a ContentDocument record after inserting ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Step 2: Link the file to the Meeting__c record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = meetingId; // ID of the Meeting__c record
        cdl.ShareType = 'V'; // Visibility: V = Viewer, C = Collaborator, I = Inferred
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
}