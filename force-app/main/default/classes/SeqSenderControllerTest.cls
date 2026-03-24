/**
* Author: Shankar Dupade(FieldKo)
* Updated : 11th Aug 2021
* Purpose: Test Class for SeqSenderController
*/
@isTest
public with sharing class SeqSenderControllerTest {
    @TestSetup
    static void createData() {
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        List<Contact> conList = TestDataFactory.createContact(accList);
        List<Kinetics__Kinetic_Question__c> qestList = TestDataFactory.createQuestion();
        List<Kinetics__Kinetic_Form__c> kfList = TestDataFactory.createKineticForm();
        List<Kinetics__Kinetic_Form_Question__c> kfqList = TestDataFactory.createKineticFormQuestion(qestList, kfList);

        List<Kinetics__Kinetic_Job__c> kjList = TestDataFactory.createKineticJob(kfList);
        List<Kinetics__Survey_Invitation__c> siList = TestDataFactory.createSurveyInvitation(conList, kjList);
        List<Kinetics__Kinetic_Form_Answer__c> ansList = TestDataFactory.createAnswers(siList, kfqList, qestList);
    }

    @isTest
    static void test_sendLinksSMS() {
        SeqSenderController.SendKineticSMSRequest smssendObj = new SeqSenderController.SendKineticSMSRequest();
        SeqSenderController sobj = new SeqSenderController();
        List<Contact> conList = [select ID from contact];
        List<Kinetics__Survey_Invitation__c> siList = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c];
        smssendObj.contactId = conList[0].Id;
        smssendObj.guid = siList[0].Kinetics__GUID__c;

        Test.startTest();
            System.assertNotEquals(smssendObj, null);
            SeqSenderController.sendLinksSMS(new List<SeqSenderController.SendKineticSMSRequest> {smssendObj});
        Test.stopTest();
    }

    @isTest
    static void test_createJob_SMS() {
        List<Contact> conList = [select Id from Contact];
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];

        List<String> contIdList = new List<String>{conList[0].Id};

        Test.startTest();
            String responseString = SeqSenderController.createJob(formList[0].Id, contIdList, GlobalConstants.channelSMS, null, 'Hello Test sms',false,0, 0, 0, null);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2000'));
        Test.stopTest();
    }

    @isTest
    static void test_createJob_getSmsTemplate() {
        List<Contact> conList = [select Id from Contact];
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];

        List<String> contIdList = new List<String>{conList[0].Id};

        Test.startTest();
            String responseString = SeqSenderController.createJob(formList[0].Id, contIdList, GlobalConstants.channelSMS, null, SeqSenderController.getSmsTemplate(),false,0, 0, 0, null);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2000'));
        Test.stopTest();
    }

    @isTest
    static void test_getContactDetails() {
        List<Contact> conList = [select Id from Contact];
        List<String> contIdList = new List<String>{conList[0].Id};

        Test.startTest();
            List<Contact> contactList = SeqSenderController.getContactDetails(contIdList);
            System.assertEquals(contactList.size(), contIdList.size());
        Test.stopTest();
    }

    @isTest
    static void test_getEmailTemplateById_notPresent() {
        Test.startTest();
            String responseString = SeqSenderController.getEmailTemplateById(null);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2100'));
        Test.stopTest();
    }

    @isTest
    static void test_sendSms() {
        List<Contact> conList = [select Id from Contact];
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];

        List<String> contIdList = new List<String>{conList[0].Id};

        Test.startTest();
            String responseString = SeqSenderController.sendSms(formList[0].Id, contIdList[0]);
            System.assertNotEquals(responseString, null);
        Test.stopTest();
    }
    @isTest
    static void test_getKineticUsageMap(){
        Test.startTest();
            String kineticUsageMapString = SeqSenderController.getKineticUsageMap();
            System.assertNotEquals(kineticUsageMapString, null);
        Test.stopTest();
    }

    @isTest
    static void test_createJob_Email() {
        List<Contact> conList = [select Id from Contact];
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];

        List<String> contIdList = new List<String>{conList[0].Id};

        Test.startTest();
            List<EmailTemplate> emailTemplateList = [select Id from EmailTemplate limit 1];
            String responseString = SeqSenderController.createJob(formList[0].Id, contIdList, GlobalConstants.channelEMAIL, emailTemplateList[0].Id, 'Hello Test email',false,0, 0, 0, null);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2000'));
        Test.stopTest();
    }

    @isTest
    static void test_getEmailTemplateById_Present() {
        Test.startTest();
            List<EmailTemplate> emailTemplateList = [select Id from EmailTemplate limit 1];
            String responseString = SeqSenderController.getEmailTemplateById(emailTemplateList[0].Id);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2000'));
        Test.stopTest();
    }
    @isTest
    static void test_createJob_SMS_withEventCreate() {
        List<Contact> conList = [select Id from Contact];
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];

        List<String> contIdList = new List<String>{conList[0].Id};

        Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
        setting.Kinetics__Create_Event__c = true;
        update setting;
        Test.startTest();
            String responseString = SeqSenderController.createJob(formList[0].Id, contIdList, GlobalConstants.channelSMS, null, 'Hello Test sms',false,0, 0, 0, null);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2000'));
        Test.stopTest();
    }
}