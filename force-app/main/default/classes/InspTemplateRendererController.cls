/**
 * Author: Shankar
 * Date: 06-06-2022
 * Purpose: Controller class to render the templates for Inspection
 */
public with sharing class InspTemplateRendererController {

        @AuraEnabled
        public static string getAllTemplatesDetailsByInspectionId(String inspectionId){
            InspTemplateResponse sRes = new InspTemplateResponse();
            system.debug('****** inspectionId=' + inspectionId);
            try {
                
                List<Kinetics__Inspection__c> inspectionRec = [SELECT Id, Name, Kinetics__Account__c, Kinetics__Contact__c 
                                                        FROM Kinetics__Inspection__c 
                                                        WHERE Id =:inspectionId LIMIT 1];
    
                Map<String, Object> responseObj = new Map<String, Object>();
                responseObj.put('inspectionTemplateList', null);
                responseObj.put('inspectionRec', inspectionRec.size() > 0? inspectionRec[0] : null);
    
                sRes.statusCode = '2000';
                sRes.responseMessage = 'Success';
                sRes.responseDetails = responseObj;
            } catch(Exception exc) {
                sRes.statusCode = '2100';
                sRes.responseMessage = exc.getMessage();
                sRes.responseDetails = null;
            }
            return JSON.serialize(sRes);
        }
    
        @AuraEnabled
        public static string updateInspectionToInprogress(String inspectionId){
            try {
                List<Kinetics__Inspection__c> inspectionRecList = [SELECT Id, Kinetics__Status__c FROM Kinetics__Inspection__c WHERE Id = :inspectionId LIMIT 1];
                if(inspectionRecList.size() > 0 && inspectionRecList[0].Kinetics__Status__c == 'Not Started'){
                    inspectionRecList[0].Kinetics__Status__c = 'In Progress';
                    upsert inspectionRecList;
                }
                return 'Done';
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }

        @AuraEnabled
        public static String getAllTemplateDetailsByInspectionId(String inspectionId, Boolean fetchAllQuestions){
            InspTemplateResponse sRes = new InspTemplateResponse();
            system.debug('****** inspectionId=' + inspectionId);
            try {
                
                List<Kinetics__Inspection__c> inspectionRec = [SELECT Id, Name, Kinetics__Account__c, Kinetics__Contact__c, Kinetics__Template__c, 
                                                        Kinetics__Template__r.Kinetics__Questions_By_Page_No__c, Kinetics__Template__r.Name ,
                                                        Kinetics__Template__r.Kinetics__Section_Metadata__c,
                                                        Kinetics__Template__r.Kinetics__Instructions__c
                                                        FROM Kinetics__Inspection__c 
                                                        WHERE Id =:inspectionId LIMIT 1];

                String templateId = inspectionRec.size() > 0 ? inspectionRec[0].Kinetics__Template__c: '';

                if(String.isBlank(templateId)) {
                    sRes.statusCode = '2100';
                    sRes.responseMessage = 'Template not found';
                    sRes.responseDetails = null;
                    return JSON.serialize(sRes);
                }
    
                List<Kinetics__Kinetic_Form_Question__c> templateQuestionList = 
                        [Select Id, 
                        Kinetics__Index__c, Kinetics__Question_Help_Text__c, Kinetics__Option_Score__c, Kinetics__Score_Confirmed__c,
                        Kinetics__Kinetic_Question__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Values__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Default_Value__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Field_Type__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Has_Followup_Questions__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Is_Photo_Mandatory__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Parent_Option_Value__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Parent_Question__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Question__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Status__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Take_Photo__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Custom_Question_Number__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Assign_Tasks__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Attach_Photos_or_Files__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Capture_Notes__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Related_To_Object__c,
                        Kinetics__Kinetic_Question__r.Show_Related_Info_In_Question_Text__c,
                        Kinetics__Kinetic_Question__r.Show_Related_Info_In_Answer_As_ReadOly__c,
                        Kinetics__Kinetic_Question__r.Show_Related_Info_As_a_Answer__c
                        From Kinetics__Kinetic_Form_Question__c 
                        Where Kinetics__Kinetic_Form__c = :templateId
                        Order By Kinetics__Index__c ASC];
    
                if(templateQuestionList.isEmpty()){
                    sRes.statusCode = '2100';
                    sRes.responseMessage = 'Template not found';
                    sRes.responseDetails = null;
                    return JSON.serialize(sRes);
                }
    
                List<Kinetics__Kinetic_Form_Answer__c> existingAnswerList = [SELECT Id, Kinetics__Answer__c, Kinetics__Kinetic_Question_Id__c, Kinetics__Score_Attained__c, Kinetics__Out_of_Score__c
                                                                                FROM Kinetics__Kinetic_Form_Answer__c
                                                                                WHERE Kinetics__Inspection__c IN :inspectionRec
                                                                                // AND Survey__c =: surveyId
                                                                                ];
                Map<String, Kinetics__Kinetic_Form_Answer__c> answerByQuestionId = new Map<String, Kinetics__Kinetic_Form_Answer__c>();
                Set<String> existingAnswerIdSet = new Set<String>();
                for(Kinetics__Kinetic_Form_Answer__c tsa: existingAnswerList) {
                    existingAnswerIdSet.add(tsa.Id);
                    answerByQuestionId.put(tsa.Kinetics__Kinetic_Question_Id__c, tsa);
                }
    
    
                // List<Task> taskList = [SELECT Id, WhatId FROM Task WHERE WhatId IN :existingAnswerList ];
                // Map<String, Integer> taskCountByAnswerId = new Map<String, Integer>();
                // for(Task t: taskList) {
                //     Integer count = 0;
                //     if(taskCountByAnswerId.containsKey(t.WhatId)) {
                //         count = taskCountByAnswerId.get(t.WhatId);
                //     }
                //     count = count + 1;
                //     taskCountByAnswerId.put(t.WhatId, count);
                // }
    
                // Map<String, String> contentDocumentIdByRecordId = new Map<String, String>();
                // Map<String, ContentNote> contentNoteByContentDocId = new Map<String, ContentNote>();
                // if(existingAnswerIdSet.size() > 0){
                //     for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId,ContentDocumentId 
                //                                     FROM ContentDocumentLink WHERE LinkedEntityId IN :existingAnswerIdSet]){
                //         contentDocumentIdByRecordId.put(cdl.LinkedEntityId, cdl.contentDocumentId);              
                //     }
                // }
                
                // for(ContentNote cn: [SELECT Id, Title, TextPreview FROM ContentNote WHERE Id IN :contentDocumentIdByRecordId.values()]){
                //     contentNoteByContentDocId.put(cn.Id, cn);
                // }


                 //changes started
                Map<String, Set<String>> fieldsByObjectName = new Map<String, Set<String>>();
                Map<String, String> fieldNameByQuestionId = new Map<String, String>();
                for(Kinetics__Kinetic_Form_Question__c sqDb: templateQuestionList){
                    if(String.isNotBlank(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_To_Object__c)
                    && String.isNotBlank(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c)) {
                        Set<String> fieldset = new Set<String>();
                        if(fieldsByObjectName.containsKey(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_To_Object__c)) {
                            fieldset = fieldsByObjectName.get(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_To_Object__c);
                        }
                        fieldset.add(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c);
                        fieldsByObjectName.put(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_To_Object__c, fieldset);
                        fieldNameByQuestionId.put(sqDb.Kinetics__Kinetic_Question__c, sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c);
                    }
                }
                List<sObject> relatedRecordList = new List<sObject>();

                //will need to change this as this is not supporting configurability
                String parentReferenceId = '';
                
                //here assuming that all the questions from same kineitc form should be related to only one reference object like contact, account, user, etc
                if(fieldsByObjectName.size() > 0 && fieldsByObjectName.size() == 1) {
                    List<String> objectNameSet = new List<String>(fieldsByObjectName.keySet());
                    Boolean isChildObjectRefered = false;
                    if(objectNameSet[0] == 'Contact') {
                        parentReferenceId = inspectionRec[0].Kinetics__Contact__c;
                    } else if(objectNameSet[0] == 'Account') {
                        parentReferenceId = inspectionRec[0].Kinetics__Account__c;
                    } else if(objectNameSet[0] == 'Kinetics__Kinetic_Form_Answer__c' || objectNameSet[0] == 'SVMXC__Service_Order__c') {
                        parentReferenceId = null;
                        isChildObjectRefered = true;
                    }
                    
                    if(String.isNotBlank(parentReferenceId)) {
                        String queryString = ' SELECT Id, ' + String.join(new List<String>(fieldsByObjectName.get(objectNameSet[0])), ',') 
                                                + ' FROM ' + objectNameSet[0] 
                                                + ' WHERE Id = :parentReferenceId ' ;
                        relatedRecordList = Database.query(queryString);
                    }
                    if(isChildObjectRefered) {
                        String inspectionRecId = inspectionRec[0].Id;
                        String queryString = ' SELECT Id, ' + String.join(new List<String>(fieldsByObjectName.get(objectNameSet[0])), ',') 
                                                + ' FROM ' + objectNameSet[0] 
                                                + ' WHERE Inspection__c = :inspectionRecId ';
                        relatedRecordList = Database.query(queryString);
                    }
                }

    
                List<templateQuestionWrapper> tempQuestionList = new List<templateQuestionWrapper>();
                Integer indexCount = 1;
                List<String> questionIdList = new List<String>();
                for(Kinetics__Kinetic_Form_Question__c sqDb: templateQuestionList){
                    if(!fetchAllQuestions 
                        && answerByQuestionId.containsKey(sqDb.Kinetics__Kinetic_Question__c) 
                        && String.isNotBlank(answerByQuestionId.get(sqDb.Kinetics__Kinetic_Question__c).Kinetics__Answer__c)) {
                        continue;
                    }
                    String extraInfoDisplayedWithQuestion = '';
                    if(sqDb.Kinetics__Kinetic_Question__r.Show_Related_Info_In_Question_Text__c && relatedRecordList.size() > 0 
                        && String.isNotBlank(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c)
                        && String.isNotBlank(String.valueOf(relatedRecordList[0].get(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c)))) {
                        extraInfoDisplayedWithQuestion = ' ' + String.valueOf(relatedRecordList[0].get(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c));
                      
                    }
                    
                    templateQuestionWrapper sqObj = new templateQuestionWrapper();
                    sqObj.index = sqDb.Kinetics__Index__c;
                    sqObj.helpText = sqDb.Kinetics__Question_Help_Text__c;
                    sqObj.fieldType = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Field_Type__c;
                    sqObj.questionDetails = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Question__c + extraInfoDisplayedWithQuestion;
                    sqObj.questionId = sqDb.Kinetics__Kinetic_Question__c;
                    sqObj.templateQuestionId = sqDb.Id;
                    sqObj.questionValues = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Values__c;
                    sqObj.displayIndex = indexCount++;
                    sqObj.totalNumberOfTasksCreated = 0;
                    sqObj.totalNumberOfNotesCreated = 0;
                    sqObj.totalNumberOfFilesUploaded = 0;
                    sqObj.scoreByOption = sqDb.Kinetics__Option_Score__c;
                    sqObj.scoreConfirmed = sqDb.Kinetics__Score_Confirmed__c != null ? Boolean.valueOf(sqDb.Kinetics__Score_Confirmed__c): false;
                    sqObj.assignTaskEnabled =  sqDb.Kinetics__Kinetic_Question__r.Kinetics__Assign_Tasks__c;
                    sqObj.attachPhotoEnabled = (sqDb.Kinetics__Kinetic_Question__r.Kinetics__Attach_Photos_or_Files__c && !sqObj.fieldType.equalsIgnoreCase('file'));
                    sqObj.captureNotesEnabled = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Capture_Notes__c;
                    sqObj.defaultValue = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Default_Value__c;
                    sqObj.markAnswerReadOnly = sqDb.Kinetics__Kinetic_Question__r.Show_Related_Info_In_Answer_As_ReadOly__c;

                    //sqObj.noteId = null;
                    //sqObj.shortNoteDescription = null;
    
                    //changes started
                    if(sqDb.Kinetics__Kinetic_Question__r.Show_Related_Info_As_a_Answer__c
                        && relatedRecordList.size() > 0 
                        && String.isNotBlank(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c)
                        && String.isNotBlank(String.valueOf(relatedRecordList[0].get(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c)))) {
                        sqObj.defaultValue = String.valueOf(relatedRecordList[0].get(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c));
                        sqObj.answer = sqObj.defaultValue == null ? '': sqObj.defaultValue;
                    }
                
                    if(answerByQuestionId.containsKey(sqObj.questionId)){
                        Kinetics__Kinetic_Form_Answer__c tsaRec = answerByQuestionId.get(sqObj.questionId);
                        if(String.isNotBlank(tsaRec.Kinetics__Answer__c)){
                            sqObj.answer = tsaRec.Kinetics__Answer__c;
                        }
                        sqObj.existingAnswerId = tsaRec.Id;
                        sqObj.scoreAttained = tsaRec.Kinetics__Score_Attained__c != null ? Integer.valueOf(tsaRec.Kinetics__Score_Attained__c): 0;
                        sqObj.outOfScore = tsaRec.Kinetics__Out_of_Score__c != null ? Integer.valueOf(tsaRec.Kinetics__Out_of_Score__c) : 0;
                        //sqObj.totalNumberOfTasksCreated = taskCountByAnswerId.containsKey(tsaRec.Id) ? taskCountByAnswerId.get(tsaRec.Id) : 0;
    
                        // if(contentDocumentIdByRecordId.containsKey(tsaRec.Id)) {
                        //     String contentDocId = contentDocumentIdByRecordId.get(tsaRec.Id);
                        //     sqObj.noteId = contentDocId;
                        //     sqObj.totalNumberOfNotesCreated = contentDocId != null? 1 : 0;
                        //     // if(contentNoteByContentDocId.containsKey(contentDocId)) {
                        //     //     sqObj.noteId = contentNoteByContentDocId.get(contentDocId).Id;
                        //     //     sqObj.shortNoteDescription = contentNoteByContentDocId.get(contentDocId).TextPreview;
                        //     // }
                        // }
                    }
                    questionIdList.add(sqDb.Kinetics__Kinetic_Question__c);

                    Integer maxScoreForQuestion = 0;
                    if(sqObj.scoreConfirmed == true 
                        && String.isNotBlank(sqObj.scoreByOption)){
                        Map<String, Integer> scoreByOptionValue = (Map<String, Integer>) JSON.deserialize(sqObj.scoreByOption, Map<String, Integer>.class);
                       
                        for(String option: scoreByOptionValue.keySet()) {
                            if(maxScoreForQuestion < scoreByOptionValue.get(option)) {
                                maxScoreForQuestion = scoreByOptionValue.get(option);
                            }
                        }
                      //  totalAvailableScore = totalAvailableScore + maxScoreForQuestion;
                    }
                    sqObj.outOfScore = (sqObj.outOfScore != null 
                                            && sqObj.outOfScore != 0 
                                            && sqObj.outOfScore == maxScoreForQuestion) ? sqObj.outOfScore : maxScoreForQuestion;


                    tempQuestionList.add(sqObj);
                }
                Map<String, List<parentRelatedRecordDetails>> parentRecordIdByFieldNameByQuestionId = collectInformationAboutParentRecords(questionIdList);
                for(templateQuestionWrapper tw: tempQuestionList) {
                    tw.parentRelatedRecordDetailsList = new List<parentRelatedRecordDetails>();
                    if(parentRecordIdByFieldNameByQuestionId.containsKey(tw.questionId)) {
                        tw.parentRelatedRecordDetailsList = parentRecordIdByFieldNameByQuestionId.get(tw.questionId);
                    }
                }

                Map<String, Object> responseObj = new Map<String, Object>();
                responseObj.put('tempQuestionList', tempQuestionList);
                responseObj.put('inspectionRec', inspectionRec.size() > 0? inspectionRec[0] : null);
                responseObj.put('parentRecordIdByFieldNameByQuestionId', parentRecordIdByFieldNameByQuestionId);
    
                sRes.statusCode = '2000';
                sRes.responseMessage = 'Success';
                sRes.responseDetails = responseObj;
            } catch(Exception exc) {
                sRes.statusCode = '2100';
                sRes.responseMessage = exc.getMessage();
                sRes.responseDetails = null;
            }
            return JSON.serialize(sRes);
        }
    
        @AuraEnabled
        public static string shareNoteRecord(Map<String, List<String>> shareWithIdListByNoteId ){
            try {
                List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
                Map<String, Map<String, String>> cdlIdByLinkedEntityIdByContentDocId = new Map<String, Map<String, String>>();
                for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId,ContentDocumentId 
                    FROM ContentDocumentLink WHERE ContentDocumentId IN :shareWithIdListByNoteId.keySet()]){
                    Map<String, String> noteIdByEntityId = new Map<String, String>();
                    if(cdlIdByLinkedEntityIdByContentDocId.containsKey(cdl.ContentDocumentId)){
                        noteIdByEntityId  = cdlIdByLinkedEntityIdByContentDocId.get(cdl.ContentDocumentId);
                    }
                    noteIdByEntityId.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                    cdlIdByLinkedEntityIdByContentDocId.put(cdl.ContentDocumentId, noteIdByEntityId);        
                }
    
                for(String noteId: shareWithIdListByNoteId.keySet()){
                    for(String shareWithId : shareWithIdListByNoteId.get(noteId)) {
                        if(cdlIdByLinkedEntityIdByContentDocId.containsKey(noteId)) {
                            Map<String, String> noteIdByEntityId  = cdlIdByLinkedEntityIdByContentDocId.get(noteId);
                            if(noteIdByEntityId.containsKey(shareWithId)) {
                                continue;
                            }
                        }
                        ContentDocumentLink objCntDocLink = new ContentDocumentLink();
                        objCntDocLink.LinkedEntityId = shareWithId; // Specify your parent Id 
                        objCntDocLink.ContentDocumentId = noteId;  //Content Note Id
                        objCntDocLink.shareType = 'V'; // Specify your sharing type 
                        contentDocumentLinkList.add(objCntDocLink);
                    }
                }
                insert contentDocumentLinkList;
                return 'Done';
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    
        @AuraEnabled
        public static string createTaskRecord(String taskRecordJSON){
            try {
                if(String.isEmpty(taskRecordJSON)) {
                    return '';
                }
                List<Task> tlist = (List<Task>) JSON.deserialize(taskRecordJSON, List<Task>.class);
    
                upsert tlist;
                return JSON.serialize(tlist);
                
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    
        @AuraEnabled
        public static string updateTaskRecord(Map<String,List<String>> tasksRecordIdListByAnswerId){
            try {
                List<Task> tList = new List<Task>();
                for(String answerId : tasksRecordIdListByAnswerId.keySet()) {
                    for(String taskId: tasksRecordIdListByAnswerId.get(answerId)){
                        Task t = new Task(Id =taskId, WhatId = answerId);
                        tList.add(t);
                    }
                }
                update tList;
                return 'Done';
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
        @AuraEnabled
        public static String saveAnswers(String answerJsonString){
            system.debug('***** answerJsonString=' + answerJsonString);
            InspTemplateResponse sRes = new InspTemplateResponse();
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
    
                    answer2Commit.Kinetics__Answer_Index__c = Decimal.valueOf(answer.index);
                    answer2Commit.Kinetics__Kinetic_Question__c = answer.questionDetails;
                    answer2Commit.Kinetics__Kinetic_Question_Values__c = answer.questionValues;
                    answer2Commit.Kinetics__Kinetic_Form_Question__c = templateQuestionId;
                    answer2Commit.Kinetics__Type__c = answer.fieldType;
                    answer2Commit.Kinetics__Answer__c = answer.answer;
                    answer2Commit.Kinetics__Kinetic_Question_Id__c = answer.questionId;
                    answer2Commit.Kinetics__Inspection__c = answer.inspectionId;
                    answer2Commit.Kinetics__Score_Attained__c = answer.scoreAttained;
                    answer2Commit.Kinetics__Out_of_Score__c = answer.outOfScore;

                    inspectionId = answer2Commit.Kinetics__Inspection__c;

                    //answer2Commit.Survey__c = answer.surveyId;
                    
                    answers2Insert.add(answer2Commit);
                    questionIdMap.put(answer.questionId, templateQuestionId);
    
                    //generated for checking if all questions are answered
                    answerByTemplateQuestionId.put(templateQuestionId, answer2Commit);
                }
    
                Map<String, String> answerIdMap = new Map<String, String>();
                if(!answers2Insert.isEmpty()){
                    upsert answers2Insert;
                    
                    moveToCompleteStatus(inspectionId);
                    for(Kinetics__Kinetic_Form_Answer__c templateAnswer: answers2Insert){
                        String templateQuestionId = questionIdMap.get(templateAnswer.Kinetics__Kinetic_Question_Id__c);
                        answerIdMap.put(templateQuestionId, templateAnswer.Id);
                    }
                }
               
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

        public static void moveToCompleteStatus(String inspectionId) {
            List<Kinetics__Kinetic_Form_Answer__c> allAnswerList = [SELECT Id, Kinetics__Answer__c, Kinetics__Kinetic_Question_Id__c,
                                                                    Kinetics__Parent_Kinetic_Form_Answer__c,Kinetics__Parent_Kinetic_Form_Answer__r.Kinetics__Answer__c,
                                                                    Kinetics__Required_Parent_Value__c
                                                                    FROM Kinetics__Kinetic_Form_Answer__c
                                                                    WHERE Kinetics__Inspection__c = :inspectionId];
            Boolean questionNotAnswered = false;
            Integer totalQuestionsAnswered = 0;
            List<Kinetics__Kinetic_Form_Answer__c> answersToDelete = new List<Kinetics__Kinetic_Form_Answer__c>();
            for(Kinetics__Kinetic_Form_Answer__c kfa: allAnswerList) {
                if(String.isNotBlank(kfa.Kinetics__Parent_Kinetic_Form_Answer__c)
                    && String.isNotBlank(kfa.Kinetics__Parent_Kinetic_Form_Answer__r.Kinetics__Answer__c)
                    && kfa.Kinetics__Parent_Kinetic_Form_Answer__r.Kinetics__Answer__c != kfa.Kinetics__Required_Parent_Value__c) {
                        answersToDelete.add(kfa);
                        continue;
                }
                    
                if(String.isBlank(kfa.Kinetics__Answer__c)) {
                    questionNotAnswered = true;
                }
                if(String.isNotBlank(kfa.Kinetics__Answer__c)) {
                    totalQuestionsAnswered = totalQuestionsAnswered + 1;
                }
            }
            delete answersToDelete;
            List<Kinetics__Inspection__c> inspectionRecList = [SELECT Id, Kinetics__Status__c, Kinetics__Answered_Questions__c 
                                                            FROM Kinetics__Inspection__c WHERE Id = :inspectionId LIMIT 1];
            if(inspectionRecList.size() > 0){
                if(questionNotAnswered == false && (inspectionRecList[0].Kinetics__Status__c == 'In Progress' || inspectionRecList[0].Kinetics__Status__c == 'Not Started')) {    
                    inspectionRecList[0].Kinetics__Status__c = 'Complete';
                }
                inspectionRecList[0].Kinetics__Answered_Questions__c = totalQuestionsAnswered;
                upsert inspectionRecList;
            }
        }
    
        @AuraEnabled                            
        public static Id saveTheChunkFile(Id inspectionId, String templateAnswerId, String fileName, String base64Data, String contentType, String fileId){
            
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            if ( String.isBlank(fileId) ) {
                fileId = saveFiles(inspectionId, templateAnswerId, fileName, base64Data );
            } else {
                appendToFile(fileId, base64Data);
            }
    
            return Id.valueOf(fileId);
        }
    
        //used to save the contentVersion and create Content document Link
        private static Id saveFiles(Id inspectionId, String templateAnswerId, String fileName, String base64Data )  { 
            
            ContentVersion contentToInsert =new ContentVersion(); 
            contentToInsert.Title =fileName; 
            contentToInsert.VersionData=EncodingUtil.base64Decode(base64Data);
            contentToInsert.PathOnClient='/' + fileName ;
            contentToInsert.IsMajorVersion = false;
            //do not remove/change the description value because there is chcekc on that in the craveable org, atleast keep 'kinetic' in the description field
            // contentToInsert.Description = ': Created for Kinetic Form Link answers';
            
            insert contentToInsert;
            
            contentToInsert = [select id, ContentDocumentId from ContentVersion WHERE Id =: contentToInsert.Id];
            ContentDocumentLink cl = new ContentDocumentLink();
            cl.ContentDocumentId = contentToInsert.ContentDocumentId;
            cl.LinkedEntityId = templateAnswerId;
            cl.ShareType = 'V';
            cl.Visibility = 'AllUsers';
            insert cl;
    
            ContentDocumentLink cl1 = new ContentDocumentLink();
            cl1.ContentDocumentId = contentToInsert.ContentDocumentId;
            cl1.LinkedEntityId = inspectionId;
            cl1.ShareType = 'V';
            cl1.Visibility = 'AllUsers';
            insert cl1;
            
            
            return contentToInsert.id;
        }
    
        //used to update add append the contentVersion
        private static void appendToFile(Id contentDocumentId, String base64Data) {
            
            
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            ContentVersion versionData = [
                SELECT Id, VersionData
                FROM ContentVersion
                WHERE Id = :contentDocumentId
            ];
    
            String existingBody     = EncodingUtil.base64Encode(versionData.VersionData);
            versionData.VersionData = EncodingUtil.base64Decode(existingBody + base64Data);
            update versionData;
        }

        @InvocableMethod(label='Create Answers For Template On Inspection' description='Create Answers For Template On Inspection')
        public static void createAnswer(List<Id> inspectionRecList) {
            
            List<Kinetics__Kinetic_Form_Answer__c> answers2Insert = new List<Kinetics__Kinetic_Form_Answer__c>();
            List<Kinetics__Inspection__c> inspectionRecListLocal = [SELECT Id, Kinetics__Available_Score__c, Kinetics__Status__c,Kinetics__Template__c,
                                                                    Kinetics__Template__r.Kinetics__Template_Metadata__c
                                                                        FROM Kinetics__Inspection__c 
                                                                        WHERE ID IN :inspectionRecList];

            for(Kinetics__Inspection__c inspectionRec : inspectionRecListLocal) {
                if(inspectionRec.Kinetics__Status__c != 'Not Started') {
                    continue;
                }
     
                if(String.isBlank(inspectionRec.Kinetics__Template__c)) {
                    continue;
                }
                
                String inspectionId = inspectionRec.id;
                String templateId = inspectionRec.Kinetics__Template__c;
                if(String.isNotBlank(inspectionRec.Kinetics__Template__r.Kinetics__Template_Metadata__c)) {
                    TbInspTemplateQuestionRendererController.createAnswersForJSONBasedTemplate(inspectionId, inspectionRec.Kinetics__Template__r.Kinetics__Template_Metadata__c);
                    continue;
                }

                List<Kinetics__Kinetic_Form_Question__c> templateQuestionList = 
                        [Select Id,
                        Kinetics__Index__c, Kinetics__Question_Help_Text__c,
                        Kinetics__Option_Score__c, Kinetics__Score_Confirmed__c,
                        Kinetics__Kinetic_Question__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Values__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Default_Value__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Field_Type__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Has_Followup_Questions__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Is_Photo_Mandatory__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Parent_Option_Value__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Parent_Question__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Question__c, 
                        Kinetics__Kinetic_Question__r.Kinetics__Status__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Take_Photo__c,
                        Kinetics__Kinetic_Question__r.Kinetics__Custom_Question_Number__c 
                        From Kinetics__Kinetic_Form_Question__c 
                        Where Kinetics__Kinetic_Form__c = :templateId
                        Order By Kinetics__Index__c ASC];

                List<Kinetics__Kinetic_Form_Answer__c> existingAnswerList = [SELECT Id, Kinetics__Answer__c, Kinetics__Kinetic_Question_Id__c
                                                                                FROM Kinetics__Kinetic_Form_Answer__c
                                                                                WHERE Kinetics__Inspection__c = :inspectionId
                                                                                ];
                delete existingAnswerList;

                
                Integer totalAvailableScore = 0;
                for(Kinetics__Kinetic_Form_Question__c kfq: templateQuestionList) {
                    Kinetics__Kinetic_Form_Answer__c answer2Commit = new Kinetics__Kinetic_Form_Answer__c();
                    answer2Commit.Kinetics__Answer_Index__c = kfq.Kinetics__Index__c;
                    answer2Commit.Kinetics__Kinetic_Question__c = kfq.Kinetics__Kinetic_Question__r.Kinetics__Question__c;
                    answer2Commit.Kinetics__Kinetic_Question_Values__c = kfq.Kinetics__Kinetic_Question__r.Kinetics__Values__c;
                    answer2Commit.Kinetics__Kinetic_Form_Question__c = kfq.Id;
                    answer2Commit.Kinetics__Type__c = kfq.Kinetics__Kinetic_Question__r.Kinetics__Field_Type__c;
                    answer2Commit.Kinetics__Answer__c = '';
                    answer2Commit.Kinetics__Kinetic_Question_Id__c = kfq.Kinetics__Kinetic_Question__c;
                    answer2Commit.Kinetics__Inspection__c = inspectionId;
                    
                    Integer maxScoreForQuestion = 0;
                    if(kfq.Kinetics__Score_Confirmed__c == true && String.isNotBlank(kfq.Kinetics__Option_Score__c)){
                        Map<String, Integer> scoreByOptionValue = (Map<String, Integer>) JSON.deserialize(kfq.Kinetics__Option_Score__c, Map<String, Integer>.class);
                       
                        for(String option: scoreByOptionValue.keySet()) {
                            if(maxScoreForQuestion < scoreByOptionValue.get(option)) {
                                maxScoreForQuestion = scoreByOptionValue.get(option);
                            }
                        }
                        totalAvailableScore = totalAvailableScore + maxScoreForQuestion;
                    }
                    answer2Commit.Kinetics__Out_of_Score__c = maxScoreForQuestion;
                    answers2Insert.add(answer2Commit);
                }
                inspectionRec.Kinetics__Available_Score__c = totalAvailableScore;
            }

            insert answers2Insert;
            update inspectionRecListLocal;
        }
        
        @TestVisible
        private static Map<String, List<parentRelatedRecordDetails>> collectInformationAboutParentRecords(List<String> questionIdList) {
            Map<String, List<parentRelatedRecordDetails>> parentRecordIdByFieldNameByQuestionId = new Map<String, List<parentRelatedRecordDetails>>();

            String commaSeparatedFieldNamesForParentObjects = GlobalUtility.getParentRelatedFieldName();

            List<String> fieldNameList = new List<String>();
            if(commaSeparatedFieldNamesForParentObjects != null) {
                fieldNameList = commaSeparatedFieldNamesForParentObjects.split(',');
            }
            if(fieldNameList.size() == 0) {
                return parentRecordIdByFieldNameByQuestionId;
            }
            Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Kinetics__Kinetic_Question__c.fields.getMap();
            List<String> validFieldNames = new List<String>();
            Set<String> validFieldNameSet = new Set<String>();
            Map<String, String> objectNameByFieldName = new Map<String, String>();
            Map<String, String> referenceNameByFieldName = new Map<String, String>();
            for(String fName: fieldNameList) {
                if(fieldsMap.containsKey(fName)) {
                    Schema.DescribeFieldResult fdescribe = fieldsMap.get(fName).getDescribe();
                    Schema.DisplayType lfielddataType = fdescribe.getType();
                    if(lfielddataType.name().equalsIgnoreCase('Reference')) {
                        for(Schema.SObjectType reference : fdescribe.getReferenceTo()) {
                            validFieldNameSet.add(fName);
                            objectNameByFieldName.put(fName, reference.getDescribe().getName());
                            String referenceFieldName = '';
                            // Added below for loop to handle name field unavailability on referenced object
                            for(Schema.sObjectType sObj : fdescribe.getReferenceTo()) {
                                Schema.DescribeSobjectResult objResult1 = sObj.getDescribe();
                                // allow only to Accessible objects
                                if(objResult1.isAccessible() && (!objResult1.getName().equalsIgnoreCase('Case'))) {
                                    Map<String, Schema.SObjectField> fieldMap1 = objResult1.fields.getMap();
                                    if(fieldMap1.keySet().contains('name') || fieldMap1.keySet().contains('Name') || fieldMap1.keySet().contains('NAME')){
                                        referenceNameByFieldName.put(fName, fdescribe.getRelationshipName().toLowerCase() + '.name');
                                    } else if(fieldMap1.keySet().contains('title') || fieldMap1.keySet().contains('Title') || fieldMap1.keySet().contains('TITLE')){
                                        referenceNameByFieldName.put(fName, fdescribe.getRelationshipName().toLowerCase() + '.title');
                                    }
                                } else if(objResult1.isAccessible() && objResult1.getName().equalsIgnoreCase('Case') ) {
                                    referenceNameByFieldName.put(fName, fdescribe.getRelationshipName().toLowerCase() + '.casenumber');
                                }
                            }

                            break;
                        }
                    }
                }
            }

            validFieldNames.addAll(validFieldNameSet);
            if(validFieldNames.size() == 0) {
                return parentRecordIdByFieldNameByQuestionId;
            }
            

            String queryString = 'SELECT Id, ' + String.join(validFieldNames, ',');
            if(referenceNameByFieldName.size() > 0){
                queryString = queryString + ',' + String.join(referenceNameByFieldName.values(), ',');
            }
            queryString = queryString + ' FROM Kinetics__Kinetic_Question__c WHERE ID IN :questionIdList ';
            List<sObject> questionRecordList = Database.query(queryString);

            for(sObject queRec : questionRecordList) {
                List<parentRelatedRecordDetails> parentRelatedRecordDetailsList = new List<parentRelatedRecordDetails>();
                for(String vfName: validFieldNames) {
                    if(String.isNotBlank(String.valueOf(queRec.get(vfName)))) {
                        parentRelatedRecordDetails prelatedWrapper = new parentRelatedRecordDetails();
                        prelatedWrapper.parentObjectName = objectNameByFieldName.containsKey(vfName) ? objectNameByFieldName.get(vfName) : '';
                        prelatedWrapper.parentRecordId = String.valueOf(queRec.get(vfName));
                        prelatedWrapper.parentReferenceFieldName = vfName;
                        prelatedWrapper.questionId = String.valueOf(queRec.get('Id'));

                        if(referenceNameByFieldName.containsKey(vfName)) {
                            String path = referenceNameByFieldName.get(vfName);
                            List<String> pathParts = path.split('\\.'); // Regex needs escaping
                            sObject record = queRec;
                            while(pathParts.size() > 1 && record != null) {
                                record = record.getSObject(pathParts.remove(0));
                            }
                            Object result = record?.get(pathParts[0]);
                            if(result == null) {
                                result = '';
                            }

                            prelatedWrapper.parentRecordName = String.valueOf(result);
                        }
                        parentRelatedRecordDetailsList.add(prelatedWrapper);
                    }
                }
                parentRecordIdByFieldNameByQuestionId.put(String.valueOf(queRec.get('Id')), parentRelatedRecordDetailsList);
            }
            return parentRecordIdByFieldNameByQuestionId;
        }

        public class templateQuestionWrapper { 
            //public String templateName;
            public String questionDetails;
            public String helpText;
            public String fieldType;
            public String questionId;
            public String templateQuestionId;
            public Decimal index;
            public Decimal displayIndex;
            public String questionValues;
            public String answer;
            public String defaultValue;
            public Integer totalNumberOfTasksCreated;
            public Integer totalNumberOfNotesCreated;
            public Integer totalNumberOfFilesUploaded;
            //public String noteId;
            //public String shortNoteDescription;
            public String existingAnswerId;
            public String scoreByOption;
            public Boolean scoreConfirmed;
            public Integer scoreAttained;
            public Integer outOfScore;
            public Boolean assignTaskEnabled;
            public Boolean attachPhotoEnabled;
            public Boolean captureNotesEnabled;
            public Boolean markAnswerReadOnly;
            public List<parentRelatedRecordDetails> parentRelatedRecordDetailsList;
        }
    
        public class InspTemplateResponse{
            public String statusCode;
            public String responseMessage;
            public Object responseDetails;
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
        }

        public class parentRelatedRecordDetails {
            @AuraEnabled
            public String parentObjectName;
            @AuraEnabled
            public String parentRecordId;
            @AuraEnabled
            public String parentReferenceFieldName;
            @AuraEnabled
            public String questionId;
            @AuraEnabled
            public String parentRecordName;
        }
    }