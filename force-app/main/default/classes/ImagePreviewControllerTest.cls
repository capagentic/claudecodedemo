/**
* Author: Shankar Dupade(FieldKo)
* Updated : 6th Sept 2021
* Purpose: Test Class for ImagePreviewController
*/
@isTest
public with sharing class ImagePreviewControllerTest {
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
        ContentVersion fileRecord1 = new ContentVersion();
        fileRecord1.Title = 'Test File 1';
        fileRecord1.VersionData = Blob.valueOf('File Image 1');
        fileRecord1.ContentLocation = 'S';
        fileRecord1.PathOnClient = 'Test.jpg';
        fileRecord1.Origin = 'H';
        fileRecord1.IsMajorVersion = false;
        fileRecord1.Kinetics__Kinetic_Form_Answer__c = ansList[0].Id;

        insert fileRecord1;
        System.assertNotEquals(null, fileRecord1);
    }

    @isTest
    static void test_getImageURLForRelatedRecord_with_outObjectName() {
        List<Kinetics__Kinetic_Form_Answer__c> kfaList = [SELECT Id, Kinetics__Attachment_URL__c from Kinetics__Kinetic_Form_Answer__c LIMIT 1];
        Test.startTest();
            System.assertNotEquals(kfaList.size(), 0);
            String objectAPIName = '';
            String recordId = kfaList[0].Id;
            String urlFieldName = 'Kinetics__Attachment_URL__c';
            try {
                String attachmentURL = ImagePreviewController.getImageURLForRelatedRecord(objectAPIName, recordId, urlFieldName);                
            } catch(Exception exc) {
                System.assertNotEquals(exc.getMessage(), null);
            }
        Test.stopTest();
    }
    @isTest
    static void test_getImageURLForRelatedRecord_withAllValues() {
        List<Kinetics__Kinetic_Form_Answer__c> kfaList = [SELECT Id, Kinetics__Attachment_URL__c from Kinetics__Kinetic_Form_Answer__c LIMIT 1];
        Test.startTest();
            System.assertNotEquals(kfaList.size(), 0);
            String objectAPIName = 'Kinetics__Kinetic_Form_Answer__c';
            String recordId = kfaList[0].Id;
            String urlFieldName = 'Kinetics__Attachment_URL__c';
            try{
                String attachmentURL = ImagePreviewController.getImageURLForRelatedRecord(objectAPIName, recordId, urlFieldName);
            } catch(Exception exc) {
                System.assertNotEquals(exc.getMessage(), null);
            }
        Test.stopTest();
    }
    @isTest
    static void test_getImageURLForRelatedRecord_with_outRecordId() {
        List<Kinetics__Kinetic_Form_Answer__c> kfaList = [SELECT Id, Kinetics__Attachment_URL__c from Kinetics__Kinetic_Form_Answer__c LIMIT 1];
        Test.startTest();
            System.assertNotEquals(kfaList.size(), 0);
            String objectAPIName = 'Kinetics__Kinetic_Form_Answer__c';
            String recordId = '';
            String urlFieldName = 'Kinetics__Attachment_URL__c';
            try{
                String attachmentURL = ImagePreviewController.getImageURLForRelatedRecord(objectAPIName, recordId, urlFieldName);
            } catch(Exception exc) {
                System.assertNotEquals(exc.getMessage(), null);
            }
        Test.stopTest();
    }
    @isTest
    static void test_getImageURLForRelatedRecord_withWrongRecordId() {
        List<Kinetics__Kinetic_Form_Answer__c> kfaList = [SELECT Id, Kinetics__Attachment_URL__c from Kinetics__Kinetic_Form_Answer__c LIMIT 1];
        Test.startTest();
            System.assertNotEquals(kfaList.size(), 0);
            String objectAPIName = 'Kinetics__Kinetic_Form_Answer__c';
            String recordId = 'UNKNOWN_RECORD_ID';
            String urlFieldName = 'Kinetics__Attachment_URL__c';
            try{
                String attachmentURL = ImagePreviewController.getImageURLForRelatedRecord(objectAPIName, recordId, urlFieldName);
            } catch(Exception exc) {
                System.assertNotEquals(exc.getMessage(), null);
            }
        Test.stopTest();
    }
    @isTest
    static void test_getImageURLForRelatedRecord_with_outurlFieldName() {
        List<Kinetics__Kinetic_Form_Answer__c> kfaList = [SELECT Id, Kinetics__Attachment_URL__c from Kinetics__Kinetic_Form_Answer__c LIMIT 1];
        Test.startTest();
            System.assertNotEquals(kfaList.size(), 0);
            String objectAPIName = 'Kinetics__Kinetic_Form_Answer__c';
            String recordId = kfaList[0].Id;
            String urlFieldName = '';
            try{
                String attachmentURL = ImagePreviewController.getImageURLForRelatedRecord(objectAPIName, recordId, urlFieldName);
            } catch(Exception exc) {
                System.assertNotEquals(exc.getMessage(), null);
            }
        Test.stopTest();
    }
}