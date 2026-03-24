/**
* Author: Shankar Dupade(FieldKo)
* Updated : 31st Aug 2021
* Purpose: Test Class for KineticInviteReminderTrigger
*/
@isTest
public with sharing class KineticInviteReminderTriggerTest {
    
    @TestSetup
    static void createData(){
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        List<Contact> conList = TestDataFactory.createContact(accList);
        List<Kinetics__Kinetic_Question__c> qestList = TestDataFactory.createQuestion();
        List<Kinetics__Kinetic_Form__c> kfList = TestDataFactory.createKineticForm();
        List<Kinetics__Kinetic_Form_Question__c> kfqList = TestDataFactory.createKineticFormQuestion(qestList, kfList);

        List<Kinetics__Kinetic_Job__c> kjList = TestDataFactory.createKineticJob(kfList);
        List<Kinetics__Survey_Invitation__c> siList = TestDataFactory.createSurveyInvitation(conList, kjList);

        Kinetics__Survey_Invitation__c invite = [SELECT Id,  Kinetics__Days_before_First_Reminder__c, Kinetics__Days_between_two_reminders__c, Kinetics__Send_Auto_Reminders__c, Kinetics__Stage__c, Kinetics__TTL_Day__c, Kinetics__Last_Reminder_Sent_Date__c,
                                                                Kinetics__Reminder_Sent_count__c
                                                            FROM Kinetics__Survey_Invitation__c 
                                                            WHERE Kinetics__GUID__c != null AND Kinetics__Contact__c != null AND Kinetics__Kinetic_Form__c != null AND Kinetics__Kinetic_Job__c != null 
                                                         ];
        invite.Kinetics__Send_Auto_Reminders__c = true;
        invite.Kinetics__Stage__c = GlobalConstants.inProgressStage;
        update invite;
    }

    @IsTest
    static void test_afterinsert(){
        
        Kinetics__Kinetic_Invite_Reminder__e kir = new Kinetics__Kinetic_Invite_Reminder__e();
        List<String> invitationIdList = new List<String>();
        List<Kinetics__Survey_Invitation__c> inviteList = new List<Kinetics__Survey_Invitation__c>();
        for(Kinetics__Survey_Invitation__c invite : [SELECT Id, Name, Kinetics__Days_before_First_Reminder__c, Kinetics__Days_between_two_reminders__c, Kinetics__GUID__c, Kinetics__Contact__c, 
                                                                Kinetics__Kinetic_Job__c, Kinetics__Send_Auto_Reminders__c, Kinetics__Stage__c, Kinetics__Kinetic_Form__c, Kinetics__TTL_Day__c, Kinetics__Last_Reminder_Sent_Date__c,
                                                                Kinetics__Reminder_Sent_count__c, Kinetics__Channel__c, CreatedDate 
                                                            FROM Kinetics__Survey_Invitation__c 
                                                            WHERE Kinetics__GUID__c != null AND Kinetics__Contact__c != null AND Kinetics__Kinetic_Form__c != null AND Kinetics__Kinetic_Job__c != null 
                                                         ]) {
            invitationIdList.add(invite.Id); 
        }

        kir.Kinetics__Kinetic_Invitation_Ids__c = JSON.serialize(invitationIdList);

        Test.startTest();
            System.assertNotEquals(null, kir);    
            EventBus.publish(kir);
        Test.stopTest();
        
    }
}