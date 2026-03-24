public with sharing class GlobalUtility {
    public static String generateGuid() {
        Blob cryptoKey = Crypto.GenerateAESKey(128);
        String encodedHex = EncodingUtil.ConvertTohex(cryptoKey);
        String guid = encodedHex.SubString(0,8)+ '-' + encodedHex.SubString(8,12) + '-' + encodedHex.SubString(12,16) + '-' + encodedHex.SubString(16,20) + '-' + encodedHex.substring(20);
        return guid;
    }

    public static String getGoogleAPIKey () {
        Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
        return setting.Kinetics__Google_API_Key__c;
    }
    public static String getLogoDocumentId () {
        Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
        return setting.Kinetics__Logo_Document_API_Name__c;
    }

    public static String getSmsTemplate() {
        Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
        return setting.Kinetics__SMS_Template__c;
    }
    public static Boolean getCreateEventFlag() {
        Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
        return setting.Kinetics__Create_Event__c;
    }
    
    public static String getFormRendererPageURL(String pageBaseURL) {
        String url = pageBaseURL;
        if(String.isBlank(url) || String.isEmpty(url)){
            Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
            url = setting.Kinetics__Form_Renderer_Page_URL__c;
        }
        while(String.isNotEmpty(url) && url.endsWith('/')){
            url = url.removeEnd('/');    
        }
        return url;
    }

    public static String getParentRelatedFieldName() {
        Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
        return setting.Kinetics__Field_Name_for_Lookup__c;
    }

    public static String getPageUrl(String pageBaseURL, String surveyGUID){
        return GlobalUtility.getFormRendererPageURL(pageBaseURL) + '?seqnum=' + surveyGUID;
    }
    
    public static void informISVAboutSMSUsageLimit() {
        List<String> sendTo = new List<String>();
        //send email to team at Fieldko to inform them about the exceeded usage 
        sendTo.add('team@fieldko.com');

        String body = 'Dear team, ';
        body += '<br/>Kinetic SMS invitation Usage has exceeded the allowed limit for : ORG Name: ' + UserInfo.getOrganizationName() + ', ORG ID: ' + UserInfo.getOrganizationId();
        body += '<br/>Please take appropriate action.';
        body += '<br/>Thank you';
        String subject = 'URGENT: Kinetic SMS invitation has exceeded the allowed limit';

        sendEmail(sendTo,subject, body);
    }

    public static void sendEmail(List<String> sendTo, String subject, String body) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(sendTo);
        mail.setReplyTo(UserInfo.getUserEmail());
        mail.setSenderDisplayName(UserInfo.getName());
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mails.add(mail);
        Messaging.sendEmail(mails);
    }

    public static Integer getAllowedSMSInvites() {
        return System.FeatureManagement.checkPackageIntegerValue('TotalAllowedSMSInvites');
    }

    public static Integer getNumberOfSentSMSInvites() {
        return System.FeatureManagement.checkPackageIntegerValue('NumberOfSentSMSInvite');
    }
    
    public static Boolean isWithinSMSAllowedLimit() {
        Integer TotalAllowedSMSInvites = getAllowedSMSInvites();
        Integer totalNumberOfSentSMSInvites = getNumberOfSentSMSInvites();
        
        return (totalNumberOfSentSMSInvites < TotalAllowedSMSInvites);
    }

    public static void increaseSMSInvitationCountByOne() {
        Integer totalNumberOfSentSMSInvites = System.FeatureManagement.checkPackageIntegerValue('NumberOfSentSMSInvite');
        if(!Test.isRunningTest()) {
            System.FeatureManagement.setPackageIntegerValue('NumberOfSentSMSInvite', (totalNumberOfSentSMSInvites + 1));
        }
    }

    public static void informISVAboutEMAILUsageLimit() {
        
        List<String> sendTo = new List<String>();
        //send email to team at Fieldko to inform them about the exceeded usage 
        sendTo.add('team@fieldko.com');
        String subject = 'URGENT: Kinetic EMAIL invitation has exceeded the allowed limit';
        String body = 'Dear team, ';
        body += '<br/>Kinetic EMAIL invitation Usage has exceeded the allowed limit for : ORG Name: ' + UserInfo.getOrganizationName() + ', ORG ID: ' + UserInfo.getOrganizationId();
        body += '<br/>Please take appropriate action.';
        body += '<br/>Thank you';
        sendEmail(sendTo,subject, body);
    }
    
    public static Integer getAllowedEmailInvites() {
        return System.FeatureManagement.checkPackageIntegerValue('TotalAllowedEmailInvites');
    }

    public static Integer getNumberOfSentEmailInvite() {
        return System.FeatureManagement.checkPackageIntegerValue('NumberOfSentEmailInvite');
    }

    public static Boolean isWithinEMAILAllowedLimit() {
        Integer TotalAllowedEmailInvites = getAllowedEmailInvites();
        Integer totalNumberOfSentEmailInvite = getNumberOfSentEmailInvite();
        
        return (totalNumberOfSentEmailInvite < TotalAllowedEmailInvites);
    }

    public static void increaseEMAILInvitationCountByOne() {
        Integer totalNumberOfSentEmailInvite = System.FeatureManagement.checkPackageIntegerValue('NumberOfSentEmailInvite');
        if(!Test.isRunningTest()) {
            System.FeatureManagement.setPackageIntegerValue('NumberOfSentEmailInvite', (totalNumberOfSentEmailInvite + 1));
        }
    }
    public static void increaseEMAILInvitationCountByCount(Integer countToIncrease) {
        Integer totalNumberOfSentEmailInvite = System.FeatureManagement.checkPackageIntegerValue('NumberOfSentEmailInvite');
        if(!Test.isRunningTest()) {
            System.FeatureManagement.setPackageIntegerValue('NumberOfSentEmailInvite', (totalNumberOfSentEmailInvite + countToIncrease));
        }
    }

    public static Integer getNumberOfAllowedQuestionsPerForm() {
        return System.FeatureManagement.checkPackageIntegerValue('NumberOfQuestionsPerForm');
    }

    public static List<Kinetics__AWS_Config__mdt> getAWSConfigList () {
        List<Kinetics__AWS_Config__mdt> awsConfigList = new List<Kinetics__AWS_Config__mdt>();
        if(!Test.isRunningTest()) {
             awsConfigList = [SELECT Kinetics__Access_Key__c, Kinetics__Access_Secret__c, Kinetics__AWS_Host__c,
                                Kinetics__AWS_Region__c, Kinetics__AWS_Service_Name__c, Kinetics__Lambda_Function_Name__c,
                                Kinetics__Method__c, Kinetics__Stage_Name__c 
                                FROM Kinetics__AWS_Config__mdt];
        } else {
            awsConfigList.add(
                GlobalUtilityTest.getAWSConfigTestRec()
            );
        }
        return awsConfigList;
    }
    public static String getGPTAPIKey () {
        Kinetics__GPT_Configurations__c setting = Kinetics__GPT_Configurations__c.getInstance();
        return setting.Kinetics__GPT_API_Key__c;
    }
    public static String getGPTEndPoint () {
        Kinetics__GPT_Configurations__c setting = Kinetics__GPT_Configurations__c.getInstance();
        return setting.Kinetics__Chat_Completions_End_Point__c;
    }
    public static String getGPTModel () {
        Kinetics__GPT_Configurations__c setting = Kinetics__GPT_Configurations__c.getInstance();
        return setting.Kinetics__GPT_Model__c;
    }
    public static String getOpenAI_Organization () {
        Kinetics__GPT_Configurations__c setting = Kinetics__GPT_Configurations__c.getInstance();
        return setting.Kinetics__OpenAI_Organization__c;
    }
    public static Decimal getTemperature () {
        Kinetics__GPT_Configurations__c setting = Kinetics__GPT_Configurations__c.getInstance();
        return Decimal.valueOf(setting.Kinetics__Temperature__c);
    }
    public static List<Kinetics__Kinetic_Link_Recipient_Configuration__mdt> getRequiredRecordForSurveyInvitaion(String sObjName) {
        List<Kinetics__Kinetic_Link_Recipient_Configuration__mdt> confList = [SELECT Id, Kinetics__Email_Field_API_Name__c, Kinetics__MobilePhone_Field_API_Name__c,
                                                                                Kinetics__Object_Name__c, Kinetics__Relationship_Field_API_Name__c,
                                                                                Kinetics__Field_API_Name_for_Greeting__c 
                                                                            FROM Kinetics__Kinetic_Link_Recipient_Configuration__mdt
                                                                            WHERE Kinetics__Is_Active__c = true 
                                                                            AND Kinetics__Object_Name__c = :sObjName 
                                                                            LIMIT 1];
        return confList;
    }
    public static KineticCustomException auraHandledMessageException(String message) {
        KineticCustomException e = new KineticCustomException(message);
        e.setMessage(message);
        return e;
    }
    public static String getGPTAssistantAPIBaseEndPoint () {
        Kinetics__GPT_Configurations__c setting = Kinetics__GPT_Configurations__c.getInstance();
        return setting.Kinetics__Assistant_AI_Base_End_Point__c;
    }

    public class KineticCustomException extends Exception {

    }
}