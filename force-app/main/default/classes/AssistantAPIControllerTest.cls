/**
* Author: Shankar Dupade(FieldKo)
* Updated : 07th March 2024
* Purpose: Test Class for AssistantAPIController
 */

 @isTest
 public with sharing class AssistantAPIControllerTest {
 
    @TestSetup
    private static void generateTestData() {
       

    }
     
    @isTest
    static void testcreate_update_Assistance() {
                  
        Map<String, String> requestBodyMap = new Map<String, String>();
        requestBodyMap.put('instructions', 'instructions');
        requestBodyMap.put('name', 'Test assistant');
        requestBodyMap.put('model', 'gpt-4');
        requestBodyMap.put('code_interpreter', 'true');
        requestBodyMap.put('retrieval', 'true');
        requestBodyMap.put('assistantID', 'asst_UruYGBBr1MIhLvhRkMssr44c');
        
        Test.setMock(HttpCalloutMock.class, new CreateAssistanceRestMock());
        Test.startTest();
            String parsedResponse = AssistantAPIController.create_update_Assistance(requestBodyMap);
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }
    @isTest
    static void testdelete_Assistance() {
                  
        Map<String, String> requestBodyMap = new Map<String, String>();
        requestBodyMap.put('instructions', 'instructions');
        requestBodyMap.put('name', 'Test assistant');
        requestBodyMap.put('model', 'gpt-4');
        requestBodyMap.put('code_interpreter', 'true');
        requestBodyMap.put('retrieval', 'true');
        requestBodyMap.put('assistantID', 'asst_UruYGBBr1MIhLvhRkMssr44c');
        
        Test.setMock(HttpCalloutMock.class, new CreateAssistanceRestMock());
        Test.startTest();
            String parsedResponse = AssistantAPIController.delete_Assistance(requestBodyMap);
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }
    @isTest
    static void testCreate_update_Thread() {
                  
        Map<String, String> requestBodyMap = new Map<String, String>();
        requestBodyMap.put('instructions', 'instructions');
        requestBodyMap.put('name', 'Test assistant');
        requestBodyMap.put('model', 'gpt-4');
        requestBodyMap.put('code_interpreter', 'true');
        requestBodyMap.put('retrieval', 'true');
        requestBodyMap.put('assistantID', 'asst_UruYGBBr1MIhLvhRkMssr44c');
        
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('threadId', 'thread_asdasdas');
        inputMap.put('callTranscript', 'test transcription text');
        inputMap.put('sfRecordId', 'meetingList[0].Id');
        inputMap.put('sfRecordName', 'meetingList[0].Name');
        inputMap.put('promptTemplateName', 'meetingList[0].Kinetics__Prompt_Template__r.Name');
        inputMap.put('assistantName', 'meetingList[0].Kinetics__Prompt_Template__r.Kinetics__Assistant__r.Name');
        

        Test.setMock(HttpCalloutMock.class, new CreateAssistanceRestMock());
        Test.startTest();
            String parsedResponse = AssistantAPIController.create_update_Thread(inputMap);
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }

    @isTest
    static void testCreate_update_Message() {
                  
        Map<String, String> requestBodyMap = new Map<String, String>();
        requestBodyMap.put('instructions', 'instructions');
        requestBodyMap.put('name', 'Test assistant');
        requestBodyMap.put('model', 'gpt-4');
        requestBodyMap.put('code_interpreter', 'true');
        requestBodyMap.put('retrieval', 'true');
        requestBodyMap.put('assistantID', 'asst_UruYGBBr1MIhLvhRkMssr44c');
        
        Test.setMock(HttpCalloutMock.class, new CreateAssistanceRestMock());
        Test.startTest();
            String parsedResponse = AssistantAPIController.create_update_Message('test request payload', 'thread_asdasdas');
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }
    
    @isTest
    static void testCreate_Run() {
                  
        Map<String, String> requestBodyMap = new Map<String, String>();
        requestBodyMap.put('instructions', 'instructions');
        requestBodyMap.put('name', 'Test assistant');
        requestBodyMap.put('model', 'gpt-4');
        requestBodyMap.put('code_interpreter', 'true');
        requestBodyMap.put('retrieval', 'true');
        requestBodyMap.put('assistantID', 'asst_UruYGBBr1MIhLvhRkMssr44c');
        
        Test.setMock(HttpCalloutMock.class, new CreateAssistanceRestMock());
        Test.startTest();
            String parsedResponse = AssistantAPIController.create_Run('asst_asdasas', 'thread_asdasdas');
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }
    
    @isTest
    static void testRetriveAllMessagesForThread() {
                  
        Map<String, String> requestBodyMap = new Map<String, String>();
        requestBodyMap.put('instructions', 'instructions');
        requestBodyMap.put('name', 'Test assistant');
        requestBodyMap.put('model', 'gpt-4');
        requestBodyMap.put('code_interpreter', 'true');
        requestBodyMap.put('retrieval', 'true');
        requestBodyMap.put('assistantID', 'asst_UruYGBBr1MIhLvhRkMssr44c');
        
        Test.setMock(HttpCalloutMock.class, new CreateAssistanceRestMock());
        Test.startTest();
            String parsedResponse = AssistantAPIController.retriveAllMessagesForThread('thread_asdasdas');
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }
    
    @isTest
    static void testGetAllAvailableAssistants() {
                  
        Map<String, String> requestBodyMap = new Map<String, String>();
        requestBodyMap.put('instructions', 'instructions');
        requestBodyMap.put('name', 'Test assistant');
        requestBodyMap.put('model', 'gpt-4');
        requestBodyMap.put('code_interpreter', 'true');
        requestBodyMap.put('retrieval', 'true');
        requestBodyMap.put('assistantID', 'asst_UruYGBBr1MIhLvhRkMssr44c');
        
        Test.setMock(HttpCalloutMock.class, new CreateAssistanceRestMock());
        Test.startTest();
            String parsedResponse = AssistantAPIController.getAllAvailableAssistants();
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }



    private class createAssistanceRestMock implements HttpCalloutMock {

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
 }