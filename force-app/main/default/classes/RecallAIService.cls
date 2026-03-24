public class RecallAIService {

    @future(callout=true)
    public static void startBotMediaAnalysisJob(String botId) {
        String result = '';
        try {
            String recallSendBotEndPoint = 'https://api.recall.ai/api/v2beta/bot/' + botId + '/analyze';
            String token = '1b787731b2bef62dd5335b2148df0dd5bb03c412';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(recallSendBotEndPoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Token ' + token);
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> transcription = new Map<String, Object>();
            transcription.put('language', 'en_au');
            transcription.put('language_code', 'en_au');
            transcription.put('speaker_labels', true);
            transcription.put('summarization', true);
            transcription.put('summary_type', 'paragraph');
            transcription.put('summary_model', 'informative');
            
            Map<String, Object> reqBodyMap = new Map<String, Object>();
            reqBodyMap.put('assemblyai_async_transcription', transcription);
            
            String requestBody = JSON.serialize(reqBodyMap);
            req.setBody(requestBody);
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('********* Status code: ' + res.getStatusCode());
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 400) {
                System.debug('********* startSummaryJob successfully. Response: ' + res.getBody());
                result = res.getBody();
            } else {
                System.debug('********* startSummaryJob Error message: ' + res.getBody());
                result = 'error';
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        // return result;
    }

    public static String getIntelligenceResult(String botId) {
        String result = '';
        try {
            String recallPoint = 'https://api.recall.ai/api/v1/bot/' + botId + '/intelligence/';
            String token = '1b787731b2bef62dd5335b2148df0dd5bb03c412';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(recallPoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Token ' + token);
            req.setHeader('Content-Type', 'application/json');
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('********* Status code: ' + res.getStatusCode());
            if (res.getStatusCode() == 200) {
                System.debug('********* Response: ' + res.getBody());
                result = res.getBody();
            } else {
                System.debug('********* Error message: ' + res.getBody());
                result = 'error';
            }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    public static String retrieveCalendarMeeting(String meetingRecallId, String authToken) {
        String result = '';
        try {
            String recallPoint = 'https://api.recall.ai/api/v1/calendar/meetings/' + meetingRecallId + '/';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(recallPoint);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-recallcalendarauthtoken', authToken);
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('********* Status code: ' + res.getStatusCode());
            if (res.getStatusCode() == 200) {
                System.debug('********* Response: ' + res.getBody());
                result = res.getBody();
            } else {
                System.debug('********* Error message: ' + res.getBody());
                result = 'error';
            }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    
}