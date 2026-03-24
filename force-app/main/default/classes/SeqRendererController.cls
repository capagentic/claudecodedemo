public  with sharing class SeqRendererController {
    public SeqRendererController() {

    }

    //this method is called to show all available questions while sending kinetic form to contacts
    @AuraEnabled
    public static String getSequenceById(String surveyId){
        SeqResponse sRes = new SeqResponse();
        system.debug('****** surveyId=' + surveyId);
        try {
            List<Schema.DescribeFieldResult> formQuestionsFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Kinetic_Form_Question__c.Kinetics__Index__c.getDescribe(),
                Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Question__c.getDescribe(),
                Kinetics__Kinetic_Form_Question__c.Kinetics__Kinetic_Form__c.getDescribe()
            };
            if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Question__c) 
                && CheckUserPermission.checkFieldsReadAccess(formQuestionsFieldList))) {
                    throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
            }
            List<Kinetics__Kinetic_Form_Question__c> surveyQuestionList = 
                    [Select Kinetics__Kinetic_Form__r.Name ,
                    Kinetics__Kinetic_Form__r.Kinetics__Instructions__c, 
                    Kinetics__Index__c,
                    Kinetics__Question_Help_Text__c,
                    Kinetics__Kinetic_Question__c,
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
                    Kinetics__Kinetic_Question__r.Kinetics__Custom_Question_Number__c 
                    From Kinetics__Kinetic_Form_Question__c 
                    Where Kinetics__Kinetic_Form__c =: surveyId
                    Order By Kinetics__Index__c];


            List<Kinetics__Kinetic_Form__c> kFormList = [SELECT Id, Name, Kinetics__Template_Metadata__c, Kinetics__Instructions__c FROM Kinetics__Kinetic_Form__c WHERE Id = :surveyId];

            if(surveyQuestionList.isEmpty() && kFormList.isEmpty()){
                sRes.statusCode = '2100';
                sRes.responseMessage = GlobalConstants.surveyNotFoundMessage;
                sRes.responseDetails = null;
                return JSON.serialize(sRes);
            }

            if( !kFormList.isEmpty() &&  String.isNotBlank(kFormList[0].Kinetics__Template_Metadata__c)){
                return SeqRendererController.getSequenceBySurveyGuidForJSONBasedTemplate(kFormList[0].Kinetics__Template_Metadata__c, kFormList);
            }

            List<SeqQuestion> sqList = new List<SeqQuestion>();
            for(Kinetics__Kinetic_Form_Question__c sqDb: surveyQuestionList){
                SeqQuestion sqObj = new SeqQuestion();
                sqObj.index = sqDb.Kinetics__Index__c;
                sqObj.fieldType = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Field_Type__c;
                sqObj.questionDetails = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Question__c;
                sqObj.surveyName = sqDb.Kinetics__Kinetic_Form__r.Name;
                sqObj.questionId = sqDb.Kinetics__Kinetic_Question__c;
                sqObj.helpText = sqDb.Kinetics__Question_Help_Text__c;
                sqObj.questionValues = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Values__c;
                sqObj.qInstructions = '';
                sqList.add(sqObj);
            }      

            sRes.statusCode = '2000';
            sRes.responseMessage = 'Success';
            sRes.responseDetails = sqList;
        }catch(Exception exc) {
            sRes.statusCode = '2100';
            sRes.responseMessage = exc.getMessage();
            sRes.responseDetails = null;
        }
        return JSON.serialize(sRes);
    }

    private static String getSequenceBySurveyGuidForJSONBasedTemplate(String templateMetadata, List<Kinetics__Kinetic_Form__c> kFormList) {
        SeqResponse sRes = new SeqResponse();
        try{
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

                        // if(String.isNotBlank(questionWrap.get('Kinetics__Related_To_Object__c'))
                        //     && String.isNotBlank(questionWrap.get('Kinetics__Related_Field_API_Name__c'))) {
                        //         Set<String> fieldset = new Set<String>();
                        //         if(fieldsByObjectName.containsKey(questionWrap.get('Kinetics__Related_To_Object__c'))) {
                        //             fieldset = fieldsByObjectName.get(questionWrap.get('Kinetics__Related_To_Object__c'));
                        //         }
                        //         fieldset.add(questionWrap.get('Kinetics__Related_Field_API_Name__c'));
                        //         fieldsByObjectName.put(questionWrap.get('Kinetics__Related_To_Object__c'), fieldset);
                        //         fieldNameByQuestionId.put(questionWrap.get('Kinetics__Template_Question_UID__c'), questionWrap.get('Kinetics__Related_Field_API_Name__c'));
                        // }
                    }
                }
            }

            String surveyName = kFormList[0].Name;

            List<SeqRendererController.SeqQuestion> sqList = new List<SeqRendererController.SeqQuestion>();
            Integer indexCount = 1;
            for(Map<String, String> sqDb: questionsList){
               
                SeqRendererController.SeqQuestion sqObj = new SeqRendererController.SeqQuestion();
                
                sqObj.displayIndex = indexCount ++;
                sqObj.index = Decimal.valueOf(sqDb.get('Kinetics__Index__c'));
                sqObj.fieldType = sqDb.get('Kinetics__Type__c');
                sqObj.questionDetails = sqDb.get('Kinetics__Question__c');
                sqObj.surveyName = surveyName;
                sqObj.surveyInviteId = null;
                sqObj.questionId = sqDb.get('Kinetics__Template_Question_UID__c');
                sqObj.surveyQuestionId = sqDb.get('Kinetics__Template_Question_UID__c');
                sqObj.questionValues = sqDb.get('Kinetics__Kinetic_Question_Values__c');
                sqObj.helpText = sqDb.get('Kinetics__Question_Help_Text__c');
                sqObj.stage = null;
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
                
                sqList.add(sqObj);
            }
            if(sqList.size() == 0){
                sRes.statusCode = '2100';
                sRes.responseMessage = GlobalConstants.surveyCompletedMessage;
                sRes.responseDetails = null;
                
                return JSON.serialize(sRes);
            }
            
            sRes.statusCode = '2000';
            sRes.responseMessage = 'Success';
            sRes.responseDetails = sqList;
        }catch(Exception ex){
            sRes.statusCode = '2100';
            sRes.responseMessage = ex.getMessage();
            sRes.responseDetails = null;
        }
        return JSON.serialize(sRes);
    }
    
    @AuraEnabled
    public static String getSequenceBySurveyGuid(String surveyGUID){
        
        return GuestUserHandlerHelper.getSequenceBySurveyGuid(surveyGUID);
    }

    @AuraEnabled
    public static String updateSurvey2InProgress(String surveyGUID){
        return GuestUserHandlerHelper.updateSurvey2InProgress(surveyGUID);
    }

    @AuraEnabled
    public static String saveAnswers(String surveyGUID, String answerJsonString){
        return GuestUserHandlerHelper.saveAnswers(surveyGUID, answerJsonString);
    }

    public class SeqQuestion{
        public String surveyName;
        public String surveyInviteId;
        public String questionDetails;
        public String fieldType;
        public String questionId;
        public String surveyQuestionId;
        public Decimal index;
        public Decimal displayIndex;
        public String questionValues;
        public String answer;
        public String stage;
        public String helpText;
        public String defaultValue;
        public String optionScore;
        public Boolean scoreConfirmed;
        public String qInstructions;
        public String flowName;
    }

    public class SeqAnswer{
        public String index;
        public String questionId;
        public String surveyQuestionId;
        public String answer;
        public String questionDetails;
        public String fieldType;
        public String questionValues;
        public Integer attainedScore;
    }

    public class SeqResponse{
        public String statusCode;
        public String responseMessage;
        public Object responseDetails;
    }
}