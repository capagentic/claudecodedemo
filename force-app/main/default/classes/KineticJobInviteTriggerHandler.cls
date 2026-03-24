/**
* Author: Shankar Dupade(FieldKo)
* Updated : 27th Aug 2021
* Purpose: Handler class for Trigger on Platform Event to create Kinetic Jobs along with Invites
*/
public with sharing class KineticJobInviteTriggerHandler {
    
    public static void handleAfterInsert(List<Kinetics_Jobs_Invites__e> kjInviteList) {
        try {
            for(Kinetics_Jobs_Invites__e kji : kjInviteList) {
                if(String.isBlank(kji.Kinetics__Kinetic_Form_Id__c) 
                    || String.isBlank(kji.Kinetics__Contact_Ids__c)) {
                    continue;
                }

                String surveyId = kji.Kinetics__Kinetic_Form_Id__c;
                List<String> contactIds = new List<String>();
                contactIds.addAll((List<String>)JSON.deserialize(kji.Kinetics__Contact_Ids__c, List<String>.class));

                String delivery = kji.Kinetics__Delivery_Method__c;
                String emailTemplateId = kji.Kinetics__Email_Template_Id__c;
                //this is not required
                String smsContent = kji.Kinetics__SMS_Template__c;

                Boolean sendAutoReminders = kji.Kinetics__Do_Send_Auto_Reminders__c;
                Decimal daysForFirstReminder = kji.Kinetics__Days_For_First_Reminder__c;
                Decimal daysbetweenReminder = kji.Kinetics__Days_Between_Reminder__c;
                Decimal daysbeforerequestexpires = kji.Kinetics__Days_Before_Request_Expires__c;
                String inspectionId = null;
                String formRendererPageUrl = kji.Kinetics__Form_Renderer_Page_URL__c;
                String responseString = SeqSenderController.createJobWithFormURL(surveyId, contactIds, delivery, emailTemplateId, smsContent, 
                                            sendAutoReminders, daysForFirstReminder, daysbetweenReminder, daysbeforerequestexpires,
                                            inspectionId, formRendererPageUrl);
                Map<String, Object> seqResponseObj = (Map<String,Object>)JSON.deserializeUntyped(responseString);

                if(seqResponseObj.containsKey('statusCode') 
                    && String.valueOf(seqResponseObj.get('statusCode')) != '2000') {
                    throw new AuraHandledException(String.valueOf(seqResponseObj.get('responseMessage')));
                }
            }
        }catch(Exception exc) {
            List<String> sendTo = new List<String>();
            //send email to team at Fieldko to inform them about the exceeded usage 
            sendTo.add(UserInfo.getUserEmail());
            String body = 'Dear, ';
            body += '<br/>It looks like something went wrong, please see below error details for more information,';
            body += '<br/>Error Message: ' + exc.getMessage();
            body += '<br/>Thank you';
            String subject = 'URGENT: Error occurred while processing your request';
        
            GlobalUtility.sendEmail(sendTo,subject, body);
        }
    }
}