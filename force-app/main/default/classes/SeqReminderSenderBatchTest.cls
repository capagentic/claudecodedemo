/**
* Author: Shankar Dupade(FieldKo)
* Updated : 09th Sept 2021
* Purpose: Test Class for SeqReminderSenderBatch
*/
@isTest
public with sharing class SeqReminderSenderBatchTest {
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
    static void SeqReminderSenderBatch_test(){
        
        Kinetics__Survey_Invitation__c si = [SELECT Id,Kinetics__Send_Auto_Reminders__c, Kinetics__Days_between_two_reminders__c, 
        Kinetics__Days_before_First_Reminder__c FROM Kinetics__Survey_Invitation__c LIMIT 1];

        System.assertNotEquals(null, si);
        si.Kinetics__Send_Auto_Reminders__c = true;
        si.Kinetics__Days_between_two_reminders__c = 1;
        si.Kinetics__Days_before_First_Reminder__c = 1;
        update si;

       Test.startTest();
            SeqReminderSenderBatch obj = new SeqReminderSenderBatch();
            DataBase.executeBatch(obj); 
        Test.stopTest();
        
    }
}