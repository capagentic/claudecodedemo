/**
 * Auther: Shankar Dupade
 * Purpose: test classes for KineticAssistantTrigger
 * Date: 08-Mar-2024
 */
@isTest
public with sharing class KineticAssistantTriggerTest {
   
    @isTest
    private static void testInsert() {
        TestDataFactory.configureGPTSetting();
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
            Kinetics__Assistant__c asst = new Kinetics__Assistant__c();
            asst.Kinetics__ChatGPT_Id__c = 'asst_asdasf';
            asst.Kinetics__File_Ids__c = '[]';
            asst.Kinetics__Instructions__c = 'test assistant instruction';
            asst.Kinetics__Model__c = 'gpt-4';
            asst.Name = 'test assistant';
            asst.Kinetics__Retrieval__c = true;
            asst.Kinetics__Code_Interpreter__c = true;
            insert asst;
        Test.stopTest();
    }
    @isTest
    private static void testUpdate() {
        TestDataFactory.configureGPTSetting();
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
            Kinetics__Assistant__c asst = new Kinetics__Assistant__c();
            asst.Kinetics__ChatGPT_Id__c = 'asst_asdasf';
            asst.Kinetics__File_Ids__c = '[]';
            asst.Kinetics__Instructions__c = 'test assistant instruction';
            asst.Kinetics__Model__c = 'gpt-4';
            asst.Name = 'test assistant';
            asst.Kinetics__Retrieval__c = true;
            asst.Kinetics__Code_Interpreter__c = true;
            insert asst;
            asst.Name = 'test assistant update';
            update asst;

        Test.stopTest();
    }
    @isTest
    private static void testDelete() {
        TestDataFactory.configureGPTSetting();
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new GPTCallTranscription_delete_RestMock());
            Kinetics__Assistant__c asst = new Kinetics__Assistant__c();
            asst.Kinetics__ChatGPT_Id__c = 'asst_asdasf';
            asst.Kinetics__File_Ids__c = '[]';
            asst.Kinetics__Instructions__c = 'test assistant instruction';
            asst.Kinetics__Model__c = 'gpt-4';
            asst.Name = 'test assistant';
            asst.Kinetics__Retrieval__c = true;
            asst.Kinetics__Code_Interpreter__c = true;
            insert asst;
            
            delete asst;
            
        Test.stopTest();
    }
    private class GPTCallTranscriptionRestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '{"id": "asst_UruYGBBr1MIhLvhRkMssr44c","object": "assistant","created_at": 1709786044,"name": "test record from sf",';
            fullJson = fullJson + '"description": null, "model": "gpt-4-turbo-preview","instructions": "test record from sf","tools": [], "metadata": {},';
            fullJson = fullJson + '"file_ids": []}';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
    private class GPTCallTranscription_delete_RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '{"id": "asst_UruYGBBr1MIhLvhRkMssr44c","object": "assistant.deleted","deleted": true}';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
}