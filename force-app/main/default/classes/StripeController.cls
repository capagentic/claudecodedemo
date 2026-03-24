/**
 * 
 * Author: Shankar D(FieldKo)
 * Date: 22-03-2022
 * Purpose: Controller class for Strip integration
 */
public without sharing class StripeController {

    @AuraEnabled
    public static string getClientSecret(String seqGUID, String questionId){
        try {
            String amountToPay =  getAmountToPay(seqGUID, questionId);
            
            return GuestUserHandlerHelper.invokeGetClientSecretFromAWS(amountToPay);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getAmountToPay(String seqGUID, String questionId){
        try {
            Map<String, String> bodyMap = new Map<String, String>();

            List<Kinetics__Kinetic_Question__c> questionList = [SELECT Id, Kinetics__Related_To_Object__c, Kinetics__Related_Field_API_Name__c
                                                                FROM Kinetics__Kinetic_Question__c 
                                                                WHERE Id = :questionId AND Kinetics__Status__c = 'Active' 
                                                                LIMIT 1]; 
            if(questionList.size () ==0){
                return JSON.serialize(bodyMap);
            }   
            Kinetics__Kinetic_Question__c questionDetails = questionList[0];
            
            List<Kinetics__Survey_Invitation__c> invites = [SELECT Id, Kinetics__Contact__c, Kinetics__Contact__r.AccountId
                                                            FROM Kinetics__Survey_Invitation__c 
                                                            WHERE Kinetics__GUID__c =: seqGUID];
            if(invites.size() == 0) {
                return JSON.serialize(bodyMap);
            }

            String parentReferenceId = '';
            if(questionDetails.Kinetics__Related_To_Object__c == 'Contact') {
                parentReferenceId = invites[0].Kinetics__Contact__c;
            } else if(questionDetails.Kinetics__Related_To_Object__c == 'Account') {
                parentReferenceId = invites[0].Kinetics__Contact__r.AccountId;
            }
            
            String queryString = ' SELECT Id, ' +  questionDetails.Kinetics__Related_Field_API_Name__c
                                    + ' FROM ' + questionDetails.Kinetics__Related_To_Object__c 
                                    + ' WHERE Id = :parentReferenceId ' ;
            List<sObject> relatedRecordList = Database.query(queryString);

            if(relatedRecordList.size() ==0) {
                return JSON.serialize(bodyMap);
            }

            bodyMap.put('amountToPay', String.valueOf(relatedRecordList[0].get(questionDetails.Kinetics__Related_Field_API_Name__c)));
            bodyMap.put('amountCurrency', UserInfo.getDefaultCurrency());

            return JSON.serialize(bodyMap);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}