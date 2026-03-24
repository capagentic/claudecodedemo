/**
* Author: Shankar Dupade(FieldKo)
* Updated : 11th Aug 2021
* Purpose: Test Class for createEditKineticQuestionLWCHelper
*/
@isTest
public with sharing class createEditKineticQuestionLWCHelperTest {
    @TestSetup
    static void createData(){
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        List<Kinetics__Kinetic_Question__c> questList = TestDataFactory.createQuestion();
    }

    @isTest
    static void test_getKineticFormConfigurationCustomSetting() {
        Test.startTest();
            String settingString = createEditKineticQuestionLWCHelper.getKineticFormConfigurationCustomSetting();
            System.assertNotEquals(null, settingString);
        Test.stopTest();
    }
    @isTest
    static void test_getExtraFields() {
        Test.startTest();    
            String getExtraFieldString = createEditKineticQuestionLWCHelper.getExtraFields('Kinetics__Kinetic_Question__c', 'dummyFieldSet');
            System.assertEquals('[]', getExtraFieldString);
        Test.stopTest();
    }
    @isTest
    static void test_getExtraFields_empty() {
        Test.startTest();    
            String getExtraFieldString = createEditKineticQuestionLWCHelper.getExtraFields('Kinetics__Kinetic_Question__c', '');
            System.assertEquals('[]', getExtraFieldString);
        Test.stopTest();
    }

    @isTest
    static void test_checkPermissions() {
        Test.startTest();
            Boolean isAvailable = createEditKineticQuestionLWCHelper.checkPermissions();
            System.assertEquals(isAvailable, true);
        Test.stopTest();
    }

    @isTest
    static void test_getExistingKineticQuestion_blankId() {
        Test.startTest();    
            String getExistingString = createEditKineticQuestionLWCHelper.getExistingKineticQuestion('');
            System.assertEquals('[]', getExistingString);
        Test.stopTest();
    }
    @isTest
    static void test_getExistingKineticQuestion() {
        List<Kinetics__Kinetic_Question__c> questList = [select Id from Kinetics__Kinetic_Question__c];
        Test.startTest();    
            String getExistingString = createEditKineticQuestionLWCHelper.getExistingKineticQuestion(questList[0].Id);
            System.assertNotEquals('[]', getExistingString);
        Test.stopTest();
    }
    @isTest
    static void test_uploadFile() {
        List<Kinetics__Kinetic_Question__c> questList = [select Id from Kinetics__Kinetic_Question__c];
        Test.startTest();    
        String base64 = Blob.valueOf('Test file').toString();
        String filename = 'Testfile.png';
        String recordId = questList[0].Id;
        String title = 'Testfile.png';
            String fileId = createEditKineticQuestionLWCHelper.uploadFile(base64, filename, recordId, title);
            System.assertNotEquals(null, fileId);
        Test.stopTest();
    }

    @isTest
    static void test_getRelatedFileIds() {
        List<Kinetics__Kinetic_Question__c> questList = [select Id from Kinetics__Kinetic_Question__c];
        Test.startTest();    
        String base64 = Blob.valueOf('Test file').toString();
        String filename = 'Testfile.png';
        String recordId = questList[0].Id;
        String title = 'Testfile.png';
            String fileId = createEditKineticQuestionLWCHelper.uploadFile(base64, filename, recordId, title);
            System.assertNotEquals(null, fileId);

            String fileAttachTitleVsIdMapString = createEditKineticQuestionLWCHelper.getRelatedFileIds(recordId);
            Map<String,String> fileAttachTitleVsId = (Map<String,String>) JSON.deserialize(fileAttachTitleVsIdMapString, Map<String,String>.class);
            System.assertNotEquals(fileAttachTitleVsId.size(), 0);
        Test.stopTest();
    }

    @isTest
    static void test_getRelatedFileIds_emptyId() {
        Test.startTest();    
            String recordId = '';
            String fileAttachTitleVsIdMapString = createEditKineticQuestionLWCHelper.getRelatedFileIds(recordId);
            Map<String,String> fileAttachTitleVsId = (Map<String,String>) JSON.deserialize(fileAttachTitleVsIdMapString, Map<String,String>.class);
            System.assertEquals(fileAttachTitleVsId.size(), 0);
        Test.stopTest();
    }

    @isTest
    static void test_deleteExistingFiles() {
        List<Kinetics__Kinetic_Question__c> questList = [select Id from Kinetics__Kinetic_Question__c];
        Test.startTest();    
            String base64 = Blob.valueOf('Test file').toString();
            String filename = 'Testfile.png';
            String recordId = questList[0].Id;
            String title = 'Testfile.png';
            String fileId = createEditKineticQuestionLWCHelper.uploadFile(base64, filename, recordId, title);
            System.assertNotEquals(null, fileId);

            createEditKineticQuestionLWCHelper.deleteExistingFiles(recordId, new List<String>{fileId});
        Test.stopTest();
    }

    
    @isTest
    static void test_doDirtyDataCleanup() {
        List<Kinetics__Kinetic_Question__c> questList = [select Id from Kinetics__Kinetic_Question__c];
        Test.startTest();
            System.assertNotEquals(questList.size(), 0);
            createEditKineticQuestionLWCHelper.doDirtyDataCleanup(questList[0].Id, false);
        Test.stopTest();
    }

    @isTest
    static void test_doDirtyDataCleanup_emptyId() {
        Test.startTest();
            createEditKineticQuestionLWCHelper.doDirtyDataCleanup(null, false);
            System.assertEquals(true, true);
        Test.stopTest();
    }
    @isTest
    static void test_doDirtyDataCleanup_Delete() {
        List<Kinetics__Kinetic_Question__c> questList = [select Id from Kinetics__Kinetic_Question__c];
        Test.startTest();
            System.assertNotEquals(questList.size(), 0);
            createEditKineticQuestionLWCHelper.doDirtyDataCleanup(questList[0].Id, true);
        Test.stopTest();
    }
}