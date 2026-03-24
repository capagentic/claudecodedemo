/**
* Author: Shankar Dupade(FieldKo)
* Updated : 31st Aug 2021
* Purpose: Test Class for KineticJobInviteTrigger
*/
@isTest
public with sharing class KineticJobInviteTriggerTest {
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
    static void test_afterinsert(){
        
        Kinetics__Kinetic_Form__c kf = [SELECT ID from Kinetics__Kinetic_Form__c limit 1];
        System.assertNotEquals(null, kf);
        List<String> conIdList = new List<String>();
        for(Contact con: [SELECT ID from Contact ]) {
            conIdList.add(con.Id);
        }
        System.assertNotEquals(0, conIdList.size());
        Kinetics_Jobs_Invites__e kji = new Kinetics_Jobs_Invites__e();
        kji.Kinetics__Kinetic_Form_Id__c = kf.Id;
        kji.Kinetics__Contact_Ids__c = JSON.serialize(conIdList);
        kji.Kinetics__Delivery_Method__c = 'SMS';
        kji.Kinetics__Email_Template_Id__c = null;
        kji.Kinetics__Do_Send_Auto_Reminders__c = false;
        kji.Kinetics__Days_For_First_Reminder__c = 0;
        kji.Kinetics__Days_Between_Reminder__c = 0;
        kji.Kinetics__Days_Before_Request_Expires__c = 0;
       
        Test.startTest();
            EventBus.publish(kji);
        Test.stopTest();
        
    }
}