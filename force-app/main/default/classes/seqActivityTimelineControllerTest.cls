/**
 * Author: Shankar Dupade (FieldKo)
 * Purpose: Test class for controller class which is used for showing activity timeline for Survey invitations
 * Date: 10 Auth 2021
 */
@isTest
public with sharing class seqActivityTimelineControllerTest {
    
    @TestSetup
    static void setupData(){
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        Account acc1 = accList[0];

        Contact c = new Contact();
        c.FirstName = 'test firstName';
        c.LastName = 'test lastName';
        c.Email = 'abs@fieldko.com';
        c.MobilePhone = '999999999';
        insert c;

        Kinetics__Kinetic_Form__c kf = new Kinetics__Kinetic_Form__c();
        kf.Name = 'Test Kinetic form';
        kf.Kinetics__Status__c = 'Active';
        insert kf;

        Kinetics__Kinetic_Job__c kj = new Kinetics__Kinetic_Job__c();
        kj.Kinetics__Delivery_Method__c = GlobalConstants.deliveryMethodSMS;
        kj.Kinetics__Kinetic_Form__c = kf.Id;
        kj.Kinetics__SMS_Template__c = GlobalUtility.getSmsTemplate();
        kj.Kinetics__Status__c = 'New';
        insert kj;

        Kinetics__Survey_Invitation__c si = new Kinetics__Survey_Invitation__c();
        si.Kinetics__Channel__c = GlobalConstants.channelSMS;
        si.Kinetics__Contact__c = c.Id;
        si.Kinetics__Stage__c = GlobalConstants.sentToRecipientStage;
        si.Kinetics__Kinetic_Form__c = kf.Id;
        si.Kinetics__Kinetic_Job__c = kj.Id;
        si.Kinetics__Send_Auto_Reminders__c = false;
        si.Kinetics__TTL_Day__c = 7;
        si.Kinetics__GUID__c = GlobalUtility.generateGuid();

        insert si;
        Kinetics__Survey_Invitation__c si1 = new Kinetics__Survey_Invitation__c();
        si1.Kinetics__Channel__c = GlobalConstants.channelEMAIL;
        si1.Kinetics__Contact__c = c.Id;
        si1.Kinetics__Stage__c = GlobalConstants.sentToRecipientStage;
        si1.Kinetics__Kinetic_Form__c = kf.Id;
        si1.Kinetics__Kinetic_Job__c = kj.Id;
        si1.Kinetics__Send_Auto_Reminders__c = false;
        si1.Kinetics__TTL_Day__c = 17;
        si1.Kinetics__GUID__c = GlobalUtility.generateGuid();

        insert si1;
    }

    @IsTest
    static void test_getSurveyInvitationsForContact(){
        
        List<Contact> cList = [select Id from Contact where MobilePhone != null];
        System.assert(cList.size() > 0);
        Test.startTest();
            String surveyInvitationListString = seqActivityTimelineController.getSurveyInvitationsForContact(cList[0].Id);
            List<Kinetics__Survey_Invitation__c> siList = (List<Kinetics__Survey_Invitation__c>)JSON.deserialize(surveyInvitationListString, List<Kinetics__Survey_Invitation__c>.class);
            system.assert(siList.size() > 0);
        Test.stopTest();
    }

    @IsTest
    static void test_updateSurveyInvitation(){
        
        List<Contact> cList = [select Id from Contact where MobilePhone != null];
        System.assert(cList.size() > 0);
        Test.startTest();
            String surveyInvitationListString = seqActivityTimelineController.getSurveyInvitationsForContact(cList[0].Id);
            List<Kinetics__Survey_Invitation__c> siList = (List<Kinetics__Survey_Invitation__c>)JSON.deserialize(surveyInvitationListString, List<Kinetics__Survey_Invitation__c>.class);
            seqActivityTimelineController.updateSurveyInvitation(siList[0].Id,  GlobalConstants.inProgressStage);
            siList = [select Id, Kinetics__Stage__c from Kinetics__Survey_Invitation__c where ID = :siList[0].Id];
            system.assert(siList.size() > 0);
            system.assert(siList[0].Kinetics__Stage__c ==  GlobalConstants.inProgressStage);
        Test.stopTest();
    }
}