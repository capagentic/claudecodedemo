/**
 * Author: Shankar Dupade
 * Date: 11th Sept 2023
 * Purpose: Test class for ChatGptManagerController
 */
@isTest
public with sharing class ChatGptManagerControllerTest {
    
    @TestSetup
    static void createData() {
        Kinetics__GPT_Usage__c gptU = new Kinetics__GPT_Usage__c();
        gptU.Kinetics__Token_Available__c = 1000;
        upsert gptU;

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
    static void test_hasManagerPanelAccess() {
        Test.startTest();
            String isGPTManagerString = ChatGptManagerController.hasManagerPanelAccess();
            PermissionSet ps = [SELECT Id, Name FROM PermissionSet WHERE Name = 'ChatGPT_Manager'];
            try{ 
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.PermissionSetId = ps.Id;
                psa.AssigneeId = UserInfo.getUserId();
                insert psa;
            }catch(Exception exe) {

            }
            isGPTManagerString = ChatGptManagerController.hasManagerPanelAccess();
            
            System.assertNotEquals(null, isGPTManagerString);
        Test.stopTest();
    }
    @isTest
    static void test_getCurrentUsage() {
        Test.startTest();
        String resp = ChatGptManagerController.getCurrentUsage();
    
        System.assertNotEquals(null, resp);
        Test.stopTest();
    }
    @isTest
    static void test_updateGptUsage() {
        Test.startTest();
            Boolean resp = ChatGptManagerController.updateGptUsage(10);
        Test.stopTest();
    }
    @isTest
    static void test_getGptJobList() {
        Test.startTest();
            GPT_Job__c gj = new GPT_Job__c();
            gj.Completion_Token__c = 10;
            gj.Prompt_Token__c = 10;
            gj.Type__c = 'Summary';
            insert gj;
            
            String resp = ChatGptManagerController.getGptJobList();
            System.assertNotEquals(null, resp);
        Test.stopTest();
    }
    
    
}