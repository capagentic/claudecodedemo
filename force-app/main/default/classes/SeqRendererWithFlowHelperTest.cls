/**
* Author: Shankar Dupade(FieldKo)
* Updated : 11th Aug 2021
* Purpose: Test Class for SeqSenderController
*/
@isTest
public with sharing class SeqRendererWithFlowHelperTest {
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
    static void test_getRelatedParentRecordIdBySurveyGuid() {
        List<Kinetics__Survey_Invitation__c> siList = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c];
        String guid = siList[0].Kinetics__GUID__c;

        Test.startTest();
            System.assertNotEquals(siList, null);
            SeqRendererWithFlowHelper.getRelatedParentRecordIdBySurveyGuid(guid, 'Contact');
        Test.stopTest();
    }
    @isTest
    static void test_Fail_getRelatedParentRecordIdBySurveyGuid() {
        List<Kinetics__Survey_Invitation__c> siList = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c];
        String guid = 'fake id';

        Test.startTest();
            System.assertNotEquals(siList, null);
            SeqRendererWithFlowHelper.getRelatedParentRecordIdBySurveyGuid(guid, 'Contact');
        Test.stopTest();
    }
    @isTest
    static void test_Fail2_getRelatedParentRecordIdBySurveyGuid() {
        List<Kinetics__Survey_Invitation__c> siList = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c];
        String guid = siList[0].Kinetics__GUID__c;

        Test.startTest();
            System.assertNotEquals(siList, null);
            SeqRendererWithFlowHelper.getRelatedParentRecordIdBySurveyGuid(guid, 'Contact_fake');
        Test.stopTest();
    }
}