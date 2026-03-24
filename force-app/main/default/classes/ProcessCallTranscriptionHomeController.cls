/**
 * Author: shankar Dupade
 * Purpose: controller class to handle operations for meeting transcription processing
 * Date: 5-2-2024
 */

public with sharing class ProcessCallTranscriptionHomeController {

    @AuraEnabled
    public static string invokeSummaryGPTJob(String recordId){
        try {
            
            List<Kinetics__Meeting__c> meetingRecordList = [SELECT Id, Kinetics__GPT_Assistant_ID__c,Kinetics__GPT_Thread_ID__c, Kinetics__GPT_Thread_Run_Id__c,
                                                            Kinetics__Prompt_Template__r.Kinetics__Assistant__r.Kinetics__ChatGPT_Id__c, Kinetics__Evaluting_Stage__c
                                                            FROM Kinetics__Meeting__c 
                                                            WHERE Id = :recordId];
            
            if(meetingRecordList.size() == 0) {
                throw GlobalUtility.auraHandledMessageException('record Not found');
            }
            if(String.isBlank(meetingRecordList[0].Kinetics__Prompt_Template__c)
                || String.isBlank(meetingRecordList[0].Kinetics__Prompt_Template__r.Kinetics__Assistant__c)
                || String.isBlank(meetingRecordList[0].Kinetics__Prompt_Template__r.Kinetics__Assistant__r.Kinetics__ChatGPT_Id__c)){
                throw GlobalUtility.auraHandledMessageException('Please provide prompt template with assistant assigned.');
            }

            String assistantId = meetingRecordList[0].Kinetics__Prompt_Template__r.Kinetics__Assistant__r.Kinetics__ChatGPT_Id__c;
            String threadId  = meetingRecordList[0].Kinetics__GPT_Thread_ID__c;
            if(String.isNotBlank(threadId) && String.isNotBlank(assistantId)) {
                return threadId;
            }

            String threadCreationUpdationResult = GPTCallTranscriptionHelper.create_update_Thread(assistantId, threadId, recordId);
            system.debug('threadCreationUpdationResult: ' + threadCreationUpdationResult);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(threadCreationUpdationResult);
            if(responseMap.containsKey('object') && String.valueOf(responseMap.get('object')) == 'thread') {
                threadId =  String.valueOf(responseMap.get('id'));
            }
            meetingRecordList[0].Kinetics__GPT_Assistant_ID__c = meetingRecordList[0].Kinetics__Prompt_Template__r.Kinetics__Assistant__r.Kinetics__ChatGPT_Id__c;
            meetingRecordList[0].Kinetics__GPT_Thread_ID__c = threadId;
            meetingRecordList[0].Kinetics__Evaluting_Stage__c = 'assessment';
            update meetingRecordList;
            return threadId;
        } catch (Exception exc) {
            throw GlobalUtility.auraHandledMessageException(exc.getMessage());
        }
    }

    @AuraEnabled
    public static string pushCallTranscription(String recordId){
        try {
            List<Kinetics__Meeting__c> meetingRecordList = [SELECT Id, Kinetics__GPT_Thread_ID__c, Kinetics__Transcript_RTF__c, Kinetics__Files_Ids__c 
                                                            FROM Kinetics__Meeting__c 
                                                            WHERE Id = :recordId];
            
            if(meetingRecordList.size() == 0) {
                throw GlobalUtility.auraHandledMessageException('Meeting record Not found');
            }

            GPTCallTranscriptionHelper.pushCallTranscription(recordId);
            return 'Submitted';
        } catch (Exception e) {
            throw GlobalUtility.auraHandledMessageException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string createMessageForSummaryGPTJob(String recordId, String assessmentType){
        try {
            List<Kinetics__Meeting__c> meetingRecordList = [SELECT Id, Kinetics__GPT_Assistant_ID__c,Kinetics__GPT_Thread_ID__c, 
                                                            Kinetics__GPT_Thread_Run_Id__c, Kinetics__Prompt_Template__c
                                                            FROM Kinetics__Meeting__c 
                                                            WHERE Id = :recordId];
            
            if(meetingRecordList.size() == 0) {
                throw GlobalUtility.auraHandledMessageException('record Not found');
            }
            String assistantId = meetingRecordList[0].Kinetics__GPT_Assistant_ID__c;
            String threadId  = meetingRecordList[0].Kinetics__GPT_Thread_ID__c;
            String kineticFormId = meetingRecordList[0].Kinetics__Prompt_Template__c;
            String createMesssageResponse = GPTCallTranscriptionHelper.create_update_Message(assistantId, threadId, recordId, kineticFormId, assessmentType);
            // meetingRecordList[0].Kinetics__Evaluting_Stage__c = assessmentType;
            // update meetingRecordList;
            return createMesssageResponse;
        }catch(Exception exc) {
            throw GlobalUtility.auraHandledMessageException(exc.getMessage());
        }
    }



    @AuraEnabled
    public static string runSummaryGPTJob(String recordId){
        try {
            
            List<Kinetics__Meeting__c> meetingRecordList = [SELECT Id, Kinetics__GPT_Assistant_ID__c,Kinetics__GPT_Thread_ID__c, Kinetics__GPT_Thread_Run_Id__c 
                                                            FROM Kinetics__Meeting__c 
                                                            WHERE Id = :recordId];
            
            if(meetingRecordList.size() == 0) {
                throw GlobalUtility.auraHandledMessageException('record Not found');
            }
            String assistantId = meetingRecordList[0].Kinetics__GPT_Assistant_ID__c;
            String threadId  = meetingRecordList[0].Kinetics__GPT_Thread_ID__c;
            String runID = meetingRecordList[0].Kinetics__GPT_Thread_Run_Id__c;
            String threadCreationUpdationResult = GPTCallTranscriptionHelper.create_Run(assistantId, threadId);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(threadCreationUpdationResult);
            if(responseMap.containsKey('object') && String.valueOf(responseMap.get('object')) == 'thread.run') {
                runID =  String.valueOf(responseMap.get('id'));
                meetingRecordList[0].Kinetics__GPT_Thread_Run_Id__c = runID;
                meetingRecordList[0].Kinetics__GPT_Thread_Run_Job_Status__c = String.valueOf(responseMap.get('status'));
                update meetingRecordList;
            }
            return runID;
        } catch (Exception e) {
            throw GlobalUtility.auraHandledMessageException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string retriveMessagesForThread(String recordId){
        try {
            List<Kinetics__Meeting__c> meetingRecordList = [SELECT Id, Kinetics__GPT_Assistant_ID__c,Kinetics__GPT_Thread_ID__c, Kinetics__GPT_Thread_Run_Id__c,
                                                            Kinetics__Prompt_Template__c, Kinetics__Prompt_Template__r.Kinetics__Spreadsheet_Template__c,
                                                            Kinetics__Prompt_Template__r.Kinetics__Spreadsheet_Template__r.Kinetics__Object_API_Name__c,
                                                            Kinetics__Prompt_Template__r.Kinetics__Spreadsheet_Template__r.Kinetics__Row_Metadata__c
                                                            FROM Kinetics__Meeting__c 
                                                            WHERE Id = :recordId 
                                                            AND Kinetics__GPT_Thread_Run_Job_Status__c = 'queued' 
                                                            LIMIT 1];
            
            if(meetingRecordList.size() == 0) {
                throw GlobalUtility.auraHandledMessageException('record Not found');
            }
            String threadId  = meetingRecordList[0].Kinetics__GPT_Thread_ID__c;
            String runID = meetingRecordList[0].Kinetics__GPT_Thread_Run_Id__c;
            String threadCreationUpdationResult = GPTCallTranscriptionHelper.retriveAllMessagesForThread(threadId);
            system.debug('threadCreationUpdationResult: ' + threadCreationUpdationResult);
            //Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(threadCreationUpdationResult);
            AssistantAPIResponse assistantAPIResponseMap = AssistantAPIResponse.parse(threadCreationUpdationResult);
            
            // if(!(assistantAPIResponseMap != null
            //     && assistantAPIResponseMap.data != null
            //     && assistantAPIResponseMap.data[0] != null
            //     && assistantAPIResponseMap.data[0].content != null
            //     && assistantAPIResponseMap.data[0].content[0] != null
            //     && assistantAPIResponseMap.data[0].content[0].text != null
            //     && assistantAPIResponseMap.data[0].content[0].text.value != null
            //     )) {
            //         throw GlobalUtility.auraHandledMessageException('Response not received in correct format');
            // }

            String responseValue = assistantAPIResponseMap.data[0].content[0].text.value;
            responseValue= responseValue.replace(responseValue.substringBefore('```json'),'');
            responseValue = responseValue.replace('```json', '');
            responseValue = responseValue.replace('```', '');
            Map<String, Object> responseMapObj = (Map<String, Object>)JSON.deserializeUntyped(responseValue);
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap = (Map<String, Object>)responseMapObj.get('response');

            List<Object> assessmentQuestionAnswerMap = new List<Object>();
            List<Object> opportunitiesMap = new List<Object>();
            List<Object> risksMap = new List<Object>();
            List<Object> feedbackMap = new List<Object>();
            List<Object> next_stepsMap = new List<Object>();
            if(responseMap.containsKey('assessments')) {
                assessmentQuestionAnswerMap = (List<Object>) responseMap.get('assessments');
            }
            if(responseMap.containsKey('opportunities')) {
                opportunitiesMap = (List<Object>) responseMap.get('opportunities');
            }
            if(responseMap.containsKey('risks')) {
                risksMap = (List<Object>) responseMap.get('risks');
            }
            if(responseMap.containsKey('feedback')) {
                feedbackMap = (List<Object>) responseMap.get('feedback');
            }
            if(responseMap.containsKey('next_steps')) {
                next_stepsMap = (List<Object>) responseMap.get('next_steps');
            }

           List<sObject> assessmentList = new List<sObject>();
            List<InspSpreadsheetController.columnConf> columnConfList = new List<InspSpreadsheetController.columnConf>();
            String objectAPIName = '';
            if(meetingRecordList.size() > 0 
                && meetingRecordList[0].Kinetics__Prompt_Template__c == 'a005g00003NSX2PAAX' 
                && String.isNotBlank(meetingRecordList[0].Kinetics__Prompt_Template__r.Kinetics__Spreadsheet_Template__c)
                && String.isNotBlank(meetingRecordList[0].Kinetics__Prompt_Template__r.Kinetics__Spreadsheet_Template__r.Kinetics__Row_Metadata__c)
                && String.isNotBlank(meetingRecordList[0].Kinetics__Prompt_Template__r.Kinetics__Spreadsheet_Template__r.Kinetics__Object_API_Name__c)) {

                objectAPIName = meetingRecordList[0].Kinetics__Prompt_Template__r.Kinetics__Spreadsheet_Template__r.Kinetics__Object_API_Name__c;
                List<Object> rowMetadataListRaw = (List<Object>)JSON.deserializeUntyped(meetingRecordList[0].Kinetics__Prompt_Template__r.Kinetics__Spreadsheet_Template__r.Kinetics__Row_Metadata__c);
                for(Object rowMetadataObj: rowMetadataListRaw) {
                     Map<String,Object> rowMetadata = (Map<String,Object>)rowMetadataObj;
                    if(rowMetadata.containsKey('columnWrapperList')) {
                        List<Object> columnWrapperListObj = (List<Object> )rowMetadata.get('columnWrapperList');
                        for(Object columnWrapperObj: columnWrapperListObj){
                            Map<String, Object> columnWrapper = (Map<String, Object>)columnWrapperObj;
                            InspSpreadsheetController.columnConf cconf = new InspSpreadsheetController.columnConf();
                            cconf.label = columnWrapper.containsKey('label')? (String)columnWrapper.get('label') : '';
                            cconf.fieldName = columnWrapper.containsKey('fieldName')? (String)columnWrapper.get('fieldName') : '';
                            columnConfList.add(cconf);
                        }
                        break;
                    }
                }
            } else {
                objectAPIName = 'Kinetics__Assessment_of_Response__c';
                InspSpreadsheetController.columnConf cconf = new InspSpreadsheetController.columnConf();
                cconf.label = 'question';
                cconf.fieldName = 'Kinetics__Question__c';
                columnConfList.add(cconf);
                
                InspSpreadsheetController.columnConf cconf2 = new InspSpreadsheetController.columnConf();
                cconf2.label = 'response';
                cconf2.fieldName = 'Kinetics__Response__c';
                columnConfList.add(cconf2);
                
                InspSpreadsheetController.columnConf cconf3 = new InspSpreadsheetController.columnConf();
                cconf3.label = 'assessment of response';
                cconf3.fieldName = 'Kinetics__Assessment_of_Response__c';
                columnConfList.add(cconf3);

                InspSpreadsheetController.columnConf cconf4 = new InspSpreadsheetController.columnConf();
                cconf4.label = 'rationale for assessment of response';
                cconf4.fieldName = 'Kinetics__Rationale_for_Assessment__c';
                columnConfList.add(cconf4);

                InspSpreadsheetController.columnConf cconf5 = new InspSpreadsheetController.columnConf();
                cconf5.label = 'relevant source statement(s)';
                cconf5.fieldName = 'Kinetics__Candidate_s_Relevant_Source_Statement_s__c';
                columnConfList.add(cconf5);
            }
            for(Object questionAnsWrap:  assessmentQuestionAnswerMap){
                sObject assmntObj = (sObject)Type.forName(objectAPIName).newInstance();
                Map<String, Object> questionAnswerWrapper = (Map<String, Object>)questionAnsWrap;

                assmntObj.put('Kinetics__Meeting__c',recordId);
                assmntObj.put('Kinetics__Assessment_Type__c','Assessment');
                
                for(InspSpreadsheetController.columnConf colconf: columnConfList) {
                    if(questionAnswerWrapper.containsKey(colconf.label)) {
                        assmntObj.put(colconf.fieldName, String.valueOf(questionAnswerWrapper.get(colconf.label)));
                    }
                // assmntObj.Kinetics__Response__c = String.valueOf(questionAnswerWrapper.get('response'));
                // assmntObj.Kinetics__Assessment_of_Response__c = String.valueOf(questionAnswerWrapper.get('assessment of response'));
                // assmntObj.Kinetics__Rationale_for_Assessment__c = String.valueOf(questionAnswerWrapper.get('rationale for assessment of response'));
                // assmntObj.Kinetics__Candidate_s_Relevant_Source_Statement_s__c = String.valueOf(questionAnswerWrapper.get('relevant source statement(s)'));
                }
                assessmentList.add(assmntObj);
            }

            for(Object responseQuestionAnsWrap:  opportunitiesMap){
                sObject assmntObj = (sObject)Type.forName(objectAPIName).newInstance();
                Map<String, Object> oppQuestionAnswerWrapper = (Map<String, Object>)responseQuestionAnsWrap;

                //System.debug(oppQuestionAnswerWrapper);
                assmntObj.put('Kinetics__Meeting__c',recordId);
                assmntObj.put('Kinetics__Assessment_Type__c','Opportunities');
                
                if(oppQuestionAnswerWrapper.containsKey('Opportunity')) {
                    assmntObj.put('Kinetics__Opportunity__c', String.valueOf(oppQuestionAnswerWrapper.get('Opportunity')));
                }
                if(oppQuestionAnswerWrapper.containsKey('Reason for Opportunity')) {
                    assmntObj.put('Kinetics__Reason_for_Opportunity__c', String.valueOf(oppQuestionAnswerWrapper.get('Reason for Opportunity')));
                }
                if(oppQuestionAnswerWrapper.containsKey('Strategy to maximize the Opportunity')) {
                    assmntObj.put('Kinetics__Strategy_to_maximize_the_Opportunity__c', String.valueOf(oppQuestionAnswerWrapper.get('Strategy to maximize the Opportunity')));
                }
                if(oppQuestionAnswerWrapper.containsKey('Relevance to Customer')) {
                    assmntObj.put('Kinetics__Relevance_to_Customer__c', String.valueOf(oppQuestionAnswerWrapper.get('Relevance to Customer')));
                }
                assessmentList.add(assmntObj);
            }

            for(Object responseQuestionAnsWrap:  risksMap){
                sObject assmntObj = (sObject)Type.forName(objectAPIName).newInstance();
                Map<String, Object> riskQuestionAnswerWrapper = (Map<String, Object>)responseQuestionAnsWrap;

                //System.debug(riskQuestionAnswerWrapper);
                assmntObj.put('Kinetics__Meeting__c',recordId);
                assmntObj.put('Kinetics__Assessment_Type__c','Risks');

                if(riskQuestionAnswerWrapper.containsKey('Risk')) {
                    assmntObj.put('Kinetics__Risk__c', String.valueOf(riskQuestionAnswerWrapper.get('Risk')));
                }
                if(riskQuestionAnswerWrapper.containsKey('Reason for Risk')) {
                    assmntObj.put('Kinetics__Reason_for_Risk__c', String.valueOf(riskQuestionAnswerWrapper.get('Reason for Risk')));
                }
                if(riskQuestionAnswerWrapper.containsKey('Strategy to address Risk')) {
                    assmntObj.put('Kinetics__Strategy_to_address_Risk__c', String.valueOf(riskQuestionAnswerWrapper.get('Strategy to address Risk')));
                }
                if(riskQuestionAnswerWrapper.containsKey('Importance')) {
                    assmntObj.put('Kinetics__Importance__c', String.valueOf(riskQuestionAnswerWrapper.get('Importance')));
                }
                assessmentList.add(assmntObj);
            }

            for(Object responseQuestionAnsWrap:  feedbackMap){
                sObject assmntObj = (sObject)Type.forName(objectAPIName).newInstance();
                Map<String, Object> feedbackQuestionAnswerWrapper = (Map<String, Object>)responseQuestionAnsWrap;

                //System.debug(feedbackQuestionAnswerWrapper);
                assmntObj.put('Kinetics__Meeting__c',recordId);
                assmntObj.put('Kinetics__Assessment_Type__c','Feedback');

                if(feedbackQuestionAnswerWrapper.containsKey('Feedback')) {
                    assmntObj.put('Kinetics__Feedback__c', String.valueOf(feedbackQuestionAnswerWrapper.get('Feedback')));
                }
                if(feedbackQuestionAnswerWrapper.containsKey('Owner')) {
                    assmntObj.put('Kinetics__Owner__c', String.valueOf(feedbackQuestionAnswerWrapper.get('Owner')));
                }
                if(feedbackQuestionAnswerWrapper.containsKey('Reason for Feedback')) {
                    assmntObj.put('Kinetics__Reason_for_Feedback__c', String.valueOf(feedbackQuestionAnswerWrapper.get('Reason for Feedback')));
                }
                if(feedbackQuestionAnswerWrapper.containsKey('Strategy to address Feedback')) {
                    assmntObj.put('Kinetics__Strategy_to_address_Feedback__c', String.valueOf(feedbackQuestionAnswerWrapper.get('Strategy to address Feedback')));
                }
                if(feedbackQuestionAnswerWrapper.containsKey('Importance')) {
                    assmntObj.put('Kinetics__Importance__c', String.valueOf(feedbackQuestionAnswerWrapper.get('Importance')));
                }
                assessmentList.add(assmntObj);
            }
            for(Object responseQuestionAnsWrap:  next_stepsMap){
                sObject assmntObj = (sObject)Type.forName(objectAPIName).newInstance();
                Map<String, Object> next_stepsQuestionAnswerWrapper = (Map<String, Object>)responseQuestionAnsWrap;

                //System.debug(next_stepsQuestionAnswerWrapper);
                assmntObj.put('Kinetics__Meeting__c',recordId);
                assmntObj.put('Kinetics__Assessment_Type__c', 'Next Steps');

                if(next_stepsQuestionAnswerWrapper.containsKey('Task_Subject')) {
                    assmntObj.put('Kinetics__Task_Subject__c', String.valueOf(next_stepsQuestionAnswerWrapper.get('Task_Subject')));
                }
                if(next_stepsQuestionAnswerWrapper.containsKey('Owner')) {
                    assmntObj.put('Kinetics__Owner__c', String.valueOf(next_stepsQuestionAnswerWrapper.get('Owner')));
                }
                if(next_stepsQuestionAnswerWrapper.containsKey('Reason for Importance')) {
                    assmntObj.put('Kinetics__Reason_for_Importance__c', String.valueOf(next_stepsQuestionAnswerWrapper.get('Reason for Importance')));
                }
                if(next_stepsQuestionAnswerWrapper.containsKey('Importance')) {
                    assmntObj.put('Kinetics__Importance__c', String.valueOf(next_stepsQuestionAnswerWrapper.get('Importance')));
                }
                assessmentList.add(assmntObj);
            }
    
            if(assessmentList.size() > 0) {
                // ContentNote objCntNote = new ContentNote();
                // objCntNote.Title = 'testing';
                // objCntNote.Content = Blob.valueOf(responseMessageBody);
                // insert objCntNote; //Insert Content Note   
                
                // List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
                // //create ContentDocumentLink  record to link with parentId 
                // ContentDocumentLink objCntDocLink = new ContentDocumentLink();
                // objCntDocLink.LinkedEntityId = recordId;
                // objCntDocLink.ContentDocumentId = objCntNote.Id;  //Content Note Id
                // objCntDocLink.shareType = 'V'; // Specify your sharing type 
                // cdLinkList.add(objCntDocLink);

                // insert cdLinkList;

                upsert assessmentList;

                meetingRecordList[0].Kinetics__GPT_Thread_Run_Job_Status__c = 'completed';
                update meetingRecordList;
            }
            return threadCreationUpdationResult;
        } catch (Exception e) {
            throw GlobalUtility.auraHandledMessageException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getAllAvailableAssistants(){
        try {
            return GPTCallTranscriptionHelper.getAllAvailableAssistants();
            
        } catch (Exception e) {
            throw GlobalUtility.auraHandledMessageException(e.getMessage());
        }
    }
}