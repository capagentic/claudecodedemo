public class MeetingIntelligenceService {
    
    

    public static void getSummary(String botId) {

        try {
            List<Meeting__c> meetings = [SELECT Id FROM Meeting__c WHERE Bot_ID__c =: botId];
            Meeting__c m;
            if(!meetings.isEmpty()){
                m = meetings.get(0);
            }
            
            String resString = RecallAIService.getIntelligenceResult(botId) ;
            if(resString != 'error'){
                resString = resString.replaceAll('assembly_ai.', '');
                RecallGetIntelligenceResultRes resObj = (RecallGetIntelligenceResultRes) JSON.deserializeStrict(resString, RecallGetIntelligenceResultRes.class);
                String summary = resObj.summary;
                m.Meeting_Summary__c = summary;
                update m;
            }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

    }
}