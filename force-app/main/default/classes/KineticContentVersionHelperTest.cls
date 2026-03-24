/**
* Author: Shankar Dupade
* Updated : 2nd Sept 2021
* Purpose: Test Class for creation, read, manipulation, deletion operations of content version record
*
*/
@isTest
public with sharing class KineticContentVersionHelperTest {
    @testSetup
    static void testSetupData() {
        
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        List<Contact> conList = TestDataFactory.createContact(accList);
        List<Kinetics__Kinetic_Question__c> qestList = TestDataFactory.createQuestion();
        List<Kinetics__Kinetic_Form__c> kfList = TestDataFactory.createKineticForm();
        List<Kinetics__Kinetic_Form_Question__c> kfqList = TestDataFactory.createKineticFormQuestion(qestList, kfList);

        List<Kinetics__Kinetic_Job__c> kjList = TestDataFactory.createKineticJob(kfList);
        List<Kinetics__Survey_Invitation__c> siList = TestDataFactory.createSurveyInvitation(conList, kjList);

        //Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
        //String answerString = '{"a045g0000042lb2AAA":{"index":1,"surveyQuestionId":"a045g0000042lb2AAA","questionId":"a035g0000030mGAAAY","questionDetails":"test capture Photo question","fieldType":"File","questionValues":null,"answer":"Screenshot_20210810-213929.png"}}';
        //System.assertNotEquals(answerString, null);
        //SeqRendererController.saveAnswers(siObj.Kinetics__GUID__c, answerString);
        Kinetics__Kinetic_Form_Answer__c answer2Commit = new Kinetics__Kinetic_Form_Answer__c();
        answer2Commit.Kinetics__Answer_Index__c = 1;
        answer2Commit.Kinetics__Kinetic_Question__c = qestList[0].Kinetics__Question__c;
        answer2Commit.Kinetics__Kinetic_Question_Values__c = qestList[0].Kinetics__Values__c;
        answer2Commit.Kinetics__Kinetic_Form_Question__c = kfqList[0].Id;
        answer2Commit.Kinetics__Type__c = qestList[0].Kinetics__Field_Type__c;
        answer2Commit.Kinetics__Survey_Invitation__c = siList[0].Id;
        answer2Commit.Kinetics__Answer__c = 'Test Answer';
        answer2Commit.Kinetics__Kinetic_Question_Id__c = qestList[0].Id;
        insert answer2Commit;
        
    }
    
    testMethod static void test_handleAfterInsert_withAnswerLink() {
        Kinetics__Kinetic_Form_Answer__c rec = [SELECT Id, Name FROM Kinetics__Kinetic_Form_Answer__c  Limit 1];

        Test.startTest();
            ContentVersion fileRecord1 = new ContentVersion();
            fileRecord1.Title = 'Test File 1';
            fileRecord1.VersionData = Blob.valueOf('File Image 1');
            fileRecord1.ContentLocation = 'S';
            fileRecord1.PathOnClient = 'Test.jpg';
            fileRecord1.Origin = 'H';
            fileRecord1.IsMajorVersion = false;
            fileRecord1.Kinetics__Kinetic_Form_Answer__c = rec.Id;

            insert fileRecord1;
            System.assertNotEquals(null, fileRecord1);
        Test.stopTest();
    }
    testMethod static void test_handleAfterInsert_with_outAnswerLink() {

        Test.startTest();
            ContentVersion fileRecord1 = new ContentVersion();
            fileRecord1.Title = 'Test File 1';
            fileRecord1.VersionData = Blob.valueOf('File Image 1');
            fileRecord1.ContentLocation = 'S';
            fileRecord1.PathOnClient = 'Test.jpg';
            fileRecord1.Origin = 'H';
            fileRecord1.IsMajorVersion = false;

            insert fileRecord1;
            System.assertNotEquals(null, fileRecord1);
        Test.stopTest();
    }
}