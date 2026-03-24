/**
 * Author: Shankar
 * Date: 01-08-2022
 * Purpose: Controller class to host helper methods to send Inspection template to Contact
 */
public with sharing class InspSendInspectionController {
    
    @AuraEnabled
    public static String getTemplateDetailsByInspectionId(String inspectionId){
        InspTemplateResponse sRes = new InspTemplateResponse();
        system.debug('****** inspectionId=' + inspectionId);
        try {
            List<Kinetics__Inspection__c> inspectionRec = [SELECT Id, Name, Kinetics__Account__c, Kinetics__Contact__c, Kinetics__Template__c, 
                                                    Kinetics__Contact__r.Name, Kinetics__Contact__r.Email, Kinetics__Contact__r.MobilePhone,
                                                    Kinetics__Template__r.Name
                                                    FROM Kinetics__Inspection__c 
                                                    WHERE Id =:inspectionId LIMIT 1];

            if(inspectionRec.size() == 0) {
                sRes = getResponseObj('2100', 'Template not found', null);
                return JSON.serialize(sRes);
            }
            sRes = getResponseObj('2000', '', inspectionRec);
            return JSON.serialize(sRes);
        } catch(Exception exp) {
            sRes = getResponseObj('2100', 'Error Occurred ' + exp.getMessage(), null);
            return JSON.serialize(sRes);
        }
    }

    private static InspTemplateResponse getResponseObj(String statusCode, String responseMessage, Object responseDetails) {
        InspTemplateResponse sRes = new InspTemplateResponse();
        sRes.statusCode = statusCode;
        sRes.responseMessage = responseMessage;
        sRes.responseDetails = responseDetails;
        return sRes;
    }

    @AuraEnabled
    public static string updateAnswerToLinkWithSurveyInvitation(String inspectionId, String jobId, List<String> contactIds, String templateId){
        InspTemplateResponse sRes = new InspTemplateResponse();
        try {
            List<Kinetics__Survey_Invitation__c> invites = [SELECT Id FROM Kinetics__Survey_Invitation__c 
                                                            WHERE Kinetics__Contact__c IN :contactIds
                                                            AND Kinetics__Kinetic_Job__c = :jobId
                                                            AND Kinetics__Inspection__c = :inspectionId
                                                            AND Kinetics__Kinetic_Form__c = :templateId];

            if(invites.size() <= 0){
                sRes = getResponseObj('2100', 'Survey Invitation not found', null);
                return JSON.serialize(sRes);
            }

            List<Kinetics__Kinetic_Form_Answer__c> answerList = new List<Kinetics__Kinetic_Form_Answer__c>();
            for(Kinetics__Kinetic_Form_Answer__c kfa: [SELECT Id, Kinetics__Survey_Invitation__c
                                FROM Kinetics__Kinetic_Form_Answer__c 
                                WHERE Kinetics__Inspection__c = :inspectionId]){
                    kfa.Kinetics__Survey_Invitation__c = invites[0].Id;
                    answerList.add(kfa);
            }
            update answerList;

            sRes = getResponseObj('2000', null, 'Answers updated successfully');
            return JSON.serialize(sRes);
        } catch (Exception e) {
            sRes = getResponseObj('2100', 'Error Occurred ' + e.getMessage(), null);
            return JSON.serialize(sRes);
        }

    }
    public class InspTemplateResponse{
        public String statusCode;
        public String responseMessage;
        public Object responseDetails;
    }
}