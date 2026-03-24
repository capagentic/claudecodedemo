/**
* Author: Shankar Dupade 
* Date: 6-4-2023
* Purpose: controller class to complete inspection
*/

public with sharing class TbInspTemplateQuestionRendererController {
   
    @AuraEnabled
    public static string getInspectionDetails(String inspectionRecId){
        try {
            Map<String, Object> resultWrapper = new Map<String, Object>();
            List<Kinetics__Inspection__c> inspectionList = [SELECT Id, Name, Kinetics__Account__c,
                                                            Kinetics__Contact__c, Kinetics__Status__c,
                                                            Kinetics__Template__c 
                                                            FROM Kinetics__Inspection__c 
                                                            WHERE Id =: inspectionRecId 
                                                            LIMIT 1];

            if(inspectionList.size() == 0) {
                return JSON.serialize(resultWrapper);
            }

            List<Kinetics__Kinetic_Form__c> templateRecList = [SELECT Id, Name, Kinetics__Instructions__c,
                                                                Kinetics__Status__c, Kinetics__Questions_By_Page_No__c,
                                                                Kinetics__Section_Metadata__c,Kinetics__Template_Metadata__c
                                                                FROM Kinetics__Kinetic_Form__c
                                                                WHERE Id = :inspectionList[0].Kinetics__Template__c
                                                                LIMIT 1];
             if(templateRecList.size() == 0) {
                return JSON.serialize(resultWrapper);
            }


            resultWrapper.put('inspectionRec', inspectionList[0]);
            resultWrapper.put('templateRec', templateRecList[0]);
            Map<String,Kinetics__Kinetic_Form_Answer__c> existingAnswersByUniqueId = new Map<String,Kinetics__Kinetic_Form_Answer__c>();
            List<String> existingAnswerIdList = new List<String>();
            for(Kinetics__Kinetic_Form_Answer__c existingAnswer : [SELECT Id, Kinetics__Answer_Index__c,Kinetics__Kinetic_Question__c,
                                    Kinetics__Kinetic_Question_Values__c,Kinetics__Type__c,Kinetics__Answer__c,Kinetics__Inspection__c,
                                    Kinetics__Score_Attained__c,Kinetics__Out_of_Score__c,Kinetics__Template_Question_UID__c,
                                    Kinetics__AI_Guidance__c
                                        FROM Kinetics__Kinetic_Form_Answer__c
                                        WHERE Kinetics__Inspection__c = :inspectionList[0].Id]){
                //inspTemplateAnswer
                existingAnswersByUniqueId.put(existingAnswer.Kinetics__Template_Question_UID__c, existingAnswer);
                existingAnswerIdList.add(existingAnswer.Id);
            }
            resultWrapper.put('existingAnswersByUniqueId', existingAnswersByUniqueId);


            Map<String, Integer> taskCountByAnswerId = new Map<String, Integer>();
            for(Task t: [SELECT Id, Kinetics__Template_Answer__c 
                            FROM Task 
                            WHERE Kinetics__Template_Answer__c IN :existingAnswerIdList
                            AND WhatId =: inspectionRecId ]) {
                Integer count = 0;
                if(taskCountByAnswerId.containsKey(t.Kinetics__Template_Answer__c)) {
                    count = taskCountByAnswerId.get(t.Kinetics__Template_Answer__c);
                }
                count = count + 1;
                taskCountByAnswerId.put(t.Kinetics__Template_Answer__c, count);
            }
            resultWrapper.put('taskCountByAnswerId', taskCountByAnswerId);

            Map<String, Integer> noteCountByAnswerId = new Map<String, Integer>();
            Map<String, String> linkedIdByDocumentIdMap = new Map<String, String>();
            List<String> contentNoteId = new List<String>();
            if(existingAnswerIdList.size() > 0){
                for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId,ContentDocumentId 
                                                FROM ContentDocumentLink 
                                                WHERE LinkedEntityId IN :existingAnswerIdList]){
                    
                    
                    linkedIdByDocumentIdMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                }
                
                for(ContentNote contentNoteRec : [SELECT Id FROM ContentNote WHERE Id IN: linkedIdByDocumentIdMap.keySet()]){
                    contentNoteId.add(contentNoteRec.Id);
                }
                
                for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId,ContentDocumentId 
                                                FROM ContentDocumentLink 
                                                WHERE LinkedEntityId IN :existingAnswerIdList
                                                AND ContentDocumentId IN :contentNoteId]){
                    Integer count = 0;
                    if(noteCountByAnswerId.containsKey(cdl.LinkedEntityId)) {
                        count = noteCountByAnswerId.get(cdl.LinkedEntityId);
                    }
                    count = count + 1;
                    noteCountByAnswerId.put(cdl.LinkedEntityId, count);
                }
            }
            resultWrapper.put('noteCountByAnswerId', noteCountByAnswerId);

            Map<String, Integer> fileCountByAnswerId = new Map<String, Integer>();
            if(existingAnswerIdList.size() > 0){
                for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId,ContentDocumentId 
                                                FROM ContentDocumentLink 
                                                WHERE LinkedEntityId IN :existingAnswerIdList
                                                AND ContentDocumentId NOT IN :contentNoteId
                                                AND (NOT ContentDocument.Title LIKE '%Signature%')]){
                    Integer count = 0;
                    if(fileCountByAnswerId.containsKey(cdl.LinkedEntityId)) {
                        count = fileCountByAnswerId.get(cdl.LinkedEntityId);
                    }
                    count = count + 1;
                    fileCountByAnswerId.put(cdl.LinkedEntityId, count);
                }
            }
            resultWrapper.put('fileCountByAnswerId', fileCountByAnswerId);
            
            return JSON.serialize(resultWrapper);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Kinetics__Kinetic_Form_Answer__c getAnswerWrapper(Decimal index, String inspectionId, Map<String, Object> questionWrapperObj) {
        Kinetics__Kinetic_Form_Answer__c answer2Commit = new Kinetics__Kinetic_Form_Answer__c();
        answer2Commit.Kinetics__Answer_Index__c = index;
        answer2Commit.Kinetics__Kinetic_Question__c = questionWrapperObj.containsKey('Name') ? String.valueOf(questionWrapperObj.get('Name')) : '';
        answer2Commit.Kinetics__Kinetic_Question_Values__c = questionWrapperObj.containsKey('Kinetics__Values__c') ? JSON.serialize(questionWrapperObj.get('Kinetics__Values__c')) : JSON.serialize(new List<Map<string, String>>());
        answer2Commit.Kinetics__Kinetic_Form_Question__c = null;
        answer2Commit.Kinetics__Type__c = questionWrapperObj.containsKey('Kinetics__Field_Type__c') ? String.valueOf(questionWrapperObj.get('Kinetics__Field_Type__c')) : '[]';
        answer2Commit.Kinetics__Answer__c = '';
        answer2Commit.Kinetics__Kinetic_Question_Id__c = null;
        answer2Commit.Kinetics__Inspection__c = inspectionId;
        answer2Commit.Kinetics__Template_Question_UID__c = questionWrapperObj.containsKey('uid') ? String.valueOf(questionWrapperObj.get('uid')) : '';
        answer2Commit.Kinetics__AI_Guidance__c = questionWrapperObj.containsKey('Kinetics__AI_Guidance__c') ? String.valueOf(questionWrapperObj.get('Kinetics__AI_Guidance__c')) : '';
        answer2Commit.Kinetics__Dependent_Flows__c = questionWrapperObj.containsKey('flows') ? String.valueOf(questionWrapperObj.get('flows')) : '';

        return answer2Commit;
    }

    public static void createAnswersForJSONBasedTemplate(String inspectionId, String templateMetadata) {
        Kinetics__Inspection__c inspectionRec = new Kinetics__Inspection__c(Id = inspectionId);
        List<Kinetics__Kinetic_Form_Answer__c> answers2Insert = new List<Kinetics__Kinetic_Form_Answer__c>();

        List<Kinetics__Kinetic_Form_Answer__c> existingAnswerList = [SELECT Id, Kinetics__Answer__c, Kinetics__Kinetic_Question_Id__c
                                                                            FROM Kinetics__Kinetic_Form_Answer__c
                                                                            WHERE Kinetics__Inspection__c = :inspectionId
                                                                            ];
        delete existingAnswerList;

        List<Object> pageObjList = new List<Object>();
        pageObjList = (List<Object>) JSON.deserializeUntyped(templateMetadata);
        if(pageObjList.size() == 0) {
            return;
        }
        Integer totalAvailableScore = 0;
        Decimal index = 1;
        for(Object pgObj : pageObjList) {
            Map<String, Object> pageObj = (Map<String, Object>)pgObj;
            if(!pageObj.containsKey('sectionlist')) {
                continue;
            }
            List<Object> sectionListObj = new List<Object>();
            sectionListObj = (List<Object>) pageObj.get('sectionlist');
            for(Object sectnObj: sectionListObj) {
                Map<String, Object> sectionObj = (Map<String, Object>)sectnObj;
                if(!sectionObj.containsKey('questionWrapperList')) {
                    continue;
                }
                List<Object> questionWrapperList = new List<Object>();
                questionWrapperList = (List<Object>) sectionObj.get('questionWrapperList');
                for(Object questWrapperObj: questionWrapperList) {
                    Map<String, Object> questionWrapperObj = (Map<String, Object>)questWrapperObj;
                    Kinetics__Kinetic_Form_Answer__c answer2Commit = TbInspTemplateQuestionRendererController.getAnswerWrapper(index, inspectionId, questionWrapperObj);
                    Integer maxScoreForQuestion = 0;
                    if(String.isNotBlank(answer2Commit.Kinetics__Kinetic_Question_Values__c)){
                        List<Object> optionsListObj = new List<Object>();
                        optionsListObj = questionWrapperObj.containsKey('Kinetics__Values__c') ? (List<Object>)questionWrapperObj.get('Kinetics__Values__c') :  null;
                        if(optionsListObj != null){
                            for(Object optn: optionsListObj) {
                                Map<String, Object> option = (Map<String, Object>)optn;
                                if(option.containsKey('score') && option.get('score') != null
                                    && String.valueOf(option.get('score')) != ''
                                    && maxScoreForQuestion < Integer.valueOf(option.get('score'))) {
                                    maxScoreForQuestion = Integer.valueOf(option.get('score'));
                                }
                            }
                        }
                        totalAvailableScore = totalAvailableScore + maxScoreForQuestion;
                    }
                    answer2Commit.Kinetics__Out_of_Score__c = maxScoreForQuestion;
                    answers2Insert.add(answer2Commit);



                    //create dependent question if any
                    if(questionWrapperObj.containsKey('dependantQuestions')) {
                        Map<String, Object> questionWrapperByOptionValue = new Map<String, Object>();
                        questionWrapperByOptionValue = (Map<String, Object>) questionWrapperObj.get('dependantQuestions');
                        for(String optionValue: questionWrapperByOptionValue.keySet()) {
                            Map<String, Object> dependentQuestionWrapperObject = new Map<String, Object>();
                            dependentQuestionWrapperObject = (Map<String, Object>) questionWrapperByOptionValue.get(optionValue);
                        
                            Map<String, Object> dependentQuestionWrapperObj = (Map<String, Object>)dependentQuestionWrapperObject.get('question');
       
                            Decimal dependentIndex = index + 0.1;
                            Kinetics__Kinetic_Form_Answer__c answer2Commit1 = TbInspTemplateQuestionRendererController.getAnswerWrapper(dependentIndex, inspectionId, dependentQuestionWrapperObj);
                            Integer maxScoreForQuestion1 = 0;
                            if(String.isNotBlank(answer2Commit1.Kinetics__Kinetic_Question_Values__c)){
                                List<Object> optionsListObj1 = new List<Object>();
                                optionsListObj1 = dependentQuestionWrapperObj.containsKey('Kinetics__Values__c') ? (List<Object>)dependentQuestionWrapperObj.get('Kinetics__Values__c') :  null;
                                if(optionsListObj1 != null){
                                    for(Object optn: optionsListObj1) {
                                        Map<String, Object> option1 = (Map<String, Object>)optn;
                                        if(option1.containsKey('score') && option1.get('score') != null
                                            && String.valueOf(option1.get('score')) != ''
                                            && maxScoreForQuestion1 < Integer.valueOf(option1.get('score'))) {
                                            maxScoreForQuestion1 = Integer.valueOf(option1.get('score'));
                                        }
                                    }
                                }
                                totalAvailableScore = totalAvailableScore + maxScoreForQuestion1;
                            }
                            answer2Commit1.Kinetics__Out_of_Score__c = maxScoreForQuestion1;
                            answer2Commit1.Kinetics__Required_Parent_Value__c = optionValue;
                            answers2Insert.add(answer2Commit1);
                            // to limit creation of answer for dependent questions to 1 answer only
                            break;
                        }
                    }
                    index = index + 1;
                }
            }
        }

        inspectionRec.Kinetics__Available_Score__c = totalAvailableScore;
        

        insert answers2Insert;
        update inspectionRec;
    }

    @AuraEnabled
    public static String saveAnswers(String answerJsonString){
        system.debug('***** answerJsonString=' + answerJsonString);
        InspTemplateRendererController.InspTemplateResponse sRes = new InspTemplateRendererController.InspTemplateResponse();
        try{
            Map<String, Kinetics__Kinetic_Form_Answer__c> answerByTemplateQuestionId = new Map<String, Kinetics__Kinetic_Form_Answer__c>();
            Map<String, inspTemplateAnswer> answersObj = (Map<String, inspTemplateAnswer>) JSON.deserializeStrict(answerJsonString, Map<String, inspTemplateAnswer>.class);
            List<Kinetics__Kinetic_Form_Answer__c> answers2Insert = new List<Kinetics__Kinetic_Form_Answer__c>();
            String inspectionId;
            Map<String, String> questionIdMap = new Map<String, String>();
            for(String templateQuestionId: answersObj.keySet()){
                inspTemplateAnswer answer = answersObj.get(templateQuestionId);

                Kinetics__Kinetic_Form_Answer__c answer2Commit = new Kinetics__Kinetic_Form_Answer__c();
                if(String.isNotBlank(answer.existingAnswerId)) {
                    answer2Commit.Id = answer.existingAnswerId;
                }
                system.debug('*****saveAnswers>answer.index=' + answer.index);
                //answer2Commit.Kinetics__Answer_Index__c = Decimal.valueOf(answer.index);
                answer2Commit.Kinetics__Kinetic_Question__c = answer.questionDetails;
                answer2Commit.Kinetics__Kinetic_Question_Values__c = answer.questionValues;
                //answer2Commit.Kinetics__Kinetic_Form_Question__c = templateQuestionId;
                answer2Commit.Kinetics__Type__c = answer.fieldType;
                answer2Commit.Kinetics__Answer__c = answer.answer;
                //answer2Commit.Kinetics__Kinetic_Question_Id__c = answer.questionId;
                answer2Commit.Kinetics__Inspection__c = answer.inspectionId;
                answer2Commit.Kinetics__Score_Attained__c = answer.scoreAttained;
                answer2Commit.Kinetics__Out_of_Score__c = answer.outOfScore;
                answer2Commit.Kinetics__Template_Question_UID__c = templateQuestionId;
                answer2Commit.Kinetics__AI_Guidance__c = answer.chatgptguidance;
                inspectionId = answer2Commit.Kinetics__Inspection__c;

                //answer2Commit.Survey__c = answer.surveyId;
                answers2Insert.add(answer2Commit);
                questionIdMap.put(answer.questionId, templateQuestionId);

                //generated for checking if all questions are answered
                answerByTemplateQuestionId.put(templateQuestionId, answer2Commit);
            }

            Map<String, String> answerIdMap = new Map<String, String>();
            Map<String, Kinetics__Kinetic_Form_Answer__c> answerRecordById = new Map<String, Kinetics__Kinetic_Form_Answer__c>();
          
            if(!answers2Insert.isEmpty()){
                upsert answers2Insert;
                for(Kinetics__Kinetic_Form_Answer__c templateAnswer: answers2Insert){
                    String templateQuestionId = String.valueOf(questionIdMap.get(String.valueOf(templateAnswer.Kinetics__Template_Question_UID__c)));
                    answerIdMap.put(templateQuestionId, templateAnswer.Id);
                    answerRecordById.put(templateAnswer.Id, templateAnswer);
                }

                List<Kinetics__Kinetic_Form_Answer__c> childAnswers = new List<Kinetics__Kinetic_Form_Answer__c>();
                for(Kinetics__Kinetic_Form_Answer__c answerRec : answers2Insert) {
                    String templateQuestionGUID = answerRec.Kinetics__Template_Question_UID__c;
                    if(templateQuestionGUID.indexOf('-child-') > 1) {
                        List<String> templateQuestionGUIDList = templateQuestionGUID.split('-child-');
                        if(templateQuestionGUIDList.size() > 1 
                            && answerIdMap.containsKey(templateQuestionGUIDList[0])) {
                                answerRec.Kinetics__Parent_Kinetic_Form_Answer__c = answerIdMap.get(templateQuestionGUIDList[0]);
                                // if(answerRecordById.containsKey(answerRec.Kinetics__Parent_Kinetic_Form_Answer__c)) {
                                //     String parentAnswerValue = answerRecordById.get(answerRec.Kinetics__Parent_Kinetic_Form_Answer__c).Kinetics__Answer__c;
                                //     answerRec.Kinetics__Required_Parent_Value__c = parentAnswerValue.subString(0,254);
                                // }
                                childAnswers.add(answerRec);
                        }
                    }
                }
                update childAnswers;
            }
            InspTemplateRendererController.moveToCompleteStatus(inspectionId);
           
            sRes.statusCode = '2000';
            sRes.responseMessage = 'Success';
            sRes.responseDetails = answerIdMap;
        }catch(Exception ex){
            sRes.statusCode = '2100';
            sRes.responseMessage = ex.getMessage();
            sRes.responseDetails = ex.getStackTraceString();
        }
        return JSON.serialize(sRes);
    }

    @AuraEnabled
    public static string linkAnswerToTasks(String answerIdByTemplateQuestionIdString, String taskIdsArrayBySurveyQuestionIdString){
        try {
            Map<String, String> answerIdByTemplateQuestionId = new Map<String, String>();
            Map<String, List<String>> taskIdsArrayBySurveyQuestionId = new Map<String, List<String>>();
            answerIdByTemplateQuestionId = (Map<String, String>) JSON.deserialize(answerIdByTemplateQuestionIdString, Map<String, String>.class);
            taskIdsArrayBySurveyQuestionId = (Map<String, List<String>>) JSON.deserialize(taskIdsArrayBySurveyQuestionIdString, Map<String, List<String>>.class);
            List<Task> tList = new List<Task>();
            for(String templateQuestionId: answerIdByTemplateQuestionId.keySet()) {
                String ansId = answerIdByTemplateQuestionId.get(templateQuestionId);
                if(taskIdsArrayBySurveyQuestionId.containsKey(templateQuestionId)) {
                    for(String taskId : taskIdsArrayBySurveyQuestionId.get(templateQuestionId)) {
                        Task t = new Task();
                        t.Id = taskId;
                        t.Kinetics__Template_Answer__c = ansId;
                        tList.add(t);
                    }
                }
            }
            if(tList.size() > 0) {
                update tList;
            }
            return 'Done';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string linkAnswerToNotes(String answerIdByTemplateQuestionIdString, String noteIdsArrayBySurveyQuestionIdString){
        try {
            Map<String, String> answerIdByTemplateQuestionId = new Map<String, String>();
            Map<String, List<String>> noteIdsArrayBySurveyQuestionId = new Map<String, List<String>>();
            answerIdByTemplateQuestionId = (Map<String, String>) JSON.deserialize(answerIdByTemplateQuestionIdString, Map<String, String>.class);
            noteIdsArrayBySurveyQuestionId = (Map<String, List<String>>) JSON.deserialize(noteIdsArrayBySurveyQuestionIdString, Map<String, List<String>>.class);
            List<String> noteIdList = new List<String>();
            for(List<String> noteIdLs: noteIdsArrayBySurveyQuestionId.values()) {
                noteIdList.addAll(noteIdLs);
            }
            if(noteIdList.size() == 0) {
                return 'Done';
            }
            List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
            Map<String, Map<String, String>> cdlIdByLinkedEntityIdByContentDocId = new Map<String, Map<String, String>>();
            for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId,ContentDocumentId 
                                            FROM ContentDocumentLink 
                                            WHERE ContentDocumentId IN :noteIdList]){
                Map<String, String> noteIdByEntityId = new Map<String, String>();
                if(cdlIdByLinkedEntityIdByContentDocId.containsKey(cdl.ContentDocumentId)){
                    noteIdByEntityId  = cdlIdByLinkedEntityIdByContentDocId.get(cdl.ContentDocumentId);
                }
                noteIdByEntityId.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                cdlIdByLinkedEntityIdByContentDocId.put(cdl.ContentDocumentId, noteIdByEntityId);        
            }

            for(String templateQId: answerIdByTemplateQuestionId.keySet()){
                String ansId = answerIdByTemplateQuestionId.get(templateQId);
                if(noteIdsArrayBySurveyQuestionId.containsKey(templateQId)) {
                    for(String noteId: noteIdsArrayBySurveyQuestionId.get(templateQId)){
                        if(cdlIdByLinkedEntityIdByContentDocId.containsKey(noteId)) {
                            Map<String, String> noteIdByEntityId  = cdlIdByLinkedEntityIdByContentDocId.get(noteId);
                            if(noteIdByEntityId.containsKey(ansId)) {
                                continue;
                            }
                            ContentDocumentLink objCntDocLink = new ContentDocumentLink();
                            objCntDocLink.LinkedEntityId = ansId; // Specify your parent Id 
                            objCntDocLink.ContentDocumentId = noteId;  //Content Note Id
                            objCntDocLink.shareType = 'V'; // Specify your sharing type 
                            contentDocumentLinkList.add(objCntDocLink);
                        }
                    }
                }
            }
            if(contentDocumentLinkList.size() > 0){
                insert contentDocumentLinkList;
            }
            return 'Done';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string updateStatusToInprogress(String inspRecId){
        try {
            List<Kinetics__Inspection__c> inspectionList = [SELECT Id, Name, Kinetics__Status__c
                                                            FROM Kinetics__Inspection__c 
                                                            WHERE Id =: inspRecId 
                                                            LIMIT 1];
            if(inspectionList.size() > 0) {
                inspectionList[0].Kinetics__Status__c = 'In Progress';
                update inspectionList;
            }
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getRelatedFieldInformation(String requiredInformationMapJSON){
        try {
            
            Map<String, String> requiredInformationMap = (Map<String, String>) JSON.deserialize(requiredInformationMapJSON, Map<String, String>.class);
            String relatedObjectName = requiredInformationMap.containsKey('relatedObjectName') ? requiredInformationMap.get('relatedObjectName') : null;
            String relatedObjectFieldName = requiredInformationMap.containsKey('relatedObjectFieldName') ? requiredInformationMap.get('relatedObjectFieldName') : null;
            String inspectionRecId = requiredInformationMap.containsKey('inspectionRecId') ? requiredInformationMap.get('inspectionRecId'): null;
            Map<String, String> valueByFieldName = new Map<String, String>();

            List<Kinetics__Inspection__c> inspectionRec = new List<Kinetics__Inspection__c>();
            if(String.isNotBlank(inspectionRecId)) {
                inspectionRec = [SELECT Id, Name, Kinetics__Account__c, Kinetics__Contact__c
                                    FROM Kinetics__Inspection__c 
                                    WHERE Id =:inspectionRecId LIMIT 1];
            }
            if(inspectionRec.size() ==0){
                return JSON.serialize(valueByFieldName);
            }

            List<sObject> relatedRecordList = new List<sObject>();

            //will need to change this as this is not supporting configurability
            String parentReferenceId = '';
             
            //here assuming that all the questions from same kineitc form should be related to only one reference object like contact, account, user, etc
            if(String.isNotBlank(relatedObjectName)) {
                Boolean isChildObjectRefered = false;
                if(relatedObjectName == 'Contact') {
                    parentReferenceId = inspectionRec[0].Kinetics__Contact__c;
                } else if(relatedObjectName == 'Account') {
                    parentReferenceId = inspectionRec[0].Kinetics__Account__c;
                } else if(relatedObjectName == 'Kinetics__Kinetic_Form_Answer__c' || relatedObjectName == 'SVMXC__Service_Order__c') {
                    parentReferenceId = null;
                    isChildObjectRefered = true;
                }
                 
                if(String.isNotBlank(parentReferenceId)) {
                    String queryString = ' SELECT Id, ' + relatedObjectFieldName 
                                             + ' FROM ' + relatedObjectName 
                                             + ' WHERE Id = :parentReferenceId ' ;
                    relatedRecordList = Database.query(queryString);
                }
                if(isChildObjectRefered) {
                    String queryString = ' SELECT Id, ' + relatedObjectFieldName 
                                             + ' FROM ' + relatedObjectName 
                                             + ' WHERE Inspection__c = :inspectionRecId ';
                    relatedRecordList = Database.query(queryString);
                }
                if(relatedRecordList.size() > 0 
                    && String.isNotBlank(relatedObjectFieldName)
                    && String.isNotBlank(String.valueOf(relatedRecordList[0].get(relatedObjectFieldName)))) {
                        valueByFieldName.put(relatedObjectFieldName, String.valueOf(relatedRecordList[0].get(relatedObjectFieldName)));
                }
            }
            return JSON.serialize(valueByFieldName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class inspTemplateAnswer{
        public String index;
        public String questionId;
        public String templateQuestionId;
        public String answer;
        public String questionDetails;
        public String fieldType;
        public String questionValues;
        public String inspectionId;
        public String inspectionTemplateId;
        public String templateId;
        public String existingAnswerId;
        public Integer scoreAttained;
        public Integer outOfScore;
        public String chatgptguidance;
    }
}