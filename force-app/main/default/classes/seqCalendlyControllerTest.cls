/**
* Author: Shankar Dupade(FieldKo)
* Updated : 7th Feb 2021
* Purpose: Test Class for seqCalendlyController
*/
@isTest
public with sharing class seqCalendlyControllerTest {
    
    @TestSetup
    static void createData(){
        TestDataFactory.configureKineticSetting();
        TestDataFactory.configureCalendlySettings();
        List<Account> accList = TestDataFactory.createAccount();

        List<Contact> conList = TestDataFactory.createContact(accList);
        List<Kinetics__Kinetic_Question__c> qestList = TestDataFactory.createQuestion();
        qestList.addAll(TestDataFactory.createQuestion());
        List<Kinetics__Kinetic_Form__c> kfList = TestDataFactory.createKineticForm();
        List<Kinetics__Kinetic_Form_Question__c> kfqList = TestDataFactory.createKineticFormQuestion(qestList, kfList);

        List<Kinetics__Kinetic_Job__c> kjList = TestDataFactory.createKineticJob(kfList);
        List<Kinetics__Survey_Invitation__c> siList = TestDataFactory.createSurveyInvitation(conList, kjList);
    }

    @isTest
    static void test_getDetailsForCalendly() {
        Test.startTest();
        Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
        String responseString = seqCalendlyController.getDetailsForCalendly(siObj.Kinetics__GUID__c);
        System.assertNotEquals(responseString, null);
        Test.stopTest();
    }
}