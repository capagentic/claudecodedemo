/**
* Author: Shankar Dupade(FieldKo)
* Updated : 09th Sept 2021
* Purpose: Test Class for SeqReminderSenderBatchHelper
*/
@isTest
public with sharing class SeqReminderSenderBatchHelperTest {
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
    static void SeqReminderSenderBatchHelper_Test(){

        Kinetics__Survey_Invitation__c si = [SELECT Id,Kinetics__Send_Auto_Reminders__c, Kinetics__Days_between_two_reminders__c, 
        Kinetics__Days_before_First_Reminder__c,Kinetics__GUID__c,Kinetics__Contact__c,Kinetics__Kinetic_Form__c, Kinetics__Kinetic_Job__c,
        CreatedDate,Kinetics__Last_Reminder_Sent_Date__c,Kinetics__Reminder_Sent_count__c,Kinetics__TTL_Day__c
         FROM Kinetics__Survey_Invitation__c LIMIT 1];
        si.Kinetics__Send_Auto_Reminders__c = true;
        si.Kinetics__Days_between_two_reminders__c = 1;
        si.Kinetics__Days_before_First_Reminder__c = 1;
        update si;

       Test.startTest();
            List<String> stageToSkip = SeqReminderSenderBatchHelper.getStagesToSkip();
            System.assertNotEquals(stageToSkip.size(), 0);
            SeqReminderSenderBatchHelper.isValidForInvitation(si);
            SeqReminderSenderBatchHelper.doSendReminder(si);
        Test.stopTest();
        
    }
}