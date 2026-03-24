@RestResource(urlMapping='/recallservice/*')
global without sharing class RecallAIWebservice {


    @HttpPost
    global static String doPost() {
        RestRequest req = RestContext.request;
        system.debug('****** req= ' + req);
        system.debug('****** req.requestBody.toString()= ' + req.requestBody.toString());

        RecallBotChangeResponse res = (RecallBotChangeResponse)JSON.deserialize(req.requestBody.toString(), RecallBotChangeResponse.class);

        system.debug('****** res= ' + res);

        String event = res.event;
        if(event == 'bot.status_change'){
            
            String status = res.data.status.code;
            system.debug('****** status=' + status);
            if(status == 'done'){
                String botId = res.data.bot_id;
                system.debug('****** botId=' + botId);
                Meeting__c m = MeetingTranscriptService.createMeetingByRecallInfo(botId);
            }

            if(status == 'analysis_done'){
                String botId = res.data.bot_id;
                system.debug('****** botId=' + botId);
                MeetingIntelligenceService.getSummary(botId);
            }
        }


        return 'Success';
    }

    

}