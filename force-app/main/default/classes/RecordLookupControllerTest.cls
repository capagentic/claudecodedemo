/**
 * Author: Shankar Dupade (FieldKo)
 * Purpose: Test class for controller class which is used for RecordLookup
 * Date: 10 Auth 2021
 */
@isTest
public with sharing class RecordLookupControllerTest {
    
    @TestSetup
    static void createData(){
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        TestDataFactory.createContact(accList);
    }

    @IsTest
    static void test_findRecords_account(){
        Test.startTest();
            List<sobject> accountList = RecordLookupController.findRecords('account', 'Account');
            System.assertNotEquals(accountList.size(), 0);
        Test.stopTest();
    }
    @IsTest
    static void test_findRecords_Contact(){
        Test.startTest();
            List<sobject> conList = RecordLookupController.findRecords('test', 'Contact');
            System.assertNotEquals(conList.size(), 0);
        Test.stopTest();
    }
    @IsTest
    static void test_findRecords_empty(){
        Test.startTest();
            List<sobject> conList = RecordLookupController.findRecords('contactNotAvailable', 'Contact');
            System.assertEquals(conList.size(), 0);
        Test.stopTest();
    }
}