/**
 * Author: Shankar Dupade (FieldKo)
 * Date: 15 Nov 2021
 * Purpose: Hellper class to handle Guest user operations
 */
public without sharing class GuestUserHandlerHelper {
    
    //used to save the contentVersion and create Content document Link
    public static Id saveFiles(Id recordId, String surveyAnswerId, String fileName, String base64Data )  { 
        List<Schema.DescribeFieldResult> contentversionFieldList = new List<Schema.DescribeFieldResult>{
            ContentVersion.Title.getDescribe(),
            ContentVersion.VersionData.getDescribe(),
            ContentVersion.PathOnClient.getDescribe(),
            ContentVersion.IsMajorVersion.getDescribe(),
            ContentVersion.Description.getDescribe(),
            ContentVersion.Kinetics__Kinetic_Form_Answer__c.getDescribe()
        };

        List<Schema.DescribeFieldResult> contentDocumentLinkFieldList = new List<Schema.DescribeFieldResult>{
            ContentDocumentLink.ContentDocumentId.getDescribe(),
            ContentDocumentLink.LinkedEntityId.getDescribe(),
            ContentDocumentLink.ShareType.getDescribe(),
            ContentDocumentLink.Visibility.getDescribe()
        };
        
        if(!(CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.ContentVersion)
            && CheckUserPermission.checkFieldsCreateAccess(contentversionFieldList)
            && CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.ContentDocumentLink)
            && CheckUserPermission.checkFieldsCreateAccess(contentDocumentLinkFieldList))) {
            throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);  
        }

        ContentVersion contentToInsert =new ContentVersion(); 
        contentToInsert.Title =fileName; 
        contentToInsert.VersionData=EncodingUtil.base64Decode(base64Data);
        contentToInsert.PathOnClient='/' + fileName ;
        contentToInsert.IsMajorVersion = false;
        //do not remove/change the description value because there is chcekc on that in the craveable org, atleast keep 'kinetic' in the description field
        contentToInsert.Description = 'Kinetic: Created for Kinetic Form Link answers';
        contentToInsert.Kinetics__Kinetic_Form_Answer__c = surveyAnswerId;
        insert contentToInsert;
        
        contentToInsert = [select id, ContentDocumentId from ContentVersion WHERE Id =: contentToInsert.Id];
        ContentDocumentLink cl = new ContentDocumentLink();
        cl.ContentDocumentId = contentToInsert.ContentDocumentId;
        cl.LinkedEntityId = recordId;
        cl.ShareType = 'V';
        cl.Visibility = 'AllUsers';
        insert cl;
        
        return contentToInsert.id;
    }

    //used to update add append the contentVersion
    public static void appendToFile(Id contentDocumentId, String base64Data) {
        
        List<Schema.DescribeFieldResult> contentversionFieldList = new List<Schema.DescribeFieldResult>{
            ContentVersion.VersionData.getDescribe()
        };
        
        if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.ContentVersion)
            && CheckUserPermission.checkFieldsReadAccess(contentversionFieldList)
            && CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.ContentVersion)
            && CheckUserPermission.checkFieldsUpdateAccess(contentversionFieldList))) {
            throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);  
        }
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

    //used to update file Id and URL on Kinetic Form Answer record
    public static void updateKineticFormAnswers(Map<Id,Id> contentVersionIdByAnswerRecId) {
        // List<Schema.DescribeFieldResult> kineticformanswerFieldList = new List<Schema.DescribeFieldResult>{
        //     Kinetics__Kinetic_Form_Answer__c.Kinetics__File_Ids__c.getDescribe(),
        //     Kinetics__Kinetic_Form_Answer__c.Kinetics__Attachment_URL__c.getDescribe(),
        //     Kinetics__Kinetic_Form_Answer__c.Kinetics__Attachment__c.getDescribe()
        // };

        List<Kinetics__Kinetic_Form_Answer__c> kineticFormAnswerRecToUpdate = new List<Kinetics__Kinetic_Form_Answer__c>();
        Map<Id,Kinetics__Kinetic_Form_Answer__c> kineticFormAnswerRecMap = new Map<Id,Kinetics__Kinetic_Form_Answer__c>([SELECT Id, Kinetics__Attachment_URL__c, 
                                            Kinetics__File_Ids__c, Kinetics__Attachment__c
                                          FROM Kinetics__Kinetic_Form_Answer__c 
                                          WHERE Id IN :contentVersionIdByAnswerRecId.keySet()]);

        for(Kinetics__Kinetic_Form_Answer__c kfAnswerRec : kineticFormAnswerRecMap.values()) {
            kfAnswerRec.Kinetics__File_Ids__c = '';
            Id fileId = contentVersionIdByAnswerRecId.get(kfAnswerRec.Id);
            kfAnswerRec.Kinetics__Attachment_URL__c = '/sfc/servlet.shepherd/version/download/' + fileId;
            kfAnswerRec.Kinetics__Attachment__c = true;
            kfAnswerRec.Kinetics__File_Ids__c = fileId;
            kineticFormAnswerRecToUpdate.add(kfAnswerRec);
        }

        // if(CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Answer__c)
        //     && CheckUserPermission.checkFieldsUpdateAccess(kineticformanswerFieldList)) {
           
            if(!kineticFormAnswerRecToUpdate.isEmpty()) {
                update kineticFormAnswerRecToUpdate;
            }
       // }
    }
    
    public static String getSequenceBySurveyGuid(String surveyGUID){
        SeqRendererController.SeqResponse sRes = new SeqRendererController.SeqResponse();
        system.debug('****** surveyGUID=' + surveyGUID);
        try{
            List<Schema.DescribeFieldResult> surveyInvitationFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Survey_Invitation__c.Kinetics__GUID__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Stage__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Form__c.getDescribe()
            };
            List<Schema.DescribeFieldResult> kineticFormFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Kinetic_Form_Question__c.Kinetics__Index__c.getDescribe(),
                Kinetics__Kinetic_Form_Question__c.Kinetics__Question_Help_Text__c.getDescribe(),
                Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Question__c.getDescribe(),
                Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Form__c.getDescribe()
            };
            if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
                && CheckUserPermission.checkFieldsReadAccess(surveyInvitationFieldList)
                && CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Question__c) 
                && CheckUserPermission.checkFieldsReadAccess(kineticFormFieldList))) {
                    throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
            }
            List<Kinetics__Survey_Invitation__c> invites = [Select Id, Kinetics__Kinetic_Form__c, Kinetics__Kinetic_Form__r.Kinetics__Template_Metadata__c, Kinetics__Stage__c, 
                                                                    Kinetics__Contact__c, Kinetics__Recipient_Name__c, Kinetics__Recipient_Last_Name__c, Kinetics__Recipient_Email__c,Kinetics__Recipient_Number__c,
                                                                    Kinetics__Contact__r.AccountId  
                                                            From Kinetics__Survey_Invitation__c 
                                                            Where Kinetics__GUID__c =: surveyGUID];
            
            if(invites.isEmpty()){
                sRes.statusCode = '2100';
                sRes.responseMessage = GlobalConstants.surveyNotFoundMessage;
                sRes.responseDetails = null;
                return JSON.serialize(sRes);
            }

            Kinetics__Survey_Invitation__c invite = invites.get(0);
            if(invite.Kinetics__Stage__c == GlobalConstants.expiredStage){
                sRes.statusCode = '2100';
                sRes.responseMessage = GlobalConstants.surveyExpiredMessage;
                sRes.responseDetails = null;
                return JSON.serialize(sRes);
            }else if(invite.Kinetics__Stage__c == GlobalConstants.completedStage){
                sRes.statusCode = '2100';
                sRes.responseMessage = GlobalConstants.surveyCompletedMessage;
                sRes.responseDetails = null;
                return JSON.serialize(sRes);
            }

            if(String.isNotBlank(invite.Kinetics__Kinetic_Form__r.Kinetics__Template_Metadata__c)){
                return getSequenceBySurveyGuidForJSONBasedTemplate(surveyGUID);
            }
            List<Kinetics__Kinetic_Form_Question__c> surveyQuestionList = 
                    [Select Kinetics__Kinetic_Form__r.Name ,
                    Kinetics__Kinetic_Form__r.Kinetics__Instructions__c,  
                    Kinetics__Index__c,
                    Kinetics__Question_Help_Text__c,
                    Kinetics__Kinetic_Question__c,
                    Kinetics__Score_Confirmed__c, Kinetics__Option_Score__c,
                    Kinetics__Kinetic_Question__r.Kinetics__Values__c, 
                    Kinetics__Kinetic_Question__r.Kinetics__Default_Value__c, 
                    Kinetics__Kinetic_Question__r.Kinetics__Field_Type__c, 
                    Kinetics__Kinetic_Question__r.Kinetics__Has_Followup_Questions__c, 
                    Kinetics__Kinetic_Question__r.Kinetics__Is_Photo_Mandatory__c, 
                    //Kinetics__Kinetic_Question__r.ArxxusRFMv1__Options_Weightage__c, 
                    //Kinetics__Kinetic_Question__r.ArxxusRFMv1__Out_of_Score__c, 
                    Kinetics__Kinetic_Question__r.Kinetics__Parent_Option_Value__c, 
                    Kinetics__Kinetic_Question__r.Kinetics__Parent_Question__c, 
                    Kinetics__Kinetic_Question__r.Kinetics__Question__c, 
                    //Kinetics__Kinetic_Question__r.ArxxusRFMv1__Skip_Scoring__c, 
                    Kinetics__Kinetic_Question__r.Kinetics__Status__c,
                    Kinetics__Kinetic_Question__r.Kinetics__Take_Photo__c,
                    Kinetics__Kinetic_Question__r.Kinetics__Custom_Question_Number__c,
                    Kinetics__Kinetic_Question__r.Kinetics__Related_To_Object__c,
                    Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c
                    From Kinetics__Kinetic_Form_Question__c 
                    Where Kinetics__Kinetic_Form__c =: invite.Kinetics__Kinetic_Form__c
                    Order By Kinetics__Index__c];

            Map<String, Kinetics__Kinetic_Form_Answer__c> answerByFormQuestionId = new Map<String, Kinetics__Kinetic_Form_Answer__c>();
            if(surveyQuestionList.size() > 0) {
                for(Kinetics__Kinetic_Form_Answer__c kfa: [SELECT Id, Kinetics__Kinetic_Question_Id__c, Kinetics__Kinetic_Form_Question__c, Kinetics__Answer__c
                                FROM Kinetics__Kinetic_Form_Answer__c 
                                WHERE Kinetics__Survey_Invitation__c = :invite.Id
                                AND Kinetics__Kinetic_Form_Question__c IN : surveyQuestionList]){

                    answerByFormQuestionId.put(kfa.Kinetics__Kinetic_Form_Question__c, kfa);
                }
            }

            //changes started
            Map<String, Set<String>> fieldsByObjectName = new Map<String, Set<String>>();
            Map<String, String> fieldNameByQuestionId = new Map<String, String>();
            for(Kinetics__Kinetic_Form_Question__c sqDb: surveyQuestionList){
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
                if(objectNameSet[0] == 'Contact') {
                    parentReferenceId = invite.Kinetics__Contact__c;
                } else if(objectNameSet[0] == 'Account') {
                    parentReferenceId = invite.Kinetics__Contact__r.AccountId;
                }

                
                String queryString = ' SELECT Id, ' + String.join(new List<String>(fieldsByObjectName.get(objectNameSet[0])), ',') 
                                        + ' FROM ' + objectNameSet[0] 
                                        + ' WHERE Id = :parentReferenceId ' ;
                relatedRecordList = Database.query(queryString);
            }

            String surveyName = surveyQuestionList.get(0).Kinetics__Kinetic_Form__r.Name;
            String instruction = (surveyQuestionList.get(0).Kinetics__Kinetic_Form__r.Kinetics__Instructions__c != null) 
                                    ? surveyQuestionList.get(0).Kinetics__Kinetic_Form__r.Kinetics__Instructions__c 
                                    : (GlobalConstants.surveyInstructionMessage+ ' '+ surveyName);

            List<SeqRendererController.SeqQuestion> sqList = new List<SeqRendererController.SeqQuestion>();
            Integer indexCount = 1;
            for(Kinetics__Kinetic_Form_Question__c sqDb: surveyQuestionList){
                if(answerByFormQuestionId.containsKey(sqDb.Id) && String.isNotBlank(answerByFormQuestionId.get(sqDb.Id).Kinetics__Answer__c)) {
                    continue;
                }
                SeqRendererController.SeqQuestion sqObj = new SeqRendererController.SeqQuestion();
                sqObj.displayIndex = indexCount ++;
                sqObj.index = sqDb.Kinetics__Index__c;
                sqObj.fieldType = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Field_Type__c;
                sqObj.questionDetails = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Question__c;
                sqObj.surveyName = sqDb.Kinetics__Kinetic_Form__r.Name;
                sqObj.surveyInviteId = invite.Id;
                sqObj.questionId = sqDb.Kinetics__Kinetic_Question__c;
                sqObj.surveyQuestionId = sqDb.Id;
                sqObj.questionValues = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Values__c;
                sqObj.helpText = sqDb.Kinetics__Question_Help_Text__c;
                sqObj.stage = invite.Kinetics__Stage__c;
                sqObj.scoreConfirmed = Boolean.valueOf(sqDb.Kinetics__Score_Confirmed__c);
                sqObj.optionScore = sqDb.Kinetics__Option_Score__c;

                //changes started
                if(relatedRecordList.size() > 0 
                    && String.isNotBlank(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c)
                    && String.isNotBlank(String.valueOf(relatedRecordList[0].get(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c)))) {
                    sqObj.defaultValue = String.valueOf(relatedRecordList[0].get(sqDb.Kinetics__Kinetic_Question__r.Kinetics__Related_Field_API_Name__c));
                    sqObj.answer = sqObj.defaultValue == null ? '': sqObj.defaultValue;
                }
                sqList.add(sqObj);
            }
            if(sqList.size() == 0 && answerByFormQuestionId.size() == surveyQuestionList.size()){
                sRes.statusCode = '2100';
                sRes.responseMessage = GlobalConstants.surveyCompletedMessage;
                sRes.responseDetails = null;
                
                return JSON.serialize(sRes);
            }
            
            Map<String, Object> sResMap = new Map<String, Object>();
            sResMap.put('surveyName', surveyName);
            sResMap.put('sqList', sqList);
            sResMap.put('instruction', instruction);
            sResMap.put('contactFirstName', '');
            sResMap.put('contactLastName', '');
            if(invite.Kinetics__Contact__c != null) {
                sResMap.put('contactFirstName', invite.Kinetics__Recipient_Name__c);
                sResMap.put('contactLastName', invite.Kinetics__Recipient_Last_Name__c);
            }
            if(String.isNotBlank(invite.Kinetics__Recipient_Name__c)) {
                sResMap.put('contactFirstName',invite.Kinetics__Recipient_Name__c);
            }
            if(String.isNotBlank(invite.Kinetics__Recipient_Last_Name__c)) {
                sResMap.put('contactLastName',invite.Kinetics__Recipient_Last_Name__c);
            }

            sRes.statusCode = '2000';
            sRes.responseMessage = 'Success';
            sRes.responseDetails = sResMap;
        }catch(Exception ex){
            sRes.statusCode = '2100';
            sRes.responseMessage = ex.getMessage();
            sRes.responseDetails = null;
        }
        return JSON.serialize(sRes);
    }

    private static String getSequenceBySurveyGuidForJSONBasedTemplate(String surveyGUID){
        SeqRendererController.SeqResponse sRes = new SeqRendererController.SeqResponse();
        system.debug('****** surveyGUID=' + surveyGUID);
        try{
            List<Schema.DescribeFieldResult> surveyInvitationFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Survey_Invitation__c.Kinetics__GUID__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Stage__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Form__c.getDescribe()
            };
            List<Schema.DescribeFieldResult> kineticFormFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Kinetic_Form_Question__c.Kinetics__Index__c.getDescribe(),
                Kinetics__Kinetic_Form_Question__c.Kinetics__Question_Help_Text__c.getDescribe(),
                Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Question__c.getDescribe(),
                Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Form__c.getDescribe()
            };
            if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
                && CheckUserPermission.checkFieldsReadAccess(surveyInvitationFieldList)
                && CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Question__c) 
                && CheckUserPermission.checkFieldsReadAccess(kineticFormFieldList))) {
                    throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
            }
            List<Kinetics__Survey_Invitation__c> invites = [Select Id, Kinetics__Kinetic_Form__c, 
                                                            Kinetics__Kinetic_Form__r.Kinetics__Template_Metadata__c, Kinetics__Kinetic_Form__r.Name,
                                                            Kinetics__Kinetic_Form__r.Kinetics__Instructions__c,
                                                            Kinetics__Stage__c,Kinetics__Contact__c, 
                                                            Kinetics__Recipient_Name__c, Kinetics__Recipient_Last_Name__c, 
                                                            Kinetics__Recipient_Email__c, Kinetics__Recipient_Number__c,
                                                            Kinetics__Contact__r.AccountId  
                                                            From Kinetics__Survey_Invitation__c 
                                                            Where Kinetics__GUID__c =: surveyGUID];
            
        
            Kinetics__Survey_Invitation__c invite = invites.get(0);
        
            String templateMetadata = invite.Kinetics__Kinetic_Form__r.Kinetics__Template_Metadata__c;
            List<Map<String, String>> questionsList = new List<Map<String, String>>();
            List<Object> pageObjList = new List<Object>();
            List<String> templateQuestionUIDList = new List<String>();
            Map<String, Set<String>> fieldsByObjectName = new Map<String, Set<String>>();
            Map<String, String> fieldNameByQuestionId = new Map<String, String>();

            pageObjList = (List<Object>) JSON.deserializeUntyped(templateMetadata);
            if(pageObjList.size() == 0) {
                sRes.statusCode = '2100';
                sRes.responseMessage = GlobalConstants.surveyNotFoundMessage;
                sRes.responseDetails = null;
                return JSON.serialize(sRes);
            }
            Integer totalAvailableScore = 0;
            Integer index = 1;
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
                        Map<String, String> questionWrap = new Map<String, String>();
                        questionWrap.put('Kinetics__Index__c',String.valueOf(index++));
                        questionWrap.put('Kinetics__Question__c', questionWrapperObj.containsKey('Name') ? String.valueOf(questionWrapperObj.get('Name')) : '');
                        questionWrap.put('Kinetics__Kinetic_Question_Values__c', questionWrapperObj.containsKey('Kinetics__Values__c') ? JSON.serialize(questionWrapperObj.get('Kinetics__Values__c')) : JSON.serialize(new List<Map<string, String>>()));
                        questionWrap.put('Kinetics__Kinetic_Form_Question__c', '');
                        questionWrap.put('Kinetics__Type__c', questionWrapperObj.containsKey('Kinetics__Field_Type__c') ? String.valueOf(questionWrapperObj.get('Kinetics__Field_Type__c')) : '');
                        questionWrap.put('Kinetics__Answer__c', '');
                        questionWrap.put('Kinetics__Kinetic_Question_Id__c', '');
                        questionWrap.put('Kinetics__Inspection__c', '');
                        questionWrap.put('Kinetics__Template_Question_UID__c', questionWrapperObj.containsKey('uid') ? String.valueOf(questionWrapperObj.get('uid')) : '');
                        questionWrap.put('Kinetics__AI_Guidance__c', questionWrapperObj.containsKey('Kinetics__AI_Guidance__c') ? String.valueOf(questionWrapperObj.get('Kinetics__AI_Guidance__c')) : '');
                        questionWrap.put('Kinetics__Related_To_Object__c', questionWrapperObj.containsKey('Kinetics__Related_To_Object__c') ? String.valueOf(questionWrapperObj.get('Kinetics__Related_To_Object__c')) : '');
                        questionWrap.put('Kinetics__Related_Field_API_Name__c', questionWrapperObj.containsKey('Kinetics__Related_Field_API_Name__c') ? String.valueOf(questionWrapperObj.get('Kinetics__Related_Field_API_Name__c')) : '');
                        questionWrap.put('qInstructions', questionWrapperObj.containsKey('qInstructions') ? String.valueOf(questionWrapperObj.get('qInstructions')) : '');
                        questionWrap.put('flowName', questionWrapperObj.containsKey('flowName') ? String.valueOf(questionWrapperObj.get('flowName')) : '');

                        templateQuestionUIDList.add(questionWrap.get('Kinetics__Template_Question_UID__c'));
                        Integer maxScoreForQuestion = 0;
                        if(String.isNotBlank(questionWrap.get('Kinetics__Kinetic_Question_Values__c'))){
                            List<Object> optionsListObj = new List<Object>();
                            optionsListObj = questionWrapperObj.containsKey('Kinetics__Values__c') ? (List<Object>)questionWrapperObj.get('Kinetics__Values__c') :  null;
                            if(optionsListObj != null){
                                String optionsCommaSeparatedString = '';
                                Map<String, String> optionscoreByValue = new Map<String, String>();
                                for(Object optn: optionsListObj) {
                                    Map<String, Object> option = (Map<String, Object>)optn;
                                    Integer optionscore = 0;
                                    String optionValue = '';
                                    if(option.containsKey('score') && option.get('score') != null
                                        && String.valueOf(option.get('score')) != ''){
                                            optionscore =  Integer.valueOf(option.get('score'));
                                    }
                                    if(maxScoreForQuestion < optionscore){
                                        maxScoreForQuestion = optionscore;
                                    }

                                    if(option.containsKey('value') && option.get('value') != null
                                        && String.valueOf(option.get('value')) != ''){
                                            optionValue = String.valueOf(option.get('value'));
                                            if(String.isNotBlank(optionsCommaSeparatedString)) {
                                                optionsCommaSeparatedString = optionsCommaSeparatedString + ', ';
                                            }
                                            optionsCommaSeparatedString = optionsCommaSeparatedString + String.valueOf(option.get('value'));
                                    }
                                    optionscoreByValue.put(optionValue, String.valueOf(optionscore));
                                }
                                questionWrap.put('Kinetics__Option_Score__c', JSON.serialize(optionscoreByValue));
                                questionWrap.put('Kinetics__Score_Confirmed__c', String.valueOf(optionscoreByValue.size() != 0));
                                questionWrap.put('Kinetics__Kinetic_Question_Values__c',optionsCommaSeparatedString);
                            }
                            totalAvailableScore = totalAvailableScore + maxScoreForQuestion;
                        }
                        questionWrap.put('Kinetics__Out_of_Score__c', String.valueOf(maxScoreForQuestion));
                        questionsList.add(questionWrap);

                        if(String.isNotBlank(questionWrap.get('Kinetics__Related_To_Object__c'))
                            && String.isNotBlank(questionWrap.get('Kinetics__Related_Field_API_Name__c'))) {
                                Set<String> fieldset = new Set<String>();
                                if(fieldsByObjectName.containsKey(questionWrap.get('Kinetics__Related_To_Object__c'))) {
                                    fieldset = fieldsByObjectName.get(questionWrap.get('Kinetics__Related_To_Object__c'));
                                }
                                fieldset.add(questionWrap.get('Kinetics__Related_Field_API_Name__c'));
                                fieldsByObjectName.put(questionWrap.get('Kinetics__Related_To_Object__c'), fieldset);
                                fieldNameByQuestionId.put(questionWrap.get('Kinetics__Template_Question_UID__c'), questionWrap.get('Kinetics__Related_Field_API_Name__c'));
                        }
                    }
                }
            }

            Map<String, Kinetics__Kinetic_Form_Answer__c> answerByFormQuestionId = new Map<String, Kinetics__Kinetic_Form_Answer__c>();
            if(questionsList.size() > 0) {
                for(Kinetics__Kinetic_Form_Answer__c kfa: [SELECT Id, Kinetics__Template_Question_UID__c, Kinetics__Kinetic_Form_Question__c, Kinetics__Answer__c
                                FROM Kinetics__Kinetic_Form_Answer__c 
                                WHERE Kinetics__Survey_Invitation__c = :invite.Id
                                AND Kinetics__Template_Question_UID__c IN : templateQuestionUIDList]){

                    answerByFormQuestionId.put(kfa.Kinetics__Template_Question_UID__c, kfa);
                }
            }

            //changes started
            List<sObject> relatedRecordList = new List<sObject>();
            //will need to change this as this is not supporting configurability
            String parentReferenceId = '';
            //here assuming that all the questions from same kineitc form should be related to only one reference object like contact, account, user, etc
            if(fieldsByObjectName.size() > 0 && fieldsByObjectName.size() == 1) {
                List<String> objectNameSet = new List<String>(fieldsByObjectName.keySet());
                if(objectNameSet[0] == 'Contact') {
                    parentReferenceId = invite.Kinetics__Contact__c;
                } else if(objectNameSet[0] == 'Account') {
                    parentReferenceId = invite.Kinetics__Contact__r.AccountId;
                }
                
                String queryString = ' SELECT Id, ' + String.join(new List<String>(fieldsByObjectName.get(objectNameSet[0])), ',') 
                                        + ' FROM ' + objectNameSet[0] 
                                        + ' WHERE Id = :parentReferenceId ' ;
                relatedRecordList = Database.query(queryString);
            }

            String surveyName = invite.Kinetics__Kinetic_Form__r.Name;
            String instruction = (invite.Kinetics__Kinetic_Form__r.Kinetics__Instructions__c != null) 
                                    ? invite.Kinetics__Kinetic_Form__r.Kinetics__Instructions__c 
                                    : (GlobalConstants.surveyInstructionMessage+ ' '+ surveyName);

            List<SeqRendererController.SeqQuestion> sqList = new List<SeqRendererController.SeqQuestion>();
            Integer indexCount = 1;
            for(Map<String, String> sqDb: questionsList){
                // if(answerByFormQuestionId.containsKey(sqDb.get('Kinetics__Template_Question_UID__c')) 
                //     && String.isNotBlank(answerByFormQuestionId.get(sqDb.get('Kinetics__Template_Question_UID__c')).Kinetics__Answer__c)) {
                //     continue;
                // }
                SeqRendererController.SeqQuestion sqObj = new SeqRendererController.SeqQuestion();
                
                if(answerByFormQuestionId.containsKey(sqDb.get('Kinetics__Template_Question_UID__c')) 
                    && String.isNotBlank(answerByFormQuestionId.get(sqDb.get('Kinetics__Template_Question_UID__c')).Kinetics__Answer__c)) {
                    sqObj.defaultValue = answerByFormQuestionId.get(sqDb.get('Kinetics__Template_Question_UID__c')).Kinetics__Answer__c;
                    sqObj.answer = sqObj.defaultValue == null ? '': sqObj.defaultValue;
                }
                
                sqObj.displayIndex = indexCount ++;
                sqObj.index = Decimal.valueOf(sqDb.get('Kinetics__Index__c'));
                sqObj.fieldType = sqDb.get('Kinetics__Type__c');
                sqObj.questionDetails = sqDb.get('Kinetics__Question__c');
                sqObj.surveyName = surveyName;
                sqObj.surveyInviteId = invite.Id;
                sqObj.questionId = sqDb.get('Kinetics__Template_Question_UID__c');
                sqObj.surveyQuestionId = sqDb.get('Kinetics__Template_Question_UID__c');
                sqObj.questionValues = sqDb.get('Kinetics__Kinetic_Question_Values__c');
                sqObj.helpText = sqDb.get('Kinetics__Question_Help_Text__c');
                sqObj.stage = invite.Kinetics__Stage__c;
                sqObj.scoreConfirmed = Boolean.valueOf(sqDb.get('Kinetics__Score_Confirmed__c'));
                sqObj.optionScore = sqDb.get('Kinetics__Option_Score__c');
                sqObj.qInstructions = sqDb.get('qInstructions');
                sqObj.flowName = sqDb.get('flowName');
                
                //just to save time for now and reuse existing componnent 
                if(sqObj.fieldType == 'Yes No') {
                    sqObj.fieldType = 'Radio Button';
                } else if(sqObj.fieldType == 'Compliant Non Compliant') {
                    sqObj.fieldType = 'Radio Button';
                } else if (sqObj.fieldType == 'Salesforce Field') {
                    sqObj.fieldType = 'Text';
                }
                
                //changes started
                if(relatedRecordList.size() > 0 
                    && String.isNotBlank(sqDb.get('Kinetics__Related_Field_API_Name__c'))
                    && String.isNotBlank(String.valueOf(relatedRecordList[0].get(sqDb.get('Kinetics__Related_Field_API_Name__c'))))) {
                    sqObj.defaultValue = String.valueOf(relatedRecordList[0].get(sqDb.get('Kinetics__Related_Field_API_Name__c')));
                    sqObj.answer = sqObj.defaultValue == null ? '': sqObj.defaultValue;
                }
                sqList.add(sqObj);
            }
            if(sqList.size() == 0 && answerByFormQuestionId.size() == questionsList.size()){
                sRes.statusCode = '2100';
                sRes.responseMessage = GlobalConstants.surveyCompletedMessage;
                sRes.responseDetails = null;
                
                return JSON.serialize(sRes);
            }
            
            Map<String, Object> sResMap = new Map<String, Object>();
            sResMap.put('surveyName', surveyName);
            sResMap.put('sqList', sqList);
            sResMap.put('instruction', instruction);
            sResMap.put('contactFirstName', invite.Kinetics__Recipient_Name__c);
            sResMap.put('contactLastName', invite.Kinetics__Recipient_Last_Name__c);
            sResMap.put('templateMetadata', templateMetadata);

            sRes.statusCode = '2000';
            sRes.responseMessage = 'Success';
            sRes.responseDetails = sResMap;
        }catch(Exception ex){
            sRes.statusCode = '2100';
            sRes.responseMessage = ex.getMessage();
            sRes.responseDetails = null;
        }
        return JSON.serialize(sRes);
    }

    private static void createEvents(List<Kinetics__Survey_Invitation__c> invites, String surveyName, String stage){
        List<Event> eList = new List<Event>();
        // List<Schema.DescribeFieldResult> eventFieldList = new List<Schema.DescribeFieldResult>{
        //     Event.Subject.getDescribe(),
        //     Event.Description.getDescribe(),
        //     Event.WhatId.getDescribe(),
        //     Event.WhoId.getDescribe(),
        //     Event.ActivityDate.getDescribe(),
        //     Event.DurationInMinutes.getDescribe(),
        //     Event.ActivityDateTime.getDescribe()
        // };
        // if(!(CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Event) 
        //     && CheckUserPermission.checkFieldsCreateAccess(eventFieldList))) {
        //         throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        // }

        if(!GlobalUtility.getCreateEventFlag()) {
            //the setting is disable for creation of event, so return with out creating event record
            return;
        }
        
        for(Kinetics__Survey_Invitation__c invite: invites){
            Event event = new Event();
            event.Subject = GlobalConstants.eventSubjectMessage + stage;
            event.Description = surveyName;
            event.WhatId = invite.Id;
            if(invite.Kinetics__Contact__c != null) {
                event.WhoId = invite.Kinetics__Contact__c;
            }
            event.ActivityDate = System.today();
            event.DurationInMinutes = 30;
            event.ActivityDateTime  = System.now() + 3;
            eList.add(event); 
        }
        insert eList;
    }

    public static String updateSurvey2InProgress(String surveyGUID){
        SeqRendererController.SeqResponse sRes = new SeqRendererController.SeqResponse();
        try{
            List<Schema.DescribeFieldResult> surveyInvitationFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Survey_Invitation__c.Kinetics__Contact__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Stage__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__GUID__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Form__c.getDescribe()
            };
            if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
                && CheckUserPermission.checkFieldsReadAccess(surveyInvitationFieldList)
                // && CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
                // && CheckUserPermission.checkFieldsUpdateAccess(surveyInvitationFieldList)
                )) {
                    throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
            }
            List<Kinetics__Survey_Invitation__c> invites = [Select Id, Kinetics__Contact__c, Kinetics__Kinetic_Form__c, Kinetics__Kinetic_Form__r.Name, Kinetics__Stage__c,
                                                    Kinetics__Inspection__c 
                                                    From Kinetics__Survey_Invitation__c 
                                                    Where Kinetics__GUID__c =: surveyGUID
                                                    AND Kinetics__Stage__c = :GlobalConstants.sentToRecipientStage];
            if(!invites.isEmpty()){
                Kinetics__Survey_Invitation__c invite = invites.get(0); 
                // if(invite.Kinetics__Stage__c == GlobalConstants.sentToRecipientStage){
                    invite.Kinetics__Stage__c = GlobalConstants.inProgressStage;
                    update invite;

                    createEvents( invites, invite.Kinetics__Kinetic_Form__r.Name, 'Opened');
                // }

                if(String.isNotBlank(invite.Kinetics__Inspection__c)) {
                    Kinetics__Inspection__c inspectionRec = new Kinetics__Inspection__c(
                                                                    Id = invite.Kinetics__Inspection__c, 
                                                                    Kinetics__Status__c = 'In Progress');
                    update inspectionRec;
                }
            }
            sRes.statusCode = '2000';
            sRes.responseMessage = 'Success';
        }catch(Exception ex){
            sRes.statusCode = '2100';
            sRes.responseMessage = ex.getMessage();
            sRes.responseDetails = ex.getStackTraceString();
        }
        return JSON.serialize(sRes);
    }

    public static String saveAnswers(String surveyGUID, String answerJsonString){
        system.debug('***** answerJsonString=' + answerJsonString);
        SeqRendererController.SeqResponse sRes = new SeqRendererController.SeqResponse();
        try{
            List<Schema.DescribeFieldResult> surveyInvitationFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Survey_Invitation__c.Kinetics__Contact__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Form__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__GUID__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Inspection__c.getDescribe()
            };
            List<Schema.DescribeFieldResult> formQuestionFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Question__c.getDescribe(),
                Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Form__c.getDescribe()
            };
            List<Schema.DescribeFieldResult> formAnswersFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Kinetic_Form_Answer__c.Kinetics__Answer_Index__c.getDescribe(),
                Kinetics__Kinetic_Form_Answer__c.Kinetics__Kinetic_Question__c.getDescribe(),
                Kinetics__Kinetic_Form_Answer__c.Kinetics__Kinetic_Question_Values__c.getDescribe(),
                Kinetics__Kinetic_Form_Answer__c.Kinetics__Kinetic_Form_Question__c.getDescribe(),
                Kinetics__Kinetic_Form_Answer__c.Kinetics__Type__c.getDescribe(),
                Kinetics__Kinetic_Form_Answer__c.Kinetics__Survey_Invitation__c.getDescribe(),
                Kinetics__Kinetic_Form_Answer__c.Kinetics__Answer__c.getDescribe(),
                Kinetics__Kinetic_Form_Answer__c.Kinetics__Kinetic_Question_Id__c.getDescribe()
            };
            if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
                && CheckUserPermission.checkFieldsReadAccess(surveyInvitationFieldList)
                // && CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
                // && CheckUserPermission.checkFieldsUpdateAccess(surveyInvitationFieldList)
                && CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Question__c) 
                && CheckUserPermission.checkFieldsReadAccess(formQuestionFieldList)
                && CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Answer__c) 
                && CheckUserPermission.checkFieldsCreateAccess(formAnswersFieldList))) {
                    throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
            }
            List<Kinetics__Survey_Invitation__c> invites = [SELECT Id, Kinetics__Contact__c, Kinetics__Recipient_Name__c, Kinetics__Recipient_Last_Name__c, 
                                                                    Kinetics__Recipient_Email__c,Kinetics__Recipient_Number__c,
                                                                    Kinetics__Kinetic_Form__c, Kinetics__Kinetic_Form__r.Name, Kinetics__Kinetic_Job__c, 
                                                                    Kinetics__Kinetic_Form__r.Kinetics__Template_Metadata__c,
                                                                    Kinetics__Inspection__c
                                                            FROM Kinetics__Survey_Invitation__c 
                                                            WHERE Kinetics__GUID__c =: surveyGUID];
            Kinetics__Survey_Invitation__c invite = invites.get(0);
            Integer totalScoreAttained = 0;
            Boolean newFormatTemplate = String.isNotBlank(invite.Kinetics__Kinetic_Form__r.Kinetics__Template_Metadata__c);

            List<Kinetics__Kinetic_Form_Question__c> surveyQuestions = [SELECT Id, Kinetics__Kinetic_Question__c 
                                                                        FROM Kinetics__Kinetic_Form_Question__c 
                                                                        WHERE Kinetics__Kinetic_Form__c =: invite.Kinetics__Kinetic_Form__c];
            Map<String, Kinetics__Kinetic_Form_Answer__c> answerByFormQuestionId = new Map<String, Kinetics__Kinetic_Form_Answer__c>();
            Map<String, Kinetics__Kinetic_Form_Answer__c> completedanswerByFormQuestionId = new Map<String, Kinetics__Kinetic_Form_Answer__c>();
            Map<String, Map<String, String>> questionsByUIDMap = new Map<String, Map<String, String>>();

            if(surveyQuestions.size() > 0) {
                for(Kinetics__Kinetic_Form_Answer__c kfa: [SELECT Id, Kinetics__Kinetic_Question_Id__c, Kinetics__Kinetic_Form_Question__c, 
                                                            Kinetics__Score_Attained__c,Kinetics__Answer__c, Kinetics__Template_Question_UID__c
                                FROM Kinetics__Kinetic_Form_Answer__c 
                                WHERE Kinetics__Survey_Invitation__c = :invite.Id
                                AND Kinetics__Kinetic_Form_Question__c IN : surveyQuestions]){
                    //generated for checking if all questions are answered
                    answerByFormQuestionId.put(kfa.Kinetics__Kinetic_Form_Question__c, kfa);

                    //total of score attained
                    totalScoreAttained = totalScoreAttained + (kfa.Kinetics__Score_Attained__c != null ? Integer.valueOf(kfa.Kinetics__Score_Attained__c) : 0);
                    if(kfa.Kinetics__Answer__c != null){
                        completedanswerByFormQuestionId.put(kfa.Kinetics__Kinetic_Form_Question__c, kfa);
                    }
                }
            } else if(newFormatTemplate){
                for(Kinetics__Kinetic_Form_Answer__c kfa: [SELECT Id, Kinetics__Kinetic_Question_Id__c, Kinetics__Kinetic_Form_Question__c, 
                                                Kinetics__Score_Attained__c,Kinetics__Answer__c, Kinetics__Template_Question_UID__c
                                FROM Kinetics__Kinetic_Form_Answer__c 
                                WHERE Kinetics__Survey_Invitation__c = :invite.Id]){
                    //generated for checking if all questions are answered
                    answerByFormQuestionId.put(kfa.Kinetics__Template_Question_UID__c, kfa);

                    //total of score attained
                    totalScoreAttained = totalScoreAttained + (kfa.Kinetics__Score_Attained__c != null ? Integer.valueOf(kfa.Kinetics__Score_Attained__c) : 0);
                    if(kfa.Kinetics__Answer__c != null){
                        completedanswerByFormQuestionId.put(kfa.Kinetics__Template_Question_UID__c, kfa);
                    }
                }
                String templateMetadata = invite.Kinetics__Kinetic_Form__r.Kinetics__Template_Metadata__c;
                
                List<Object> pageObjList = new List<Object>();
                List<String> templateQuestionUIDList = new List<String>();
    
                pageObjList = (List<Object>) JSON.deserializeUntyped(templateMetadata);
                
                Integer totalAvailableScore = 0;
                Integer index = 1;
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
                            Map<String, String> questionWrap = new Map<String, String>();
                            questionWrap.put('Kinetics__Index__c',String.valueOf(index++));
                            questionWrap.put('Kinetics__Question__c', questionWrapperObj.containsKey('Name') ? String.valueOf(questionWrapperObj.get('Name')) : '');
                            questionWrap.put('Kinetics__Kinetic_Question_Values__c', questionWrapperObj.containsKey('Kinetics__Values__c') ? JSON.serialize(questionWrapperObj.get('Kinetics__Values__c')) : JSON.serialize(new List<Map<string, String>>()));
                            questionWrap.put('Kinetics__Kinetic_Form_Question__c', '');
                            questionWrap.put('Kinetics__Type__c', questionWrapperObj.containsKey('Kinetics__Field_Type__c') ? String.valueOf(questionWrapperObj.get('Kinetics__Field_Type__c')) : '');
                            questionWrap.put('Kinetics__Answer__c', '');
                            questionWrap.put('Kinetics__Kinetic_Question_Id__c', '');
                            questionWrap.put('Kinetics__Inspection__c', '');
                            questionWrap.put('Kinetics__Template_Question_UID__c', questionWrapperObj.containsKey('uid') ? String.valueOf(questionWrapperObj.get('uid')) : '');
                            questionWrap.put('Kinetics__AI_Guidance__c', questionWrapperObj.containsKey('Kinetics__AI_Guidance__c') ? String.valueOf(questionWrapperObj.get('Kinetics__AI_Guidance__c')) : '');
                            questionWrap.put('Kinetics__Related_To_Object__c', questionWrapperObj.containsKey('Kinetics__Related_To_Object__c') ? String.valueOf(questionWrapperObj.get('Kinetics__Related_To_Object__c')) : '');
                            questionWrap.put('Kinetics__Related_Field_API_Name__c', questionWrapperObj.containsKey('Kinetics__Related_Field_API_Name__c') ? String.valueOf(questionWrapperObj.get('Kinetics__Related_Field_API_Name__c')) : '');
    
                            templateQuestionUIDList.add(questionWrap.get('Kinetics__Template_Question_UID__c'));
                            Integer maxScoreForQuestion = 0;
                            if(String.isNotBlank(questionWrap.get('Kinetics__Kinetic_Question_Values__c'))){
                                List<Object> optionsListObj = new List<Object>();
                                optionsListObj = questionWrapperObj.containsKey('Kinetics__Values__c') ? (List<Object>)questionWrapperObj.get('Kinetics__Values__c') :  null;
                                if(optionsListObj != null){
                                    Map<String, String> optionscoreByValue = new Map<String, String>();
                                    for(Object optn: optionsListObj) {
                                        Map<String, Object> option = (Map<String, Object>)optn;
                                        Integer optionscore = 0;
                                        String optionValue = '';
                                        if(option.containsKey('score') && option.get('score') != null
                                            && String.valueOf(option.get('score')) != ''){
                                                optionscore =  Integer.valueOf(option.get('score'));
                                        }
                                        if(maxScoreForQuestion < optionscore){
                                            maxScoreForQuestion = optionscore;
                                        }

                                        optionscoreByValue.put(optionValue, String.valueOf(optionscore));
                                    }
                                    questionWrap.put('Kinetics__Option_Score__c', JSON.serialize(optionscoreByValue));
                                    questionWrap.put('Kinetics__Score_Confirmed__c', String.valueOf(optionscoreByValue.size() != 0));
                                }
                                
                                totalAvailableScore = totalAvailableScore + maxScoreForQuestion;
                            }
                            questionWrap.put('Kinetics__Out_of_Score__c', String.valueOf(maxScoreForQuestion));
                            questionsByUIDMap.put(questionWrap.get('Kinetics__Template_Question_UID__c'),questionWrap);
                        }
                    }
                }
            }

            Map<String, SeqRendererController.SeqAnswer> answersObj = (Map<String, SeqRendererController.SeqAnswer>) JSON.deserializeStrict(answerJsonString, Map<String, SeqRendererController.SeqAnswer>.class);
            List<Kinetics__Kinetic_Form_Answer__c> answers2Insert = new List<Kinetics__Kinetic_Form_Answer__c>();

            Map<String, String> questionIdMap = new Map<String, String>();
            for(String surveyQuestionId: answersObj.keySet()){
                SeqRendererController.SeqAnswer answer = answersObj.get(surveyQuestionId);

                Kinetics__Kinetic_Form_Answer__c answer2Commit = new Kinetics__Kinetic_Form_Answer__c();
                if(answerByFormQuestionId.containsKey(surveyQuestionId)) {
                    answer2Commit.Id = answerByFormQuestionId.get(surveyQuestionId).Id;
                    totalScoreAttained = totalScoreAttained - (answerByFormQuestionId.get(surveyQuestionId).Kinetics__Score_Attained__c != null ? Integer.valueOf(answerByFormQuestionId.get(surveyQuestionId).Kinetics__Score_Attained__c) : 0);
                }
                answer2Commit.Kinetics__Answer_Index__c = Decimal.valueOf(answer.index);
                answer2Commit.Kinetics__Kinetic_Question__c = answer.questionDetails;
                answer2Commit.Kinetics__Kinetic_Question_Values__c = answer.questionValues;
                
                answer2Commit.Kinetics__Kinetic_Form_Question__c = (newFormatTemplate) ? null : surveyQuestionId;
                answer2Commit.Kinetics__Type__c = answer.fieldType;
               
                answer2Commit.Kinetics__Survey_Invitation__c = invite.Id;
                answer2Commit.Kinetics__Answer__c = answer.answer;
                answer2Commit.Kinetics__Kinetic_Question_Id__c =  (newFormatTemplate) ? null : answer.questionId;
                answer2Commit.Kinetics__Inspection__c = invite.Kinetics__Inspection__c;
                answer2Commit.Kinetics__Score_Attained__c = answer.attainedScore != null ? answer.attainedScore : 0;
                if(newFormatTemplate) {
                    answer2Commit.Kinetics__Template_Question_UID__c = surveyQuestionId;
                    if(questionsByUIDMap.containsKey(surveyQuestionId)) {
                        answer2Commit.Kinetics__Kinetic_Question_Values__c = questionsByUIDMap.get(surveyQuestionId).get('Kinetics__Kinetic_Question_Values__c');
                    }
                    if(questionsByUIDMap.containsKey(surveyQuestionId)) {
                        answer2Commit.Kinetics__Type__c = questionsByUIDMap.get(surveyQuestionId).get('Kinetics__Type__c');
                    }
                }

                totalScoreAttained = totalScoreAttained + Integer.valueOf(answer2Commit.Kinetics__Score_Attained__c);

                answers2Insert.add(answer2Commit);

                questionIdMap.put(answer.questionId, surveyQuestionId);

                //generated for checking if all questions are answered
                answerByFormQuestionId.put(surveyQuestionId, answer2Commit);

                completedanswerByFormQuestionId.put(surveyQuestionId, answer2Commit);
            }

            Map<String, String> answerIdMap = new Map<String, String>();
            if(!answers2Insert.isEmpty()){
                upsert answers2Insert;

                for(Kinetics__Kinetic_Form_Answer__c surveyAnswer: answers2Insert){
                    String surveyQuestionId =  (newFormatTemplate) ? questionIdMap.get(surveyAnswer.Kinetics__Template_Question_UID__c) : questionIdMap.get(surveyAnswer.Kinetics__Kinetic_Question_Id__c);
                    answerIdMap.put(surveyQuestionId, surveyAnswer.Id);
                }
            }
            String inviteStage = '';
            if(surveyQuestions.size() != 0 
                && completedanswerByFormQuestionId.size() != surveyQuestions.size() 
                && completedanswerByFormQuestionId.size() < surveyQuestions.size()) {
                inviteStage = GlobalConstants.partiallyCompletedStage;
            } else if(surveyQuestions.size() == 0 && newFormatTemplate == true
                    && completedanswerByFormQuestionId.size() != questionsByUIDMap.size()
                    && completedanswerByFormQuestionId.size() < questionsByUIDMap.size()) {
                inviteStage = GlobalConstants.partiallyCompletedStage;
            } else {
                inviteStage = GlobalConstants.completedStage;
            }
            invite.Kinetics__Stage__c = inviteStage;
            update invite;

            if(String.isNotBlank(invite.Kinetics__Inspection__c)){ 
                Kinetics__Inspection__c inspectionRec = new Kinetics__Inspection__c(Id = invite.Kinetics__Inspection__c);
                if(inviteStage == GlobalConstants.completedStage) {
                    inspectionRec.Kinetics__Status__c = 'Complete';
                }
                if(totalScoreAttained != 0){
                    inspectionRec.Kinetics__Total_Score__c = totalScoreAttained;
                }
                inspectionRec.Kinetics__Answered_Questions__c = completedanswerByFormQuestionId.size();
                update inspectionRec;
            }

            //update Kinetic job
            //query to check if all the invitations are completed
            List<Kinetics__Kinetic_Job__c> jobListWithCompleted = [SELECT Id, Kinetics__Status__c,
                                                    (SELECT Id FROM Kinetics__Survey_Invitations__r 
                                                        WHERE (Kinetics__Stage__c = :GlobalConstants.completedStage OR Kinetics__Stage__c = :GlobalConstants.expiredStage OR Kinetics__Stage__c = :GlobalConstants.partiallyCompletedStage)
                                                        LIMIT 1)  
                                                    FROM Kinetics__Kinetic_Job__c 
                                                    WHERE Kinetics__Kinetic_Form__c = :invite.Kinetics__Kinetic_Form__c 
                                                    AND Id = :invite.Kinetics__Kinetic_Job__c
                                                    LIMIT 1];
            if(jobListWithCompleted.size() > 0) {
                //query to check if any invitations is non complete
                List<Kinetics__Kinetic_Job__c> jobListWithNonCompleted = [SELECT Id, Kinetics__Status__c,
                                                        (SELECT Id FROM Kinetics__Survey_Invitations__r 
                                                            WHERE (Kinetics__Stage__c != :GlobalConstants.completedStage AND Kinetics__Stage__c != :GlobalConstants.expiredStage )
                                                            LIMIT 1)
                                                        FROM Kinetics__Kinetic_Job__c 
                                                        WHERE Kinetics__Kinetic_Form__c = :invite.Kinetics__Kinetic_Form__c 
                                                        AND Id = :invite.Kinetics__Kinetic_Job__c
                                                        LIMIT 1];
                
                Kinetics__Kinetic_Job__c kcompletedjob = jobListWithCompleted[0];
                Kinetics__Kinetic_Job__c knoncompletedjob = jobListWithNonCompleted[0];
                
                if((kcompletedjob.Kinetics__Survey_Invitations__r != null && kcompletedjob.Kinetics__Survey_Invitations__r.size() > 0)
                    && (knoncompletedjob.Kinetics__Survey_Invitations__r == null 
                        || knoncompletedjob.Kinetics__Survey_Invitations__r != null &&  knoncompletedjob.Kinetics__Survey_Invitations__r.size() == 0)
                    ) {
                    // check if all the invitations are completed and there is no invitation 
                    kcompletedjob.Kinetics__Status__c = GlobalConstants.jobCompletedStatus;
                } else if((kcompletedjob.Kinetics__Survey_Invitations__r != null && kcompletedjob.Kinetics__Survey_Invitations__r.size() > 0)
                    && (knoncompletedjob.Kinetics__Survey_Invitations__r != null &&  knoncompletedjob.Kinetics__Survey_Invitations__r.size() > 0)
                    && knoncompletedjob.Kinetics__Status__c == GlobalConstants.jobNewStatus) {
                    kcompletedjob.Kinetics__Status__c = GlobalConstants.jobInProgressStatus;
                }
                update kcompletedjob;
            }

            createEvents( invites, invite.Kinetics__Kinetic_Form__r.Name, inviteStage);
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

    public static string getDetailsForCalendly(String seqGUID){
        seqCalendlyController.calendlyWrapper calendlyConfig = new seqCalendlyController.calendlyWrapper();
        try {

            List<Kinetics__Survey_Invitation__c> sIList = [SELECT Id, Kinetics__Contact__c FROM Kinetics__Survey_Invitation__c WHERE Kinetics__GUID__c = :seqGUID AND Kinetics__Contact__c != null LIMIT 1];
            if(sIList.size() > 0){
                List<Contact> conList = [SELECT Id, FirstName, LastName, Name, Email FROM Contact WHERE Id =:sIList[0].Kinetics__Contact__c LIMIT 1];
                if(conList.size() > 0) {
                    calendlyConfig.conRec = conList[0];
                }
            }
            
            calendlyConfig.calendlyConfig = Kinetics__Calendly_Settings__c.getInstance();
            return JSON.serialize(calendlyConfig);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public static String invokeGetClientSecretFromAWS(String amountToPayMap){
        String result;
        try{
            APIGatewayUtil.AWSConfig config = new APIGatewayUtil.AWSConfig();
            List<Kinetics__AWS_Config__mdt> awsConfigList = GlobalUtility.getAWSConfigList();

            if(awsConfigList.size() <= 0) {
                result = '{}';
            } else {
                //we are assuming that only one record will be there with the config values... atleast at the time of development
                Kinetics__AWS_Config__mdt awsConfig = awsConfigList[0];

                // fieldko aws sns
                config.accessKey    = awsConfig.Kinetics__Access_Key__c;
                config.accessSecret = awsConfig.Kinetics__Access_Secret__c;
    
                config.awsHost = 'https://fbubya9gbj.execute-api.ap-southeast-2.amazonaws.com';
                config.awsRegion = awsConfig.Kinetics__AWS_Region__c;
                config.awsServiceName = awsConfig.Kinetics__AWS_Service_Name__c;
                config.functionName = 'stripeHelper';
                config.apiMethod = awsConfig.Kinetics__Method__c;
                config.stageName = 'test';

                String requestPayload = amountToPayMap;
                String baseURL = config.awsHost;
                APIGatewayUtil apiGateUtilObj = new APIGatewayUtil(baseURL, config);

                HttpResponse res = apiGateUtilObj.sendRequest(config.functionName, config.apiMethod, requestPayload, config.stageName);
                result = (res!=null && res.getStatusCode() == 200) ? res.getBody() : '{}';
            }
        } catch(Exception ex){
            system.debug('**** ex='+ex.getMessage());
            result = '{}';
        }
  
        return result;
    }
}