/**
* Author: Shankar Dupade(FieldKo)
* Updated : 9th Sept 2021
* Purpose: Test Class for SeqEmailSenderController
*/
@isTest
public with sharing class SeqEmailSenderControllerTest {
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
    static void test_sendLinksEMAIL() {
        List<Kinetics__Kinetic_Job__c> kjList  = [SELECT Id, Kinetics__Delivery_Method__c FROM Kinetics__Kinetic_Job__c];
        List<EmailTemplate> emailtemplateList = [SELECT Id,Body FROM EmailTemplate  limit 1];
        kjList[0].Kinetics__Delivery_Method__c = GlobalConstants.deliveryMethodEMAIL;
        kjList[0].Kinetics__Email_Template__c = emailtemplateList[0].Body;
        kjList[0].Kinetics__Email_Template_Id__c = emailtemplateList[0].Id;
        update kjList;

        List<Kinetics__Survey_Invitation__c> siList = [SELECT Id from Kinetics__Survey_Invitation__c  WHERE  Kinetics__Kinetic_Job__c = :kjList[0].Id LIMIT 1];
        Test.startTest();
            SeqEmailSenderController.SendKineticEMAILRequest skr = new SeqEmailSenderController.SendKineticEMAILRequest();
            System.assertNotEquals(siList.size(), 0);
            skr.inviteId = siList[0].Id;
            SeqEmailSenderController.sendLinksEMAIL(new List<SeqEmailSenderController.SendKineticEMAILRequest>{skr});
        Test.stopTest();
    }
}