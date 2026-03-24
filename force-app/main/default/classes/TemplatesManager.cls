public with sharing class TemplatesManager {
    

    @AuraEnabled
    public static String getAllTemplateDetailsByTemplateId(String templateId){
        String result;
        try {
            if(String.isBlank(templateId)) {
                return null;
            }

            List<Kinetics__Kinetic_Form__c> templates = [Select Kinetics__Instructions__c, Kinetics__Number_Of_Questions__c, Kinetics__Questions_By_Page_No__c, Name
                                                            From Kinetics__Kinetic_Form__c
                                                            Where Id =:  templateId];
            if(templates.isEmpty()){
                return null;
            }                               
            Kinetics__Kinetic_Form__c template = templates.get(0);

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
                    Kinetics__Kinetic_Question__r.Kinetics__Custom_Question_Number__c 
                    From Kinetics__Kinetic_Form_Question__c 
                    Where Kinetics__Kinetic_Form__c = :templateId
                    Order By Kinetics__Index__c ASC];

            if(templateQuestionList.isEmpty()){
                return null;
            }

            List<templateQuestionWrapper> tempQuestionList = new List<templateQuestionWrapper>();
            Integer indexCount = 1;
            for(Kinetics__Kinetic_Form_Question__c sqDb: templateQuestionList){
                templateQuestionWrapper sqObj = new templateQuestionWrapper();
                sqObj.index = sqDb.Kinetics__Index__c;
                sqObj.helpText = sqDb.Kinetics__Question_Help_Text__c;
                sqObj.fieldType = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Field_Type__c;
                sqObj.questionDetails = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Question__c;
                // sqObj.questionId = sqDb.Kinetics__Kinetic_Question__c;
                // sqObj.templateQuestionId = sqDb.Id;
                sqObj.questionValues = sqDb.Kinetics__Kinetic_Question__r.Kinetics__Values__c;
                sqObj.displayIndex = indexCount++;
                sqObj.totalNumberOfTasksCreated = 0;
                sqObj.totalNumberOfNotesCreated = 0;
                sqObj.totalNumberOfFilesUploaded = 0;
                sqObj.scoreByOption = sqDb.Kinetics__Option_Score__c;
                sqObj.scoreConfirmed = sqDb.Kinetics__Score_Confirmed__c != null ? Boolean.valueOf(sqDb.Kinetics__Score_Confirmed__c): false;
                tempQuestionList.add(sqObj);
            }

            Map<String, Object> responseObj = new Map<String, Object>();
            responseObj.put('tempQuestionList', tempQuestionList);
            responseObj.put('template', template);
            result = JSON.serialize(responseObj);
        } catch(Exception exc) {
            result = null;
        }
        return result;
    }

    public class templateQuestionWrapper { 
        //public String templateName;
        public String questionDetails;
        public String helpText;
        public String fieldType;
        // public String questionId;
        // public String templateQuestionId;
        public Decimal index;
        public Decimal displayIndex;
        public String questionValues;
        // public String answer;
        public String defaultValue;
        public Integer totalNumberOfTasksCreated;
        public Integer totalNumberOfNotesCreated;
        public Integer totalNumberOfFilesUploaded;
        //public String noteId;
        //public String shortNoteDescription;
        // public String existingAnswerId;
        public String scoreByOption;
        public Boolean scoreConfirmed;
        public Integer scoreAttained;
    }
}