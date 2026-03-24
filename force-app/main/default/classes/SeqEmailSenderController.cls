public with sharing class SeqEmailSenderController {
    @InvocableMethod(label='Send Kinetic Links through EMAIL' description='Send Kinetic Links through EMAIL')
    public static void sendLinksEMAIL(List<SendKineticEMAILRequest> emailReqs) {
        // for(SendKineticEMAILRequest emailReq: emailReqs){
        //     SeqEmailSenderController.sendEmailFromInvite(emailReq.inviteId);
        // }
        SeqEmailSenderController.sendEmailFromInvite(emailReqs);
    }
    

    private static void sendEmailFromInvite(List<SendKineticEMAILRequest> emailReqs) {
        List<ExceptionLogController.ExceptionWrapper> eWrapperList = new List<ExceptionLogController.ExceptionWrapper>();
        if(!GlobalUtility.isWithinEMAILAllowedLimit()){
            // need to show message to user on limit reached..
            GlobalUtility.informISVAboutEMAILUsageLimit(); 
            
            ExceptionLogController.ExceptionWrapper ewrper = new ExceptionLogController.ExceptionWrapper();
            ewrper.methodName = 'sendEmailFromInvite';
            ewrper.errorString = 'Kinetic EMAIL invitation has exceeded the allowed limit';
            ewrper.stackTrace = JSON.serialize(emailReqs);
            ewrper.errorCause = null;
            ewrper.affectedRecordId = null;
            eWrapperList.add(ewrper);  
        } else {
            Map<String, Kinetics__Survey_Invitation__c> surveyInvitationById = new Map<String, Kinetics__Survey_Invitation__c>();
            Map<String, String> emailTemplateIdByInvitationId = new Map<String, String>();
            
            for(SendKineticEMAILRequest emailReq: emailReqs){
                surveyInvitationById.put(emailReq.inviteId, null);
            }
            for(Kinetics__Survey_Invitation__c inviteRec: [SELECT Id, Kinetics__Contact__c, Kinetics__Kinetic_Form__c, Kinetics__GUID__c, Kinetics__Stage__c,
                                                                Kinetics__Kinetic_Job__c, Kinetics__Recipient_Email__c, 
                                                                Kinetics__Kinetic_Job__r.Kinetics__Email_Template__c, Kinetics__Kinetic_Job__r.Kinetics__Email_Template_Id__c
                                                                FROM Kinetics__Survey_Invitation__c
                                                                WHERE Id IN :surveyInvitationById.keySet() 
                                                                ]){
                surveyInvitationById.put(inviteRec.Id, inviteRec);
                emailTemplateIdByInvitationId.put(inviteRec.Id, inviteRec.Kinetics__Kinetic_Job__r.Kinetics__Email_Template_Id__c);
            }

            if(emailTemplateIdByInvitationId.size() == 0) {
                throw new AuraHandledException('No Record found for the Invite Id');
            }

           
            List<Messaging.SingleEmailMessage> singleEmailMessageList = new List<Messaging.SingleEmailMessage>();
            Contact dummyContact;
            for(String inviteRecId : surveyInvitationById.keySet()) {
                Kinetics__Survey_Invitation__c inviteRec = surveyInvitationById.get(inviteRecId);
                if(String.isNotBlank(inviteRec.Kinetics__Recipient_Email__c)) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    String[] toAddresses = new String[]{};
                    toAddresses.add(inviteRec.Kinetics__Recipient_Email__c);
                    email.setToAddresses(toAddresses);
            
                    email.setWhatId(inviteRec.Id);
                  
                    if(inviteRec.Kinetics__Contact__c != null){
                        //send email using template Id
                        email.setTemplateId(inviteRec.Kinetics__Kinetic_Job__r.Kinetics__Email_Template_Id__c);
                        email.setTargetObjectId(inviteRec.Kinetics__Contact__c);
                    } else {
                        // List<EmailTemplate> emailTemplates = [SELECT Subject, Description, HtmlValue, DeveloperName, Body 
                        //                              FROM EmailTemplate 
                        //                              WHERE Id =: inviteRec.Kinetics__Kinetic_Job__r.Kinetics__Email_Template_Id__c];

                        // String pageUrl = GlobalUtility.getPageUrl(inviteRec.Kinetics__GUID__c);
                        // String emailBody = SeqEmailSenderController.generateEmailText(pageUrl, emailTemplates[0].Body);
                        // String subject = emailTemplates[0].Subject;
                        // email.setSubject(subject);
                        // email.setHtmlBody(emailBody);
                        dummyContact = new Contact();
                        dummyContact.LastName = 'dummy contactLastName';
                        dummyContact.Email = inviteRec.Kinetics__Recipient_Email__c;
                        insert dummyContact;
                        email.setTemplateId(inviteRec.Kinetics__Kinetic_Job__r.Kinetics__Email_Template_Id__c);
                        email.setTargetObjectId(dummyContact.Id);
                    }

                    email.setSenderDisplayName(UserInfo.getName());
                    email.setReplyTo(UserInfo.getUserEmail());
                    singleEmailMessageList.add(email); 
                }
            }
            Messaging.SendEmailResult [] resultList = Messaging.sendEmail(singleEmailMessageList);
            Integer successFullEmailSendCount = 0;
            if(dummyContact != null) {
                delete dummyContact;
            }

            for(Messaging.SendEmailResult rr:resultList){
                System.debug('Email result ' + rr.IsSuccess());
                if(rr.IsSuccess()) {
                    successFullEmailSendCount = successFullEmailSendCount + 1;
                }
                if(!rr.IsSuccess())
                {
                    Messaging.SendEmailError[] errArr = rr.getErrors();
                    if (errArr.size() > 0){
                        ExceptionLogController.ExceptionWrapper ewrper = new ExceptionLogController.ExceptionWrapper();
                        ewrper.methodName = 'sendEmailFromInvite';
                        ewrper.errorString = errArr[0].getMessage();
                        ewrper.stackTrace = null;
                        ewrper.errorCause = null;
                        ewrper.affectedRecordId = errArr[0].getTargetObjectId();
                        eWrapperList.add(ewrper);
                    }
                }
            }
            
            if(successFullEmailSendCount >0) {
                SeqEmailSenderController.increaseEMAILInvitationCountByCount(successFullEmailSendCount);
            }
        }
        if(eWrapperList.size() > 0) {
            ExceptionLogController.logException(eWrapperList);
        }
    }

    // private static String generateEmailText(String pageUrl, String emailTemplateBody) {
    //     if(String.isBlank(emailTemplateBody)) {
    //         return emailTemplateBody;
    //     }
    //     emailTemplateBody = emailTemplateBody.replace('\n', '<br>');
    //     emailTemplateBody = emailTemplateBody.replace('<![CDATA[', '');
    //     emailTemplateBody = emailTemplateBody.replace(']]>', '');
    //     emailTemplateBody = emailTemplateBody.replace('{{pageUrl}}', pageUrl);
    //     return emailTemplateBody;
    // }
    // private static void sendEmailFromInvite(String inviteId) {
    //     if(!GlobalUtility.isWithinEMAILAllowedLimit()){
    //         // need to show message to user on limit reached..
    //         GlobalUtility.informISVAboutSMSUsageLimit();
            
    //     } else {
    //         List<Kinetics__Survey_Invitation__c> inviteList = [SELECT Id, Kinetics__Contact__c, Kinetics__Kinetic_Form__c, Kinetics__GUID__c, Kinetics__Stage__c,
    //                                                             Kinetics__Kinetic_Job__c, Kinetics__Contact__r.Email, 
    //                                                             Kinetics__Kinetic_Job__r.Kinetics__Email_Template__c, Kinetics__Kinetic_Job__r.Kinetics__Email_Template_Id__c
    //                                                             FROM Kinetics__Survey_Invitation__c
    //                                                             WHERE Id = :inviteId 
    //                                                             LIMIT 1];
    //         if(inviteList.size() == 0) {
    //             throw new AuraHandledException('No Record found for the Invite Id');
    //         }
    //         List<EmailTemplate> emailTemplates = [SELECT Subject, Description, HtmlValue, DeveloperName, Body 
    //                                                 FROM EmailTemplate 
    //                                                 WHERE Id =: inviteList[0].Kinetics__Kinetic_Job__r.Kinetics__Email_Template_Id__c];
    //         String pageUrl = GlobalUtility.getPageUrl(inviteList[0].Kinetics__GUID__c);
    //         String emailBody = SeqEmailSenderController.generateEmailText(pageUrl, inviteList[0].Kinetics__Kinetic_Job__r.Kinetics__Email_Template__c);
    //         //String emailBody = SeqEmailSenderController.generateEmailText(pageUrl, emailTemplates[0].HtmlValue);
    //         String subject = emailTemplates[0].Subject;// 'Kinetic Form Email';
    //         if(String.isNotBlank(inviteList[0].Kinetics__Contact__r.Email)
    //         && String.isNotBlank(emailBody)) {
    //             Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    //             String[] toAddresses = new String[]{};
    //             toAddresses.add(inviteList[0].Kinetics__Contact__r.Email);
    //             email.setToAddresses(toAddresses);
                
    //             //send email using template Id
    //             email.setTemplateId(inviteList[0].Kinetics__Kinetic_Job__r.Kinetics__Email_Template_Id__c);
                
    //             // send email witj template body
    //             // email.setSubject(subject);
    //             // email.setHtmlBody(emailBody);
                
    //             //email.setWhatId(inviteList[0].Id);
    //             //email.setTargetObjectId(inviteList[0].Kinetics__Contact__c);
    //             email.setTargetObjectId(inviteList[0].Id);
    //             email.setSenderDisplayName(UserInfo.getName());
    //             email.setReplyTo(UserInfo.getUserEmail());
    //             Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    //         }
    //         SeqEmailSenderController.increaseEMAILInvitationCountByOne();
    //     }
    // }
    // @future
    // private static void increaseEMAILInvitationCountByOne() {
    //     GlobalUtility.increaseEMAILInvitationCountByOne();
    // }
    @future
    private static void increaseEMAILInvitationCountByCount(Integer countToIncrease) {
        GlobalUtility.increaseEMAILInvitationCountByCount(countToIncrease);
    }

    public class SendKineticEMAILRequest {
        @InvocableVariable(required=true)
        public String inviteId;
    }
}