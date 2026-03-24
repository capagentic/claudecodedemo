/*
* Auther: Shankar Dupade
* Purpose: Helper class to support functionalities to create / edit Kinetic question from LWC component
* Date: 05-08-2021
*/
public with sharing class createEditKineticQuestionLWCHelper {
    transient static List<Schema.DescribeFieldResult> kineticQuestionDefinitionFieldList;
    public static void createKineticQuestionDefinitionFieldList(){ 
        kineticQuestionDefinitionFieldList = new List<Schema.DescribeFieldResult>{
                                              Kinetics__Kinetic_Question__c.Kinetics__Default_Value__c.getDescribe(), 
                                              Kinetics__Kinetic_Question__c.Kinetics__Field_Type__c.getDescribe(),
                                              Kinetics__Kinetic_Question__c.Kinetics__Take_Photo__c.getDescribe(),
                                              Kinetics__Kinetic_Question__c.Kinetics__Is_Photo_Mandatory__c.getDescribe(), 
                                              Kinetics__Kinetic_Question__c.Kinetics__Question__c.getDescribe(), 
                                              Kinetics__Kinetic_Question__c.Kinetics__Status__c.getDescribe(),
                                              Kinetics__Kinetic_Question__c.Kinetics__Values__c.getDescribe(),
                                              Kinetics__Kinetic_Question__c.Kinetics__Has_Followup_Questions__c.getDescribe() 
                                           };  
    }

    @AuraEnabled (cacheable=true)
    public static String getExtraFields(String objectname, String fieldsetName) {
        
        if(String.isNotEmpty(objectname) && String.isNotEmpty(fieldsetName)){
            //get fields from FieldSet
            SObject sObj = (SObject)(Type.forName('Schema.'+ objectname).newInstance());
            List<Schema.FieldSetMember> lstFSMember = new List<Schema.FieldSetMember>();
            if(sObj.getSObjectType().getDescribe().fieldSets.getMap().get(fieldsetName) != null) {
                lstFSMember = sObj.getSObjectType().getDescribe().fieldSets.getMap().get(fieldsetName).getFields();
            }
            return JSON.serialize(lstFSMember);
        }
        return '[]';
    }

    @AuraEnabled
    public static string getKineticFormConfigurationCustomSetting(){
        
        return ('{"ArxxusRFMv1__Show_Custom_Question_Number__c" :"true"}');
    }

    @AuraEnabled
    public static Boolean checkPermissions(){
        createEditKineticQuestionLWCHelper.createKineticQuestionDefinitionFieldList();
        if(!(CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Kinetic_Question__c) && 
            CheckUserPermission.checkFieldsUpdateAccess(createEditKineticQuestionLWCHelper.kineticQuestionDefinitionFieldList) &&
            CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Kinetics__Kinetic_Question__c) &&
            CheckUserPermission.checkFieldsCreateAccess(createEditKineticQuestionLWCHelper.kineticQuestionDefinitionFieldList))) {
                throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }
        return true;
    }

    @AuraEnabled
    public static string getExistingKineticQuestion(String recordId){
        if(String.isNotEmpty(recordId)) {
            createEditKineticQuestionLWCHelper.createKineticQuestionDefinitionFieldList();
            if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Kinetic_Question__c) && 
                CheckUserPermission.checkFieldsReadAccess(createEditKineticQuestionLWCHelper.kineticQuestionDefinitionFieldList))) {
                    throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
            }

            String extraFields = createEditKineticQuestionLWCHelper.getExtraFields('Kinetics__Kinetic_Question__c', 'Kinetics__More_Details');
            List<Map<String, String>> lstFSMember = (List<Map<String, String>>) JSON.deserialize(extraFields, List<Map<String, String>>.class);
            String queryString = 'SELECT Id, Name, Kinetics__Default_Value__c, Kinetics__Field_Type__c, Kinetics__Take_Photo__c, Kinetics__Is_Photo_Mandatory__c,'
                                + 'Kinetics__Question__c, Kinetics__Status__c, Kinetics__Values__c, Kinetics__Has_Followup_Questions__c,'
                                + 'Kinetics__Assign_Tasks__c, Kinetics__Attach_Photos_or_Files__c,Kinetics__Capture_Notes__c';
                
            for(Map<string, String> lst: lstFSMember) {
                queryString = queryString + ', ' + lst.get('fieldPath');
            }
            
            queryString = queryString + ' FROM Kinetics__Kinetic_Question__c WHERE Id =: recordId LIMIT 1';
            return JSON.serialize(Database.query(queryString));
        } else {
            return JSON.serialize(new List<Kinetics__Kinetic_Question__c>());
        }
    }
  
    @AuraEnabled
    public static String uploadFile(String base64, String filename, String recordId, String title) {
        String fileExtension = '';
        
        ContentVersion cv = FileService.upsertNewFile(title, fileExtension, filename, EncodingUtil.base64Decode(base64), null, Id.valueOf(recordId));
        return cv.Id;
    }

    @AuraEnabled
    public static String getRelatedFileIds(String questionId){
        // Get the option Attachment Name
        Map<String,String> fileAttachTitleVsId = new Map<String,String>();
        if(String.isEmpty(questionId)) {
            return JSON.serialize(fileAttachTitleVsId);
        }
        Map<Id,FileAttachmentWrapper> fileAttachWrapper = FileAttachmentService.getFileAttachmentRecords(new Set<Id> { questionId });
        if(fileAttachWrapper != null) {
            FileAttachmentWrapper wrapper = fileAttachWrapper.get(questionId);
            if(wrapper != null) {
                if(wrapper.contentVersionRecords != null) {
                    for(ContentVersion fileRecord : wrapper.contentVersionRecords) {
                        String fileTitle = fileRecord.Title.removeEnd(questionId);
                        fileAttachTitleVsId.put(fileTitle,fileRecord.Id);
                    }
                }
            }
        }
        return JSON.serialize(fileAttachTitleVsId);
    }

    @AuraEnabled
    public static void deleteExistingFiles(String questionId, List<String> contentVersionIds){
        List<ContentVersion> contentVersionRecords = [SELECT Id, ContentDocumentId 
                                                        FROM ContentVersion WHERE Id IN :contentVersionIds];
        FileService.deleteAllFiles(contentVersionRecords);
    }

    @AuraEnabled
    public static void doDirtyDataCleanup(String questionId, Boolean isDelete){
        
        createEditKineticQuestionLWCHelper.createKineticQuestionDefinitionFieldList();
        if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Kinetic_Question__c) 
            && CheckUserPermission.checkFieldsReadAccess(createEditKineticQuestionLWCHelper.kineticQuestionDefinitionFieldList)
            && CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Kinetic_Question__c) 
            && CheckUserPermission.checkFieldsUpdateAccess(createEditKineticQuestionLWCHelper.kineticQuestionDefinitionFieldList)
            && CheckUserPermission.checkObjectDeleteAccess(Schema.sObjectType.Kinetics__Kinetic_Question__c) 
            && CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Followup_Question__c)
            && CheckUserPermission.checkObjectDeleteAccess(Schema.sObjectType.Kinetics__Followup_Question__c))) {
                throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }
        
        List<Kinetics__Kinetic_Question__c> qList = [SELECT Id, Kinetics__Values__c, Kinetics__Default_Value__c, Kinetics__Has_Followup_Questions__c,
                                                        Kinetics__Field_Type__c
                                                        FROM Kinetics__Kinetic_Question__c 
                                                        WHERE Id = :questionId LIMIT 1];
        
        if(qList.size() == 0) { 
            return;
        }
        System.debug('qList: ' + qList.size());
        Kinetics__Kinetic_Question__c qd = qList[0];
        qd.Kinetics__Has_Followup_Questions__c = false;

        if(String.isNotEmpty(qd.Kinetics__Values__c)) {
            String valuesStr = qd.Kinetics__Values__c.toLowerCase();
            List<Kinetics__Followup_Question__c>  followUpQuestionsList = [SELECT Id, Name, Kinetics__Parent_Option_Value__c 
            FROM Kinetics__Followup_Question__c WHERE Kinetics__Parent_Question__c =: qd.Id];   

            List<Kinetics__Followup_Question__c> remainingFQs = new List<Kinetics__Followup_Question__c>();
            List<Kinetics__Followup_Question__c> followUpQuestionsToBeDeleted = new List<Kinetics__Followup_Question__c>();
            System.debug('followUpQuestionsList: ' + followUpQuestionsList.size());
            for(Kinetics__Followup_Question__c followupQuestion : followUpQuestionsList) {
                String parentOptVal = followupQuestion.Kinetics__Parent_Option_Value__c.toLowerCase();

                if(valuesStr.contains(parentOptVal)) {
                    remainingFQs.add(followupQuestion);
                } else {
                    followUpQuestionsToBeDeleted.add(followupQuestion);
                }

                if(qd.Kinetics__Field_Type__c != 'Radio Button' || isDelete) {
                    followUpQuestionsToBeDeleted.add(followupQuestion);
                }
            }

            if(!remainingFQs.isEmpty() && isDelete == false) {
                qd.Kinetics__Has_Followup_Questions__c = true;
                update qd;
            }

            
            delete followUpQuestionsToBeDeleted;
        }
        if(isDelete){
            delete qList;
        }
    }
}