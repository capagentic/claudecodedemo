/**
 * Author: Shankar Dupade
 * Date: 02-02-2024
 * Purpose: helper class to invoke chat gpt assistant api
 */
public with sharing class GPTCallTranscriptionHelper {
    
    @future(callout=true)
    public static void create_update_Assistance(List<String> assistantIdList) {
        try {
            List<Kinetics__Assistant__c> assistantList = [SELECT Id, Kinetics__ChatGPT_Id__c, Kinetics__Code_Interpreter__c, Kinetics__File_Ids__c, Kinetics__Instructions__c, Kinetics__Model__c, Name, Kinetics__Retrieval__c FROM Kinetics__Assistant__c WHERE Id In :assistantIdList LIMIT 1];
            if(assistantList.size() == 0) {
                // 'Record not found';
            }
            Map<String, String> assistantValues = new Map<String, String>();
            for(Kinetics__Assistant__c asst: assistantList) {
                if(String.isNotBlank(asst.Kinetics__ChatGPT_Id__c)) {
                    assistantValues.put('assistantID', asst.Kinetics__ChatGPT_Id__c);
                }
                assistantValues.put('instructions', asst.Kinetics__Instructions__c);
                assistantValues.put('name', asst.Name);
                assistantValues.put('model', asst.Kinetics__Model__c);
                assistantValues.put('code_interpreter', String.valueOf(asst.Kinetics__Code_Interpreter__c));
                assistantValues.put('retrieval', String.valueOf(asst.Kinetics__Retrieval__c));

                String assistantCreateResponse = AssistantAPIController.create_update_Assistance(assistantValues);
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(assistantCreateResponse);
                if(responseMap.containsKey('object') && String.valueOf(responseMap.get('object')) == 'assistant') {
                    asst.Kinetics__ChatGPT_Id__c = String.valueOf(responseMap.get('id'));
                }
            }
            update assistantList;
        }catch(Exception exc) {
            throw GlobalUtility.auraHandledMessageException(exc.getMessage());
        }
    }
    
    @future(callout=true)
    public static void delete_Assistance(List<String> recordGPTIdsToPush) {
        try {
            if(recordGPTIdsToPush.size() == 0) {
                // 'Record not found';
            }
            Map<String, String> assistantValues = new Map<String, String>();
            for(String recordGPTId: recordGPTIdsToPush) {
                if(String.isNotBlank(recordGPTId)) {
                    assistantValues.put('assistantID', recordGPTId);
                }
                
                String assistantCreateResponse = AssistantAPIController.delete_Assistance(assistantValues);
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(assistantCreateResponse);
                if(responseMap.containsKey('object') 
                    && String.valueOf(responseMap.get('object')) == 'assistant.deleted'
                    && Boolean.valueOf(responseMap.get('deleted')) == true) {
                    //all good to proceed with deletion
                } else {
                    throw GlobalUtility.auraHandledMessageException('Could not delete Assistant from platform.');
                }
            }
        }catch(Exception exc) {
            throw GlobalUtility.auraHandledMessageException(exc.getMessage());
        }
    }

    public static String create_update_Thread(String assistantID, String threadId, String meetingId){
        
       
        List<Kinetics__Meeting__c> meetingList = [select Id, Name, Kinetics__GPT_Thread_ID__c, Kinetics__Transcript_RTF__c,
        Kinetics__Prompt_Template__r.Name, Kinetics__Prompt_Template__r.Kinetics__Assistant__r.Name from Kinetics__Meeting__c where Id = :meetingId];

        if(meetingList.size() == 0) {
            return null;
        }

        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('threadId', meetingList[0].Kinetics__GPT_Thread_ID__c);
        inputMap.put('callTranscript', meetingList[0].Kinetics__Transcript_RTF__c);
        inputMap.put('sfRecordId', meetingList[0].Id);
        inputMap.put('sfRecordName', meetingList[0].Name);
        inputMap.put('promptTemplateName', meetingList[0].Kinetics__Prompt_Template__r.Name);
        inputMap.put('assistantName', meetingList[0].Kinetics__Prompt_Template__r.Kinetics__Assistant__r.Name);
        
        
        String calloutResponse = AssistantAPIController.create_update_Thread(inputMap);

        system.debug('res:' + calloutResponse);
        // Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(calloutResponse);
        // if(responseMap.containsKey('object') && String.valueOf(responseMap.get('object')) == 'thread') {
        //     return String.valueOf(responseMap.get('id'));
        // }
        return calloutResponse;
    }
    
    public static void pushCallTranscription(String meetingId) {
        Map<String, String> requestBodyMap = new Map<String, String>();
        
        List<Kinetics__Meeting__c> meetingList = [SELECT Id, Name, Kinetics__GPT_Thread_ID__c, Kinetics__Transcript_RTF__c, Kinetics__Files_Ids__c
                                                FROM Kinetics__Meeting__c 
                                                WHERE Id = :meetingId];

        if(meetingList.size() == 0) {
            throw GlobalUtility.auraHandledMessageException('error: Meeting record not found');
        }
        if(String.isBlank(meetingList[0].Kinetics__GPT_Thread_ID__c)) {
            throw GlobalUtility.auraHandledMessageException('error: thread ID is required');
        }

        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('threadId', meetingList[0].Kinetics__GPT_Thread_ID__c);
        if(String.isNotBlank(meetingList[0].Kinetics__Transcript_RTF__c)) {
            inputMap.put('callTranscript', meetingList[0].Kinetics__Transcript_RTF__c);
        }
        inputMap.put('sfFileIds', meetingList[0].Kinetics__Files_Ids__c);

        AssistantAPIController.pushCallTranscription(inputMap);
    }

    // public static String create_update_Message(String assistantID, String threadId, String meetingId, String kineticFormId) {

    //     if(String.isBlank(threadId)) {
    //         throw GlobalUtility.auraHandledMessageException('error: thread ID is required');
    //     }
    //     try{
    //         String surveyQuestionWrapper = SeqRendererController.getSequenceById(kineticFormId);
    //         List<Kinetics__Kinetic_Form__c> formList = [SELECT Id, Kinetics__Spreadsheet_Template__c, 
    //                                                     Kinetics__Spreadsheet_Template__r.Name,
    //                                                     Kinetics__Spreadsheet_Template__r.Kinetics__Object_API_Name__c,
    //                                                     Kinetics__Spreadsheet_Template__r.Kinetics__Row_Metadata__c
    //                                                     FROM Kinetics__Kinetic_Form__c
    //                                                     WHERE Id =:kineticFormId];
    //         String contentString = 'create a table by following this format without deviation such that the result is in JSON format as follows,';
    //         //String contentString = 'create a JSON table of next steps related to closing the sale with columns for: task, task owner, description of task, importance of task';
    //         //String contentString = 'create a JSON table of risks related to closing the sale for the sales call transcript with columns for: risk, rationale for risk and strategy to address risk';
    //         if(formList.size() == 0 || String.isBlank(formList[0].Kinetics__Spreadsheet_Template__c)
    //             || kineticFormId != 'a005g00003NSX2PAAX'){ 
    //                 contentString = contentString + ' {"response": { ';
    //                 contentString = contentString + ' "assessments": [{"question":"xxxxx", "response":"xxxxx", "assessment of response":"xxxxx [either "Negative", "Moderate" or "Positive"]", "rationale for assessment of response":"xxxxx", "relevant source statement(s)":"xxxxx"}]';
    //                 // contentString = contentString + ' ,"opportunities": [{"Opportunity":"xxxxx", "Reason for Opportunity":"xxxxx", "Strategy to maximize the Opportunity":"xxxxx", "Relevance to Customer":"xxxxx [either "Low", "Medium" or "High"]"}]';
    //                 // contentString = contentString + ' ,"risks": [{"Risk":"xxxxx", "Reason for Risk":"xxxxx", "Strategy to address Risk":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';
    //                 // contentString = contentString + ' ,"feedback": [{"Feedback":"xxxxx", "Owner":"xxxxx", "Reason for Feedback":"xxxxx", "Strategy to address Feedback":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';
    //                 contentString = contentString + ' ,"next_steps": [{"Task_Subject":"xxxxx", "Owner":"xxxxx", "Reason for Importance":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';
    //                 contentString = contentString + ' }}';
    //         } else {
    //             contentString = contentString + ' {"response": [{';
    //             List<Object> rowMetadataListRaw = (List<Object>)JSON.deserializeUntyped(formList[0].Kinetics__Spreadsheet_Template__r.Kinetics__Row_Metadata__c);
    //             for(Object rowMetadataObj: rowMetadataListRaw) {
    //                  Map<String,Object> rowMetadata = (Map<String,Object>)rowMetadataObj;
    //                 if(rowMetadata.containsKey('columnWrapperList')) {
    //                     List<Object> columnWrapperListObj = (List<Object> )rowMetadata.get('columnWrapperList');
    //                     for(Object columnWrapperObj: columnWrapperListObj){
    //                         Map<String, Object> columnWrapper = (Map<String, Object>)columnWrapperObj;
    //                         InspSpreadsheetController.columnConf cconf = new InspSpreadsheetController.columnConf();
    //                         cconf.label = columnWrapper.containsKey('label')? (String)columnWrapper.get('label') : '';
    //                         cconf.fieldName = columnWrapper.containsKey('fieldName')? (String)columnWrapper.get('fieldName') : '';
    //                         contentString = contentString + '"'+cconf.label+'":"xxxxx", ';
    //                         // cconf.wrapText = columnWrapper.containsKey('wrapText')? (Boolean)columnWrapper.get('wrapText') : false;
    //                         // cconf.editable = columnWrapper.containsKey('editable')? (Boolean)columnWrapper.get('editable') : false;
    //                         //cconf.type = columnWrapper.containsKey('type')? (((String)columnWrapper.get('type')).toLowerCase()) : 'text';
    //                         //columnConfList.add(cconf);
    //                     }
    //                     break;
    //                 }
    //             }
    //             contentString = contentString + '}]';
    //         }
           
    //         contentString = contentString + ' Do not include any explanations, only provide a RFC8259 compliant JSON response. ';
            
    //         Map<String, Object> seqResponseObj = (Map<String, Object>) JSON.deserializeUntyped(surveyQuestionWrapper);
    //         List<Object> sqList = (List<Object>)seqResponseObj.get('responseDetails');

            
    //         List<Map<String, String>> questionwrapperList = new List<Map<String, String>>();
            
    //         for(Object seqObj: sqList) {
    //             Map<String, Object> seqq = (Map<String, Object>) seqObj;
    //             Map<String, String> questionWrapp = new Map<String, String>();
                
    //             questionWrapp.put('questionText', String.valueOf(seqq.get('questionDetails')));
    //             questionWrapp.put('index', String.valueOf(seqq.get('index')));
    //             questionWrapp.put('qInstructions', String.valueOf(seqq.get('qInstructions')));

    //             questionwrapperList.add(questionWrapp);
    //         }

    //         Map<String, Object> requestBodyMap = new Map<String, Object>();

    //         requestBodyMap.put('role', 'user');
    //         contentString = contentString + JSON.serialize(questionwrapperList);

    //         requestBodyMap.put('content',contentString);

    //         String requestPayload = JSON.serialize(requestBodyMap);
        
    //         return AssistantAPIController.create_update_Message(requestPayload, threadId);
    //     } catch(Exception exc) {
    //         throw GlobalUtility.auraHandledMessageException(exc.getMessage());
    //     }
    // }

    public static String create_update_Message(String assistantID, String threadId, String meetingId, String kineticFormId, String assessmentType) {

        if(String.isBlank(threadId)) {
            throw GlobalUtility.auraHandledMessageException('error: thread ID is required');
        }
        try{
            String surveyQuestionWrapper = SeqRendererController.getSequenceById(kineticFormId);
            List<Kinetics__Kinetic_Form__c> formList = [SELECT Id, Kinetics__Spreadsheet_Template__c, 
                                                        Kinetics__Spreadsheet_Template__r.Name,
                                                        Kinetics__Spreadsheet_Template__r.Kinetics__Object_API_Name__c,
                                                        Kinetics__Spreadsheet_Template__r.Kinetics__Row_Metadata__c
                                                        FROM Kinetics__Kinetic_Form__c
                                                        WHERE Id =:kineticFormId];
            // String contentString = 'create a JSON table of next steps ("next_steps"), risks ("risks"), opportunities ("opportunities") if the customer proceeds with the proposed solution related to closing the sales call transcript with columns as outlined here, ';
            // contentString = contentString + ' by following this format without deviation such that the result is in JSON format as follows,';
            // contentString = contentString + ' "assessments": [{"question":"xxxxx", "response":"xxxxx", "assessment of response":"xxxxx [either "Negative", "Moderate" or "Positive"]", "rationale for assessment of response":"xxxxx", "relevant source statement(s)":"xxxxx"}]';
            // contentString = contentString + ' "opportunities": [{"Opportunity":"xxxxx", "Reason for Opportunity":"xxxxx", "Strategy to maximize the Opportunity":"xxxxx", "Relevance to Customer":"xxxxx [either "Low", "Medium" or "High"]"}]';
            // contentString = contentString + ' "risks": [{"Risk":"xxxxx", "Reason for Risk":"xxxxx", "Strategy to address Risk":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';
            // contentString = contentString + ' "next_steps": [{"Task_Subject":"xxxxx", "Owner":"xxxxx", "Reason for Importance":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';

            String contentString_assessment = 'create a JSON table of assessments from the call transcript, in a format such that, ';
            contentString_assessment = contentString_assessment + ' {"response": { ';
            contentString_assessment = contentString_assessment + ' "assessments": [{"question":"xxxxx", "response":"xxxxx", "assessment of response":"xxxxx [either "Negative", "Moderate" or "Positive"]", "rationale for assessment of response":"xxxxx", "relevant source statement(s)":"xxxxx"}]';
            contentString_assessment = contentString_assessment + ' }}';

                        
            //                 // contentString = contentString + ' ,"feedback": [{"Feedback":"xxxxx", "Owner":"xxxxx", "Reason for Feedback":"xxxxx", "Strategy to address Feedback":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';
            
            

            String contentString_NextSteps = 'create a JSON table of next steps related to closing the sale with columns for: Task_Subject, Owner, Reason for Importance, Importance';
            contentString_NextSteps = contentString_NextSteps + ' {"response": { ';
            contentString_NextSteps = contentString_NextSteps + ' "next_steps": [{"Task_Subject":"xxxxx", "Owner":"xxxxx", "Reason for Importance":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';
            contentString_NextSteps = contentString_NextSteps + ' }}';

            String contentString_Risks = 'create a JSON table of risks related to closing the sale for the sales call transcript with columns for: risk, Reason for Risk and strategy to address risk';
            contentString_Risks = contentString_Risks + ' {"response": { ';
            contentString_Risks = contentString_Risks + ' "risks": [{"Risk":"xxxxx", "Reason for Risk":"xxxxx", "Strategy to address Risk":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';
            contentString_Risks = contentString_Risks + ' }}';

            String contentString_Opportunity = 'create a JSON table of opportunities if the customer proceeds with the proposed solution with columns for: Opportunity, Reason for Opportunity, Strategy to Maximize the Opportunity';
            contentString_Opportunity = contentString_Opportunity + ' {"response": { ';
            contentString_Opportunity = contentString_Opportunity + ' "opportunities": [{"Opportunity":"xxxxx", "Reason for Opportunity":"xxxxx", "Strategy to maximize the Opportunity":"xxxxx", "Relevance to Customer":"xxxxx [either "Low", "Medium" or "High"]"}]';
            contentString_Opportunity = contentString_Opportunity + ' }}';

            String contentString = '';
            if(formList.size() == 0 || String.isBlank(formList[0].Kinetics__Spreadsheet_Template__c)
                || kineticFormId != 'a005g00003NSX2PAAX'){ 
                    // contentString = contentString + ' {"response": { ';
                    // contentString = contentString + ' "assessments": [{"question":"xxxxx", "response":"xxxxx", "assessment of response":"xxxxx [either "Negative", "Moderate" or "Positive"]", "rationale for assessment of response":"xxxxx", "relevant source statement(s)":"xxxxx"}]';
                    // // contentString = contentString + ' ,"opportunities": [{"Opportunity":"xxxxx", "Reason for Opportunity":"xxxxx", "Strategy to maximize the Opportunity":"xxxxx", "Relevance to Customer":"xxxxx [either "Low", "Medium" or "High"]"}]';
                    // // contentString = contentString + ' ,"risks": [{"Risk":"xxxxx", "Reason for Risk":"xxxxx", "Strategy to address Risk":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';
                    // // contentString = contentString + ' ,"feedback": [{"Feedback":"xxxxx", "Owner":"xxxxx", "Reason for Feedback":"xxxxx", "Strategy to address Feedback":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';
                    // contentString = contentString + ' ,"next_steps": [{"Task_Subject":"xxxxx", "Owner":"xxxxx", "Reason for Importance":"xxxxx", "Importance":"xxxxx [either "Low", "Medium" or "High"]"}]';
                    // contentString = contentString + ' }}';
            } else {
                contentString = contentString + ' {"response": [{';
                List<Object> rowMetadataListRaw = (List<Object>)JSON.deserializeUntyped(formList[0].Kinetics__Spreadsheet_Template__r.Kinetics__Row_Metadata__c);
                for(Object rowMetadataObj: rowMetadataListRaw) {
                     Map<String,Object> rowMetadata = (Map<String,Object>)rowMetadataObj;
                    if(rowMetadata.containsKey('columnWrapperList')) {
                        List<Object> columnWrapperListObj = (List<Object> )rowMetadata.get('columnWrapperList');
                        for(Object columnWrapperObj: columnWrapperListObj){
                            Map<String, Object> columnWrapper = (Map<String, Object>)columnWrapperObj;
                            InspSpreadsheetController.columnConf cconf = new InspSpreadsheetController.columnConf();
                            cconf.label = columnWrapper.containsKey('label')? (String)columnWrapper.get('label') : '';
                            cconf.fieldName = columnWrapper.containsKey('fieldName')? (String)columnWrapper.get('fieldName') : '';
                            contentString = contentString + '"'+cconf.label+'":"xxxxx", ';
                            // cconf.wrapText = columnWrapper.containsKey('wrapText')? (Boolean)columnWrapper.get('wrapText') : false;
                            // cconf.editable = columnWrapper.containsKey('editable')? (Boolean)columnWrapper.get('editable') : false;
                            //cconf.type = columnWrapper.containsKey('type')? (((String)columnWrapper.get('type')).toLowerCase()) : 'text';
                            //columnConfList.add(cconf);
                        }
                        break;
                    }
                }
                contentString = contentString + '}]';
            }
           
            contentString_assessment = contentString_assessment + ' Do not include any explanations, only provide a RFC8259 compliant JSON response. ';
            contentString_NextSteps = contentString_NextSteps + ' Do not include any explanations, only provide a RFC8259 compliant JSON response. ';
            contentString_Risks = contentString_Risks + ' Do not include any explanations, only provide a RFC8259 compliant JSON response. ';
            contentString_Opportunity = contentString_Opportunity + ' Do not include any explanations, only provide a RFC8259 compliant JSON response. ';

            
            Map<String, Object> seqResponseObj = (Map<String, Object>) JSON.deserializeUntyped(surveyQuestionWrapper);
            List<Object> sqList = (List<Object>)seqResponseObj.get('responseDetails');

            
            List<Map<String, String>> questionwrapperList = new List<Map<String, String>>();
            
            for(Object seqObj: sqList) {
                Map<String, Object> seqq = (Map<String, Object>) seqObj;
                Map<String, String> questionWrapp = new Map<String, String>();
                
                questionWrapp.put('questionText', String.valueOf(seqq.get('questionDetails')));
                questionWrapp.put('index', String.valueOf(seqq.get('index')));
                questionWrapp.put('qInstructions', String.valueOf(seqq.get('qInstructions')));

                questionwrapperList.add(questionWrapp);
            }


            contentString_assessment = contentString_assessment + 'For generating assessment please use these questions, '+ JSON.serialize(questionwrapperList);


            Map<String, Object> requestBodyMap_assessment = new Map<String, Object>();
            requestBodyMap_assessment.put('role', 'user');
            requestBodyMap_assessment.put('content',contentString_assessment);
            String requestPayload_assessment = JSON.serialize(requestBodyMap_assessment);
        

            Map<String, Object> requestBodyMap_nextSteps = new Map<String, Object>();
            requestBodyMap_nextSteps.put('role', 'user');
            requestBodyMap_nextSteps.put('content',contentString_NextSteps);
            String requestPayload_nextSteps = JSON.serialize(requestBodyMap_nextSteps);
        

            Map<String, Object> requestBodyMap_risks = new Map<String, Object>();
            requestBodyMap_risks.put('role', 'user');
            requestBodyMap_risks.put('content',contentString_Risks);
            String requestPayload_risks = JSON.serialize(requestBodyMap_risks);
        

            Map<String, Object> requestBodyMap_opportunity = new Map<String, Object>();
            requestBodyMap_opportunity.put('role', 'user');
            requestBodyMap_opportunity.put('content',contentString_Opportunity);
            String requestPayload_opportunity = JSON.serialize(requestBodyMap_opportunity);
        
            if(assessmentType == 'assessment'){
                return AssistantAPIController.create_update_Message(requestPayload_assessment, threadId);
            }
            if(assessmentType == 'next_steps'){
                return AssistantAPIController.create_update_Message(requestPayload_nextSteps, threadId);
            }
            if(assessmentType == 'risks'){
                return AssistantAPIController.create_update_Message(requestPayload_risks, threadId);
            }
            if(assessmentType == 'opportunity'){
                return AssistantAPIController.create_update_Message(requestPayload_opportunity, threadId);
            }
            return 'Invalid assessment type provided';
        } catch(Exception exc) {
            throw GlobalUtility.auraHandledMessageException(exc.getMessage());
        }
    }
    public static String create_Run(String assistantID, String threadId) {
        
        if(String.isBlank(assistantID)) {
            throw GlobalUtility.auraHandledMessageException('error: assistantID is required');
        }
        if(String.isBlank(threadId)) {
            throw GlobalUtility.auraHandledMessageException('error: thread ID is required');
        }
        return AssistantAPIController.create_Run(assistantID, threadId);
    }

    public static String retriveAllMessagesForThread(String threadId){

        String calloutResponse = AssistantAPIController.retriveAllMessagesForThread(threadId);
        system.debug('res:' + calloutResponse);
        return calloutResponse;
    }

    public static String getAllAvailableAssistants() {
        String calloutResponse = AssistantAPIController.getAllAvailableAssistants();
        system.debug('assistants res:' + calloutResponse);
        return calloutResponse;
    }

    public static String getRetrieveRun(String meetingId) {
        Map<String, String> requestBodyMap = new Map<String, String>();
        
        List<Kinetics__Meeting__c> meetingList = [SELECT Id, Name, Kinetics__GPT_Thread_ID__c, Kinetics__GPT_Thread_Run_Id__c
                                                FROM Kinetics__Meeting__c 
                                                WHERE Id = :meetingId];

        if(meetingList.size() == 0) {
            throw GlobalUtility.auraHandledMessageException('error: Meeting record not found');
        }
        if(String.isBlank(meetingList[0].Kinetics__GPT_Thread_ID__c)) {
            throw GlobalUtility.auraHandledMessageException('error: thread ID is required');
        }
        if(String.isBlank(meetingList[0].Kinetics__GPT_Thread_Run_Id__c)) {
            throw GlobalUtility.auraHandledMessageException('error: thread Run ID is required');
        }

        return AssistantAPIController.getRetrieveRun(meetingList[0].Kinetics__GPT_Thread_ID__c, meetingList[0].Kinetics__GPT_Thread_Run_Id__c);
    }
}