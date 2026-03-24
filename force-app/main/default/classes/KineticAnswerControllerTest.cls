/**
* Author: Shankar Dupade(FieldKo)
* Updated : 11th Aug 2021
* Purpose: Test Class for KineticAnswerController
*/
@isTest
public with sharing class KineticAnswerControllerTest {
    
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
    static void test_getAnswers() {
        Test.startTest();
            KineticAnswerController kac = new KineticAnswerController();
            List<Kinetics__Survey_Invitation__c> siList = [select Id from Kinetics__Survey_Invitation__c];
            String responseString = KineticAnswerController.getAnswers(siList[0].Id);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2000'));
        Test.stopTest();
    }
}