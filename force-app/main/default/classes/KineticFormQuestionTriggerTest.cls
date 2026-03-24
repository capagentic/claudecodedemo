/**
* Author: Shankar Dupade(FieldKo)
* Updated : 9th Sept 2021
* Purpose: Test Class for KineticFormQuestionTrigger
*/
@isTest
public with sharing class KineticFormQuestionTriggerTest {
    @TestSetup
    static void createData(){
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        List<Contact> conList = TestDataFactory.createContact(accList);
        List<Kinetics__Kinetic_Question__c> qestList = TestDataFactory.createQuestion();
        List<Kinetics__Kinetic_Form__c> kfList = TestDataFactory.createKineticForm();
        List<Kinetics__Kinetic_Form_Question__c> kfqList = TestDataFactory.createKineticFormQuestion(qestList, kfList);

    }
    @IsTest
    static void test_beforeInsert(){
        Test.startTest();
            Kinetics__Kinetic_Form__c kf = [SELECT Id FROM Kinetics__Kinetic_Form__c LIMIT 1];
            Kinetics__Kinetic_Question__c kq = [SELECT Id FROM Kinetics__Kinetic_Question__c LIMIT 1];
            
            Kinetics__Kinetic_Form_Question__c kfq = new Kinetics__Kinetic_Form_Question__c();
            kfq.Kinetics__Kinetic_Question__c = kq.Id;
            kfq.Kinetics__Kinetic_Form__c = kf.Id;
            kfq.Kinetics__Index__c = 1;
            insert kfq;
            System.assertNotEquals(null, kfq);
        Test.stopTest();
    }
}