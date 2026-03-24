/*
* Auther: Shankar Dupade
* Purpose: Helper class to support functionalities to create / edit Kinetic Form from LWC component
* Date: 05th-Aug-2021
*/
public with sharing class createEditKineticFormLWCHelper {
    transient static List<Schema.DescribeFieldResult> kineticFormFieldList;

    public static List<Schema.DescribeFieldResult> createKineticFormFieldList(){ 
        kineticFormFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Kinetic_Form__c.Name.getDescribe(), 
            Kinetics__Kinetic_Form__c.Kinetics__Status__c.getDescribe(),
            Kinetics__Kinetic_Form__c.Kinetics__Instructions__c.getDescribe()
                                           };
        List<Map<String, String>> fldMapList = new List<Map<String, String>>();
        String fieldSetfields = getExtraFields('Kinetics__Kinetic_Form__c','Kinetics__More_Details');
        
        fldMapList = (List<Map<String, String>>) JSON.deserialize(fieldSetfields, List<Map<String, String>>.class);
        
        for (Map<String, String> fielddetails : fldMapList) {  
            if(fielddetails.containsKey('fieldPath')
             && String.valueOf(fielddetails.get('fieldPath')) != 'Name' 
             && String.valueOf(fielddetails.get('fieldPath')) != 'Kinetics__Status__c'
             && String.valueOf(fielddetails.get('fieldPath')) != 'Kinetics__Instructions__c'){
                String field = fielddetails.get('fieldPath'); 
                kineticFormFieldList.add(Kinetics__Kinetic_Form__c.getSobjectType().getDescribe().fields.getMap().get(field).getDescribe());
            }
        }
    
        return kineticFormFieldList;
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

    //This Function will check weather custom setting survey show Instruction is checked or not, and display field on layout respectively.
    @AuraEnabled
    public static String getSurveyConfigurationCustomSetting() {
        return ('[{"isEnabled" : "true"}]');
    }

    @AuraEnabled
    public static Boolean checkPermissions(){

        createEditKineticFormLWCHelper.createKineticFormFieldList();
        if(!(CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Kinetic_Form__c) && 
            CheckUserPermission.checkFieldsUpdateAccess(createEditKineticFormLWCHelper.kineticFormFieldList) &&
            CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Kinetics__Kinetic_Form__c) &&
            CheckUserPermission.checkFieldsCreateAccess(createEditKineticFormLWCHelper.kineticFormFieldList))) {
                //need to update the message
                throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }
        return true;
    }

    @AuraEnabled
    public static string getExistingKineticForms(String recordId){
      
        if(String.isNotEmpty(recordId)) {
            createEditKineticFormLWCHelper.createKineticFormFieldList();
            if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Kinetic_Form__c)
                && CheckUserPermission.checkFieldsReadAccess(createEditKineticFormLWCHelper.kineticFormFieldList))) {
                throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
            }

            String extraFields = createEditKineticFormLWCHelper.getExtraFields('Kinetics__Kinetic_Form__c', 'Kinetics__More_Details');
            List<Map<String, String>> lstFSMember = (List<Map<String, String>>) JSON.deserialize(extraFields, List<Map<String, String>>.class);
            String queryString = 'SELECT Id, Name, Kinetics__Instructions__c, Kinetics__Status__c, Kinetics__Questions_By_Page_No__c,Kinetics__Section_Metadata__c ';
                
            for(Map<string, String> lst: lstFSMember) {
                if(String.valueOf(lst.get('fieldPath')) != 'Name'
                    && String.valueOf(lst.get('fieldPath')) != 'Kinetics__Instructions__c'
                    && String.valueOf(lst.get('fieldPath')) != 'Id'
                    && String.valueOf(lst.get('fieldPath')) != 'Kinetics__Status__c'
                    && String.valueOf(lst.get('fieldPath')) != 'Kinetics__Questions_By_Page_No__c'
                    && String.valueOf(lst.get('fieldPath')) != 'Kinetics__Section_Metadata__c'){
                    queryString = queryString + ', ' + lst.get('fieldPath');
                }
            }
            
            queryString = queryString + ' FROM Kinetics__Kinetic_Form__c WHERE Id =: recordId LIMIT 1';
            return JSON.serialize(Database.query(queryString));
        } else {
            return JSON.serialize(new List<Kinetics__Kinetic_Form__c>());
        }
    }

    @AuraEnabled
    public static void doDirtyDataCleanup(String recordId, Boolean isDelete){
       
        if(!(CheckUserPermission.checkObjectDeleteAccess(Schema.sObjectType.Kinetics__Kinetic_Form__c))) {
            throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }

        List<Kinetics__Kinetic_Form__c> recList = [SELECT Id FROM Kinetics__Kinetic_Form__c 
                                                        WHERE Id = :recordId LIMIT 1];
        
        if(recList.size() == 0) { 
            return;
        }
        
        if(isDelete){
            delete recList;
        }
    }

    @AuraEnabled
    public static String getAllActiveKineticQuestions(String kFormId){

        List<Kinetics__Kinetic_Question__c> kQuestionDefList = new List<Kinetics__Kinetic_Question__c>();
        List<Kinetics__Kinetic_Question__c> kSelectedQuesDefList = new List<Kinetics__Kinetic_Question__c>();
        List<String> kQuestionId = new List<String>();
        List<Schema.DescribeFieldResult> kineticFormQuestFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Question__c.getDescribe(),
            Kinetics__Kinetic_Form_Question__c.Kinetics__Question_Help_Text__c.getDescribe(),
            Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Form__c.getDescribe()
        };
        List<Schema.DescribeFieldResult> kineticQuestionFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Kinetic_Question__c.Kinetics__Question__c.getDescribe(),
            Kinetics__Kinetic_Question__c.Kinetics__Field_Type__c.getDescribe(),
            Kinetics__Kinetic_Question__c.Kinetics__Question_Help_Text__c.getDescribe(),
            Kinetics__Kinetic_Question__c.Kinetics__Values__c.getDescribe()
        };
        
        if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Question__c) 
            && CheckUserPermission.checkFieldsReadAccess(kineticFormQuestFieldList))) {
            throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }

        if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Kinetic_Question__c) 
            && CheckUserPermission.checkFieldsReadAccess(kineticQuestionFieldList))) {
            throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }

        if(kFormId != null) {
            for(Kinetics__Kinetic_Form_Question__c sq : [SELECT Kinetics__Kinetic_Question__c, Kinetics__Kinetic_Form__c, Kinetics__Question_Help_Text__c, Kinetics__Option_Score__c, Kinetics__Score_Confirmed__c 
                                                        FROM Kinetics__Kinetic_Form_Question__c 
                                                        WHERE Kinetics__Kinetic_Form__c = :kFormId] ){
                kQuestionId.add(sq.Kinetics__Kinetic_Question__c); 
            }
            
            kSelectedQuesDefList = [SELECT Id, Name, Kinetics__Question__c, Kinetics__Field_Type__c, Kinetics__Values__c,Kinetics__Question_Help_Text__c,
                                    (SELECT Id, Kinetics__Index__c, Kinetics__Question_Help_Text__c, Kinetics__Option_Score__c, Kinetics__Score_Confirmed__c FROM  Kinetics__Kinetic_Form_Questions__r  WHERE Kinetics__Kinetic_Form__c =:kFormId) 
                                    FROM Kinetics__Kinetic_Question__c 
                                    WHERE Kinetics__Status__c = 'Active' AND Id In :kQuestionId 
                                    ORDER BY Name];
                
            kQuestionDefList.addAll([SELECT Id, Name, Kinetics__Question__c, Kinetics__Field_Type__c, Kinetics__Values__c,Kinetics__Question_Help_Text__c,
                                    (SELECT Id, Kinetics__Index__c, Kinetics__Question_Help_Text__c, Kinetics__Option_Score__c, Kinetics__Score_Confirmed__c FROM  Kinetics__Kinetic_Form_Questions__r  WHERE Kinetics__Kinetic_Form__c =:kFormId)
                                    FROM Kinetics__Kinetic_Question__c 
                                    WHERE Kinetics__Status__c = 'Active' AND Id not In :kQuestionId 
                                    ORDER BY Name DESC
                                    LIMIT 10000]);            
        }
        else{        
            kQuestionDefList = [SELECT Id, Name, Kinetics__Question__c, Kinetics__Field_Type__c, Kinetics__Values__c, Kinetics__Question_Help_Text__c
                                FROM Kinetics__Kinetic_Question__c 
                                WHERE Kinetics__Status__c = 'Active' 
                                ORDER BY Name DESC
                                LIMIT 10000]; 
        }
        if(kSelectedQuesDefList.size() < 1 && kQuestionDefList.size() < 1){
            throw new AuraHandledException(System.Label.Kinetics.No_active_questions_found_Please_create_some_active_questions);
        }

        Map<String, List<Kinetics__Kinetic_Question__c>> kQuestionWrapperMap = new Map<String, List<Kinetics__Kinetic_Question__c>>();
        kQuestionWrapperMap.put('kSelectedQuesDefList', kSelectedQuesDefList);
        kQuestionWrapperMap.put('kQuestionDefList', kQuestionDefList);
        return JSON.serialize(kQuestionWrapperMap);
    }

    @AuraEnabled
    public static void upsertKineticQuestions(String listwrapperString, String kFormId, String existingKFormQuestionIdsString){
        List<Schema.DescribeFieldResult> kineticFormQuestFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Question__c.getDescribe(),
            Kinetics__Kinetic_Form_Question__c.Kinetics__Index__c.getDescribe(),
            Kinetics__Kinetic_Form_Question__c.Kinetics__Question_Help_Text__c.getDescribe(),
            Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Form__c.getDescribe(),
            Kinetics__Kinetic_Form_Question__c.Kinetics__Option_Score__c.getDescribe(),
            Kinetics__Kinetic_Form_Question__c.Kinetics__Score_Confirmed__c.getDescribe()
        };
        if(!(CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Question__c) 
            && CheckUserPermission.checkFieldsCreateAccess(kineticFormQuestFieldList)
            && CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Question__c) 
            && CheckUserPermission.checkFieldsUpdateAccess(kineticFormQuestFieldList))) {
            throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }
        if(!(CheckUserPermission.checkObjectDeleteAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Question__c))) {
            throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }

        List<Map<String, String>> listOfRecords = (List<Map<String, String>>) JSON.deserialize(listwrapperString, List<Map<String, String>>.class);
        List<Kinetics__Kinetic_Form_Question__c> kFormQuestionList = new List<Kinetics__Kinetic_Form_Question__c>();
        Set<String> existingKFormQuestionsIds = new Set<String>();
        existingKFormQuestionsIds = (Set<String>) JSON.deserialize(existingKFormQuestionIdsString, Set<String>.class);
        
        Integer numberOfAllowedQuestionsPerForm = getNumberOfAllowedQuestionsPerForm();
        if(numberOfAllowedQuestionsPerForm < listOfRecords.size()) {
            throw new AuraHandledException(GlobalConstants.allowedQuestionsLimitExceededString.replace('{{numberOfAllowedQuestionsPerForm}}', String.valueOf(numberOfAllowedQuestionsPerForm)));
        }

        for(Map<String, String> rec: listOfRecords) {
            Kinetics__Kinetic_Form_Question__c sq;
            if(rec.containsKey('surveyQuestionId')){
                sq = new Kinetics__Kinetic_Form_Question__c(Id = rec.get('surveyQuestionId'));
                existingKFormQuestionsIds.remove(rec.get('surveyQuestionId'));
            } else {
                sq = new Kinetics__Kinetic_Form_Question__c();
            }
            sq.Kinetics__Kinetic_Form__c = kFormId;
            sq.Kinetics__Kinetic_Question__c = rec.get('qid');
            sq.Kinetics__Index__c = Decimal.valueOf(rec.get('index'));
            sq.Kinetics__Question_Help_Text__c = rec.get('helpText');
            sq.Kinetics__Option_Score__c =rec.get('scoreSetting');
            sq.Kinetics__Score_Confirmed__c = rec.get('scoreConfirmed') != null ? Boolean.valueOf(rec.get('scoreConfirmed')): false;
            kFormQuestionList.add(sq);
        }
        //delete the existing Survey Questions which are removed from survey
        delete [SELECT Id FROM Kinetics__Kinetic_Form_Question__c WHERE Id IN :existingKFormQuestionsIds];

        upsert kFormQuestionList;
    }
    @AuraEnabled
    public static Integer getNumberOfAllowedQuestionsPerForm(){
        try {
            return GlobalUtility.getNumberOfAllowedQuestionsPerForm();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}