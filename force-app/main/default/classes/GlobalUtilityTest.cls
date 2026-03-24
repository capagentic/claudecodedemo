/**
 * Author: Shankar Dupade (FieldKo)
 * Purpose: Test class for controller class which is used for GlobalUtility
 * Date: 10 Auth 2021
 */
@isTest
public with sharing class GlobalUtilityTest {
    
    @IsTest
    static void test_generateGuid(){
        TestDataFactory.configureKineticSetting();
        TestDataFactory.configureGPTSetting();
        Test.startTest();
            String guid = GlobalUtility.generateGuid();
            System.assert(guid.length() > 8);

            String googleMapAPIKey = GlobalUtility.getGoogleAPIKey();
            System.assert(googleMapAPIKey.length() > 0);

            String smsTemplate = GlobalUtility.getSmsTemplate();
            System.assert(smsTemplate.length() > 0);
            
            String formRendererPageURL = GlobalUtility.getFormRendererPageURL(null);
            System.assert(formRendererPageURL.length() > 0);

            GlobalUtility.getPageUrl(null, 'ABCDEFGHIJ');
            
            GlobalUtility.getCreateEventFlag();
            
            GlobalUtility.informISVAboutSMSUsageLimit();
            GlobalUtility.getAllowedSMSInvites();
            GlobalUtility.getNumberOfSentSMSInvites();
            GlobalUtility.isWithinSMSAllowedLimit();
            GlobalUtility.increaseSMSInvitationCountByOne();
            GlobalUtility.informISVAboutEMAILUsageLimit();
            GlobalUtility.getAllowedEmailInvites();
            GlobalUtility.getNumberOfSentEmailInvite();
            GlobalUtility.isWithinEMAILAllowedLimit();
            GlobalUtility.increaseEMAILInvitationCountByOne();
            GlobalUtility.getNumberOfAllowedQuestionsPerForm();
            GlobalUtility.increaseEMAILInvitationCountByCount(10);
            GlobalUtility.getGPTAPIKey();
            GlobalUtility.getGPTEndPoint();
            GlobalUtility.getGPTModel();
            GlobalUtility.getOpenAI_Organization();
            GlobalUtility.getTemperature();
            GlobalUtility.getGPTAssistantAPIBaseEndPoint();
            GlobalUtility.getLogoDocumentId();
            GlobalUtility.auraHandledMessageException('test error message');
        Test.stopTest();
    }
    @IsTest
    static void test_getAWSConfigList(){
        TestDataFactory.configureKineticSetting();
        Test.startTest();
            List<Kinetics__AWS_Config__mdt> awsconfigList = GlobalUtility.getAWSConfigList();
            System.assert(awsconfigList.size() != 0);
        Test.stopTest();
    }

    @isTest
    static void test_getParentRelatedFieldName() {
        TestDataFactory.configureKineticSetting();
        Test.startTest();
            GlobalUtility.getParentRelatedFieldName();
        Test.stopTest();
    }

    @isTest
    static void test_getRequiredRecordForSurveyInvitaion() {
        TestDataFactory.configureKineticSetting();
        Test.startTest();
            GlobalUtility.getRequiredRecordForSurveyInvitaion('Account');
        Test.stopTest();
    }

    public static Kinetics__AWS_Config__mdt getAWSConfigTestRec() {
        Kinetics__AWS_Config__mdt awsconfig =  new Kinetics__AWS_Config__mdt(
                Kinetics__Access_Key__c = 'testkey', 
                Kinetics__Access_Secret__c = 'test_access_secret',
                Kinetics__AWS_Host__c = 'test_aws_host',
                Kinetics__AWS_Region__c = 'test_aws_region',
                Kinetics__AWS_Service_Name__c = 'test_aws_service_Name',
                Kinetics__Lambda_Function_Name__c = 'sendSms',
                Kinetics__Method__c = 'POST', 
                Kinetics__Stage_Name__c = 'default'
            );
        System.assert(awsconfig != null);
        return awsconfig;
    }
}