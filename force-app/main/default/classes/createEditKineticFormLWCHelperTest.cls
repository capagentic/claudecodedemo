/**
* Author: Shankar Dupade(FieldKo)
* Updated : 11th Aug 2021
* Purpose: Test Class for createEditKineticFormLWCHelper
*/
@isTest
public with sharing class createEditKineticFormLWCHelperTest {
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
    static void test_getSurveyConfigurationCustomSetting() {
        Test.startTest();
            String settingString = createEditKineticFormLWCHelper.getSurveyConfigurationCustomSetting();
            System.assertNotEquals(null, settingString);
        Test.stopTest();
    }
    @isTest
    static void test_getExtraFields() {
        Test.startTest();    
            String getExtraFieldString = createEditKineticFormLWCHelper.getExtraFields('Kinetics__Kinetic_Form__c', 'dummyFieldSet');
            System.assertEquals('[]', getExtraFieldString);
        Test.stopTest();
    }
    @isTest
    static void test_getExtraFields_empty() {
        Test.startTest();    
            String getExtraFieldString = createEditKineticFormLWCHelper.getExtraFields('Kinetics__Kinetic_Form__c', '');
            System.assertEquals('[]', getExtraFieldString);
        Test.stopTest();
    }

    @isTest
    static void test_checkPermissions() {
        Test.startTest();
            Boolean isAvailable = createEditKineticFormLWCHelper.checkPermissions();
            System.assertEquals(isAvailable, true);
        Test.stopTest();
    }

    @isTest
    static void test_getExistingKineticForms_blankId() {
        Test.startTest();    
            String getExistingString = createEditKineticFormLWCHelper.getExistingKineticForms('');
            System.assertEquals('[]', getExistingString);
        Test.stopTest();
    }
    @isTest
    static void test_getExistingKineticForms() {
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];
        Test.startTest();    
            String getExistingString = createEditKineticFormLWCHelper.getExistingKineticForms(formList[0].Id);
            System.assertNotEquals('[]', getExistingString);
        Test.stopTest();
    }
    @isTest
    static void test_doDirtyDataCleanup() {
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];
        Test.startTest();
            System.assertNotEquals(formList.size(), 0);
            createEditKineticFormLWCHelper.doDirtyDataCleanup(formList[0].Id, false);
            
        Test.stopTest();
    }
    @isTest
    static void test_doDirtyDataCleanup_delete() {
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];
        Test.startTest();    
            System.assertNotEquals(formList.size(), 0);
            createEditKineticFormLWCHelper.doDirtyDataCleanup(formList[0].Id, true);
        Test.stopTest();
    }
    @isTest
    static void test_doDirtyDataCleanup_empty() {
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];
        Test.startTest();    
            System.assertNotEquals(formList.size(), 0);
            createEditKineticFormLWCHelper.doDirtyDataCleanup(null, false);
        Test.stopTest();
    }

    @isTest
    static void test_getAllActiveKineticQuestions() {
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];
        Test.startTest();    
            System.assertNotEquals(formList.size(), 0);
            createEditKineticFormLWCHelper.getAllActiveKineticQuestions(formList[0].Id);
        Test.stopTest();
    }
    @isTest
    static void test_getAllActiveKineticQuestions_empty() {
        Test.startTest();  
            String result = createEditKineticFormLWCHelper.getAllActiveKineticQuestions(null);
            System.assertNotEquals(result, null);  
        Test.stopTest();
    }
    
    @isTest
    static void test_upsertKineticQuestions() {
        List<Kinetics__Kinetic_Form__c> formList = [select Id from Kinetics__Kinetic_Form__c];
        List<Kinetics__Kinetic_Question__c> questList = [select Id from Kinetics__Kinetic_Question__c];
        Test.startTest();   
            System.assertNotEquals(formList.size(), 0);
            List<Map<String,String>> listOfRecordsMapList = new List<Map<String, String>>();
            Map<String, String> listOfRecordsMap = new Map<String, String>();
            listOfRecordsMap.put('qid', questList[0].Id);
            listOfRecordsMap.put('index', '1');

            listOfRecordsMapList.add(listOfRecordsMap);
            String listwrapperString = JSON.serialize(listOfRecordsMapList);
            String kFormId = formList[0].Id;
            String existingKFormQuestionIdsString = JSON.serialize(new Set<String>());
            createEditKineticFormLWCHelper.upsertKineticQuestions(listwrapperString, kFormId, existingKFormQuestionIdsString);
        Test.stopTest();
    }
}