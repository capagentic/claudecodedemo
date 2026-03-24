public with sharing class KineticAnswerController {
    public KineticAnswerController() {

    }

    @AuraEnabled
    public static String getAnswers(String surveyInviteId){
        KineticAnswerResponse res = new KineticAnswerResponse();
        List<Schema.DescribeFieldResult> kineticAnswersFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Kinetic_Form_Answer__c.Kinetics__Answer_Index__c.getDescribe(),
            Kinetics__Kinetic_Form_Answer__c.Kinetics__Kinetic_Question__c.getDescribe(),
            Kinetics__Kinetic_Form_Answer__c.Kinetics__Kinetic_Form_Question__c.getDescribe(),
            Kinetics__Kinetic_Form_Answer__c.Kinetics__Type__c.getDescribe(),
            Kinetics__Kinetic_Form_Answer__c.Kinetics__Answer__c.getDescribe(),
            Kinetics__Kinetic_Form_Answer__c.Kinetics__Survey_Invitation__c.getDescribe(),
            Kinetics__Kinetic_Form_Answer__c.Kinetics__Kinetic_Question_Values__c.getDescribe()
        };

        try{
            if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Kinetic_Form_Answer__c) 
                && CheckUserPermission.checkFieldsReadAccess(kineticAnswersFieldList))) {
                    throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
            }
            
            List<Kinetics__Kinetic_Form_Answer__c> answersDB = [SELECT Id, Kinetics__Answer_Index__c, Kinetics__Kinetic_Question__c, Kinetics__Kinetic_Question_Values__c, Kinetics__Kinetic_Form_Question__c,
                                                                Kinetics__Type__c, Kinetics__Answer__c
                                                            FROM Kinetics__Kinetic_Form_Answer__c 
                                                            WHERE Kinetics__Survey_Invitation__c =: surveyInviteId
                                                            Order By Kinetics__Answer_Index__c];
            List<KineticAnswer> answers = new List<KineticAnswer>();
            for(Kinetics__Kinetic_Form_Answer__c tsAnswer: answersDB){
                KineticAnswer kAnswer = new KineticAnswer();
                kAnswer.qIndex = tsAnswer.Kinetics__Answer_Index__c;
                kAnswer.qType = tsAnswer.Kinetics__Type__c;
                kAnswer.qValues = tsAnswer.Kinetics__Kinetic_Question_Values__c;
                kAnswer.qTitle = tsAnswer.Kinetics__Kinetic_Question__c;
                kAnswer.answer = tsAnswer.Kinetics__Answer__c;
                kAnswer.recordUrl = '/' + tsAnswer.Id;
                answers.add(kAnswer);
            }

            res.statusCode = '2000';
            res.responseMessage = 'success';
            res.responseDetails = answers;
        }catch(Exception ex){
            res.statusCode = '2100';
            res.responseMessage = ex.getMessage();
            res.responseDetails = ex;
        }
                           
        return JSON.serialize(res);
    }

    public class KineticAnswerResponse{
        String statusCode;
        String responseMessage;
        Object responseDetails;
    }

    public class KineticAnswer{
        Decimal qIndex;
        String qType;
        String qValues;
        String qTitle;
        String answer;
        String recordUrl;
    }
    
}