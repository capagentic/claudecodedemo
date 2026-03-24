public with sharing class SeqSenderController {
    public SeqSenderController() {

    }
    @InvocableMethod(label='Send Kinetic Links through SMS' description='Send Kinetic Links through SMS')
    public static void sendLinksSMS(List<SendKineticSMSRequest> smsReqs) {
        for(SendKineticSMSRequest smsReq: smsReqs){
            //the contactId attribute is not changed but it is taking any record id
            SeqSenderController.sendSmsFromInvite(smsReq.guid, smsReq.contactId);
        }
    }

    public static String createJobWithFormURL(String surveyId, List<String> contactIds, String delivery, String emailTemplateId, String smsContent,
                                            Boolean sendAutoReminders, Decimal daysForFirstReminder, Decimal daysbetweenReminder, Decimal daysbeforerequestexpires,
                                            String inspectionId, String formRendererPageUrl) {
                                                
        SeqResponse res = new SeqResponse();

        try{
            List<Schema.DescribeFieldResult> kineticJobFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Kinetic_Job__c.Kinetics__Status__c.getDescribe(),
                Kinetics__Kinetic_Job__c.Kinetics__Delivery_Method__c.getDescribe(),
                Kinetics__Kinetic_Job__c.Kinetics__SMS_Template__c.getDescribe(),
                Kinetics__Kinetic_Job__c.Kinetics__Email_Template__c.getDescribe(),
                Kinetics__Kinetic_Job__c.Kinetics__Email_Template_Id__c.getDescribe(),
                Kinetics__Kinetic_Job__c.Kinetics__Kinetic_Form__c.getDescribe()
            };
            List<Schema.DescribeFieldResult> surveyInvitationFieldList = new List<Schema.DescribeFieldResult>{
                Kinetics__Survey_Invitation__c.Kinetics__Days_before_First_Reminder__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Days_between_two_reminders__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Send_Auto_Reminders__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Contact__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Form__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__GUID__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Job__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Stage__c.getDescribe(),
                Kinetics__Survey_Invitation__c.Kinetics__Inspection__c.getDescribe()
            };
            List<Schema.DescribeFieldResult> eventFieldList = new List<Schema.DescribeFieldResult>{
                Event.Subject.getDescribe(),
                Event.Description.getDescribe(),
                Event.WhatId.getDescribe(),
                Event.WhoId.getDescribe(),
                Event.ActivityDate.getDescribe(),
                Event.DurationInMinutes.getDescribe(),
                Event.ActivityDateTime.getDescribe()
            };
            if(!(CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Kinetics__Kinetic_Job__c) 
                && CheckUserPermission.checkFieldsCreateAccess(kineticJobFieldList)
                && CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
                && CheckUserPermission.checkFieldsCreateAccess(surveyInvitationFieldList)
                && CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Event) 
                && CheckUserPermission.checkFieldsCreateAccess(eventFieldList))) {
                    throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
            }
    
            Kinetics__Kinetic_Job__c job = new Kinetics__Kinetic_Job__c();
            job.Kinetics__Status__c = 'New';
            if(delivery.equalsIgnoreCase('sms')) {
                job.Kinetics__Delivery_Method__c = GlobalConstants.deliveryMethodSMS;
                job.Kinetics__SMS_Template__c = String.isNotEmpty(smsContent)? smsContent: getSmsTemplate();
            } else if(delivery.equalsIgnoreCase('email')) {
                job.Kinetics__Delivery_Method__c = GlobalConstants.deliveryMethodEMAIL;
                job.Kinetics__Email_Template_Id__c = emailTemplateId;
                // if(String.isNotBlank(emailTemplateId)) {
                //     List<EmailTemplate> emailTemplates = [SELECT Subject, Description, HtmlValue, DeveloperName, Body 
                //                                             FROM EmailTemplate 
                //                                             WHERE Id =: emailTemplateId 
                //                                             LIMIT 1];
                //     if(emailTemplates.size() > 0) {
                //         job.Kinetics__Email_Template__c = emailTemplates[0].HtmlValue;
                //         if(String.isBlank(job.Kinetics__Email_Template__c) && String.isNotBlank(emailTemplates[0].Body)) {
                //             job.Kinetics__Email_Template__c = emailTemplates[0].Body;
                //         }
                //     }
                // }
            }
            
            job.Kinetics__Kinetic_Form__c = surveyId;
            insert job;

            Kinetics__Kinetic_Job__c jobDB = [SELECT Id, Name, Kinetics__Kinetic_Form__r.Name FROM Kinetics__Kinetic_Job__c WHERE Id =: job.Id];
    
            List<Kinetics__Survey_Invitation__c> invites = new List<Kinetics__Survey_Invitation__c>();
            Id recordId = Id.valueOf(contactIds[0]);
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            Kinetics__Kinetic_Link_Recipient_Configuration__mdt confObj = getRequiredRecordForSurveyInvitaion(sObjName);
    
            List<sObject> recordList = getRelatedParentRecordList(confObj, contactIds);
    
            if(recordList.size() == 0) {
                return 'No record Found';
            }

            for(sObject sObjectRecord: recordList){
                Kinetics__Survey_Invitation__c inv = generateInvitation(confObj, sObjectRecord, surveyId, job.Id, false);
                inv.Kinetics__Days_before_First_Reminder__c = daysForFirstReminder;
                inv.Kinetics__Days_between_two_reminders__c = daysbetweenReminder;
                inv.Kinetics__TTL_Day__c = daysbeforerequestexpires;
                inv.Kinetics__Send_Auto_Reminders__c = sendAutoReminders;
                inv.Kinetics__Inspection__c = inspectionId;
                inv.Kinetics__Form_Renderer_Page_Base_Url__c = GlobalUtility.getFormRendererPageURL(formRendererPageUrl);

                if(delivery.equalsIgnoreCase('sms')) {
                    inv.Kinetics__Channel__c = GlobalConstants.channelSMS;
                } else if(delivery.equalsIgnoreCase('email')) {
                    inv.Kinetics__Channel__c = GlobalConstants.channelEMAIL;
                }
                invites.add(inv);
            }
            insert invites;

            createEvents( invites, jobDB.Kinetics__Kinetic_Form__r.Name, 'Sent');

            res.statusCode = '2000';
            res.responseMessage = 'success';
            res.responseDetails = jobDB;
        }catch(Exception ex){
            res.statusCode = '2100';
            res.responseMessage = ex.getMessage();
            res.responseDetails = null;
        }

        return JSON.serialize(res);
    }
    
    @AuraEnabled 
    public static String createJob(String surveyId, List<String> contactIds, String delivery, String emailTemplateId, String smsContent,
                                    Boolean sendAutoReminders, Decimal daysForFirstReminder, Decimal daysbetweenReminder, Decimal daysbeforerequestexpires,
                                    String inspectionId) {
        String formRendererPageUrl = null;
        return createJobWithFormURL(surveyId, contactIds, delivery, emailTemplateId, smsContent, sendAutoReminders, 
                                    daysForFirstReminder, daysbetweenReminder, daysbeforerequestexpires, inspectionId, 
                                    formRendererPageUrl);
    }

    public static void createEvents(List<Kinetics__Survey_Invitation__c> invites, String surveyName, String stage){
        List<Event> eList = new List<Event>();
        List<Schema.DescribeFieldResult> eventFieldList = new List<Schema.DescribeFieldResult>{
            Event.Subject.getDescribe(),
            Event.Description.getDescribe(),
            Event.WhatId.getDescribe(),
            Event.WhoId.getDescribe(),
            Event.ActivityDate.getDescribe(),
            Event.DurationInMinutes.getDescribe(),
            Event.ActivityDateTime.getDescribe()
        };
        if(!(CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Event) 
            && CheckUserPermission.checkFieldsCreateAccess(eventFieldList))) {
                throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }

        if(!GlobalUtility.getCreateEventFlag()) {
            //the setting is disable for creation of event, so return with out creating event record
            return;
        }
        for(Kinetics__Survey_Invitation__c invite: invites){
            Event event = new Event();
            event.Subject = GlobalConstants.eventSubjectMessage + stage;
            event.Description = surveyName;
            event.WhatId = invite.Id;
            if(invite.Contact__c != null) {
                event.WhoId = invite.Contact__c;
            }
            event.ActivityDate = System.today();
            event.DurationInMinutes = 30;
            event.ActivityDateTime  = System.now() + 3;
            eList.add(event); 
        }
        insert eList;
    }
    
    public static String sendSmsFromInvite(String guid, String contactId) {  
        List<Schema.DescribeFieldResult> contactFieldList = new List<Schema.DescribeFieldResult>{
            Contact.Email.getDescribe(),
            Contact.MobilePhone.getDescribe()
        };
        if(!(CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Contact) 
            && CheckUserPermission.checkFieldsCreateAccess(contactFieldList))) {
                throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }

        List<Kinetics__Survey_Invitation__c> sinvitationList = [SELECT Id, Kinetics__Kinetic_Job__r.Kinetics__SMS_Template__c,
                                                                Kinetics__Recipient_Number__c, Kinetics__Form_Renderer_Page_Base_Url__c
                                                                FROM Kinetics__Survey_Invitation__c 
                                                                WHERE Kinetics__GUID__c = :guid 
                                                                LIMIT 1];
        if(sinvitationList.isEmpty()) {
            return 'No Survey Invitation Found';
        }
        Kinetics__Survey_Invitation__c si = sinvitationList.get(0);
        String smsText = String.isNotEmpty(si.Kinetics__Kinetic_Job__r.Kinetics__SMS_Template__c)? si.Kinetics__Kinetic_Job__r.Kinetics__SMS_Template__c: SeqSenderController.getSmsTemplate();
        String pageUrl = getPageUrl(si.Kinetics__Form_Renderer_Page_Base_Url__c, guid);
        String message = generateSmsText(pageUrl, smsText);
        SmsService.sendSMSAsync(si.Kinetics__Recipient_Number__c, message);
        return pageUrl;
    }

    private static List<sObject> getRelatedParentRecordList(Kinetics__Kinetic_Link_Recipient_Configuration__mdt confObj, List<String> recordIdList) {
        String queryString = 'SELECT Id ';
        if(String.isNotBlank(confObj.Kinetics__Email_Field_API_Name__c)) {
            queryString = queryString + ', ' + confObj.Kinetics__Email_Field_API_Name__c; 
        }
        if(String.isNotBlank(confObj.Kinetics__MobilePhone_Field_API_Name__c)) {
            queryString = queryString + ', ' + confObj.Kinetics__MobilePhone_Field_API_Name__c; 
        }
        if(String.isNotBlank(confObj.Kinetics__Field_API_Name_for_Greeting__c)) {
            queryString = queryString + ', ' + confObj.Kinetics__Field_API_Name_for_Greeting__c; 
        }
        
        queryString = queryString + ' FROM ' + confObj.Kinetics__Object_Name__c + ' WHERE Id IN :recordIdList';

        List<sObject> recordList = Database.query(queryString);
        return recordList;
    }

    @AuraEnabled 
    public static String sendSms(String surveyId, String contactId) {  
        List<Schema.DescribeFieldResult> contactFieldList = new List<Schema.DescribeFieldResult>{
            Contact.Email.getDescribe(),
            Contact.MobilePhone.getDescribe()
        };
        if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Contact) 
            && CheckUserPermission.checkFieldsReadAccess(contactFieldList))) {
                throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }
      
        Id recordId = Id.valueOf(contactId);
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        Kinetics__Kinetic_Link_Recipient_Configuration__mdt confObj = getRequiredRecordForSurveyInvitaion(sObjName);

        List<sObject> recordList = getRelatedParentRecordList(confObj, new List<String> {contactId});

        if(recordList.size() == 0) {
            return 'No record Found';
        }

        Kinetics__Kinetic_Job__c job = new Kinetics__Kinetic_Job__c();
        job.Kinetics__Status__c = 'New';
        job.Kinetics__Delivery_Method__c = GlobalConstants.deliveryMethodSMS;
        job.Kinetics__SMS_Template__c = SeqSenderController.getSmsTemplate();
        job.Kinetics__Kinetic_Form__c = surveyId;
        insert job;

        Kinetics__Survey_Invitation__c invite = generateInvitation(confObj, recordList[0], surveyId, job.Id, true);
        system.debug('*****  invite=' + invite);
        String pageUrl = getPageUrl(invite.Kinetics__Form_Renderer_Page_Base_Url__c, invite.Kinetics__GUID__c);
        String message = generateSmsText(pageUrl, job.Kinetics__SMS_Template__c);
        SmsService.sendSMSAsync(String.valueOf(recordList[0].get(confObj.Kinetics__MobilePhone_Field_API_Name__c)), message);
        return pageUrl;
    }
    
    @AuraEnabled 
    public static String getSmsTemplate(){
        return GlobalUtility.getSmsTemplate();
    }

    @AuraEnabled
    public static List<Contact> getContactDetails(List<String> selectedContactIds){
        try {
            List<Schema.DescribeFieldResult> contactFieldList = new List<Schema.DescribeFieldResult>{
                Contact.Email.getDescribe(),
                Contact.MobilePhone.getDescribe(),
                Contact.AccountId.getDescribe(),
                Contact.Title.getDescribe()
            };
            if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Contact) 
                && CheckUserPermission.checkFieldsReadAccess(contactFieldList))) {
                    throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
            }
            List<Contact> contList = [SELECT Id, Name, AccountId, Account.Name, Title, Email, MobilePhone 
                                        FROM Contact 
                                        WHERE 
                                        // (Email != null OR MobilePhone != null) 
                                        //     AND 
                                        Id In :selectedContactIds];
            return contList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled 
    public static String getEmailTemplateById(String emailTemplateId){
        SeqResponse sRes = new SeqResponse();

        List<EmailTemplate> emailTemplates = [SELECT Subject, Description, HtmlValue, DeveloperName, Body 
                                        FROM EmailTemplate 
                                        WHERE Id =: emailTemplateId];
        EmailTemplate emailTemplate;
        if(!emailTemplates.isEmpty()){
            emailTemplate = new EmailTemplate();
            emailTemplate = emailTemplates.get(0);

            sRes.statusCode = '2000';
            sRes.responseMessage = 'success';
            sRes.responseDetails = emailTemplate;
        }else{
            sRes.statusCode = '2100';
            sRes.responseMessage = GlobalConstants.emailTemplateNotFoundMessage;
        }

        return JSON.serialize(sRes);
    }
    
    private static Kinetics__Survey_Invitation__c generateInvitation(Kinetics__Kinetic_Link_Recipient_Configuration__mdt confObj, sObject sObjectRecord, 
                                    String surveyId, String jobId, Boolean immediateInsert){
        List<Schema.DescribeFieldResult> surveyInvitationFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Survey_Invitation__c.Kinetics__Contact__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Form__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__GUID__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Job__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Stage__c.getDescribe()
        };
        if(!(CheckUserPermission.checkObjectCreateAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
            && CheckUserPermission.checkFieldsCreateAccess(surveyInvitationFieldList))) {
                throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }
        Kinetics__Survey_Invitation__c invite = new Kinetics__Survey_Invitation__c();
        if(String.isNotBlank(confObj.Kinetics__Relationship_Field_API_Name__c)) {
            invite.put(confObj.Kinetics__Relationship_Field_API_Name__c, String.valueOf(sObjectRecord.get('Id')));
        }
        if(String.isNotBlank(confObj.Kinetics__MobilePhone_Field_API_Name__c) 
            && sObjectRecord.get(confObj.Kinetics__MobilePhone_Field_API_Name__c) != null) {
                invite.Kinetics__Recipient_Number__c  = String.valueOf(sObjectRecord.get(confObj.Kinetics__MobilePhone_Field_API_Name__c));
        }
        if(String.isNotBlank(confObj.Kinetics__Field_API_Name_for_Greeting__c) 
            && sObjectRecord.get(confObj.Kinetics__Field_API_Name_for_Greeting__c) != null) {
                invite.Kinetics__Recipient_Name__c  = String.valueOf(sObjectRecord.get(confObj.Kinetics__Field_API_Name_for_Greeting__c));
        }
        if(String.isNotBlank(confObj.Kinetics__Email_Field_API_Name__c) 
            && sObjectRecord.get(confObj.Kinetics__Email_Field_API_Name__c) != null) {
                invite.Kinetics__Recipient_Email__c  = String.valueOf(sObjectRecord.get(confObj.Kinetics__Email_Field_API_Name__c));
        }

        invite.Kinetics__Kinetic_Form__c = surveyId;
        invite.Kinetics__GUID__c = GlobalUtility.generateGuid();
        invite.Kinetics__Form_Renderer_Page_Base_Url__c = GlobalUtility.getFormRendererPageURL(null);
        invite.Kinetics__Stage__c = GlobalConstants.sentToRecipientStage;

        if(!String.isBlank(jobId)){
            invite.Kinetics__Kinetic_Job__c = jobId;
        }else{
            invite.Kinetics__Kinetic_Job__c = 'a015g00000USks1AAD';   // park the send to a generic kenetic job
        }
        if(immediateInsert){
            insert invite;
        }
        return invite;
    }
    private static Kinetics__Kinetic_Link_Recipient_Configuration__mdt getRequiredRecordForSurveyInvitaion(String sObjName) {
        List<Kinetics__Kinetic_Link_Recipient_Configuration__mdt> confList = GlobalUtility.getRequiredRecordForSurveyInvitaion(sObjName);
        if(confList.size() > 0) {
            return confList[0];
        }
        return null;
    }

    private static String generateSmsText(String pageUrl, String seqText){
        //String seqText = SeqSenderController.getSmsTemplate();
        seqText = seqText.replace('{{pageUrl}}', pageUrl);

        return seqText;
    }

    
    public static String getPageUrl(String pageBaseURL, String surveyGUID){
        return GlobalUtility.getPageUrl(pageBaseURL, surveyGUID);
    }

    @AuraEnabled
    public static string getKineticUsageMap(){
        try {
            Map<String, Integer> kineticUsageByType = new Map<String, Integer>();
            kineticUsageByType.put('TotalAllowedSMSInvites', GlobalUtility.getAllowedSMSInvites());
            kineticUsageByType.put('NumberOfSentSMSInvite', GlobalUtility.getNumberOfSentSMSInvites());
            kineticUsageByType.put('TotalAllowedEmailInvites', GlobalUtility.getAllowedEmailInvites());
            kineticUsageByType.put('NumberOfSentEmailInvite', GlobalUtility.getNumberOfSentEmailInvite());

            return JSON.serialize(kineticUsageByType);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class SeqResponse{
        public String statusCode;
        public String responseMessage;
        Object responseDetails;
    }

    public class SendKineticSMSRequest {
        @InvocableVariable
        public String contactId;

        @InvocableVariable(required=true)
        public String guid;

    }
}