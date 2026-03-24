/**
* Author: Shankar Dupade(FieldKo)
* Updated : 09th Sept 2021
* Purpose: Test Class for SeqReminderSenderBatchScheduler
*/
@isTest
public with sharing class SeqReminderSenderBatchSchedulerTest {
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
    static void test_setBatchSize() {
        Test.StartTest();
            SeqReminderSenderBatchScheduler ssbs = new SeqReminderSenderBatchScheduler();
            ssbs.setBatchSize(10);
            String sch = '0 0 23 * * ?'; 
            System.assertNotEquals(null, ssbs);
            System.schedule('Test Batch Schedule', sch, ssbs); 
        Test.stopTest(); 
    }
}