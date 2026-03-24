/**
* Author: Shankar Dupade(FieldKo)
* Updated : 10th Aug 2021
* Purpose: Test Class for collecting ids of contacts selected from list view on contact tab
*/
@isTest
public with sharing class getSelectedRecipientControllerTest {
    
    @TestSetup
    static void createData(){
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        List<Contact> conList = TestDataFactory.createContact(accList);
    }

    @IsTest
    static void test_getSelectedRecipientControllerConstructor(){
        
        List<Contact> conList = [select Id, Name, FirstName, LastName from Contact];
        Test.startTest();
            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(conList);
            sc.setSelected(conList);
            getSelectedRecipientController testContactInstance = new getSelectedRecipientController(sc);
            System.assertNotEquals(testContactInstance.conIdsString, null);
        Test.stopTest();
    }
    @IsTest
    static void test_getSelectedRecipientControllerConstructor_zeroSelected(){
        
        List<Contact> conList = [select Id, Name, FirstName, LastName from Contact];
        Test.startTest();
            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(conList);
            getSelectedRecipientController testContactInstance = new getSelectedRecipientController(sc);
            System.assertNotEquals(testContactInstance.conIdsString, null);
        Test.stopTest();
    }
}