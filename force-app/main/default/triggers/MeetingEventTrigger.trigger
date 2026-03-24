trigger MeetingEventTrigger on Meeting_Event__e (after insert) {

    system.debug('***** MeetingEventTrigger starts');
    
    String botId;
    String meetingId;
    String platform;
    for(Meeting_Event__e eventRecord : Trigger.new) {
        botId = eventRecord.Bot_Id__c;
        meetingId = eventRecord.Meeting_Id__c;
        platform = eventRecord.Platform__c;
    }

    system.debug('***** MeetingEventTrigger botId=' + botId);
    system.debug('***** MeetingEventTrigger meetingId=' + meetingId);
    system.debug('***** MeetingEventTrigger platform=' + platform);

    if(platform == 'Google'){
        MeetingTranscriptService.saveTranscript(botID, meetingId, 'meeting transcript.txt'); 
        // String transcript = MeetingTranscriptService.retrieveBotTranscript(botID);
        // MeetingTranscriptGetter.attachFileToMeeting(meetingId, 'meeting transcript', transcript);
        system.debug('***** MeetingEventTrigger completes');
    }


}
