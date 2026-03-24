/**
* Author: Shankar Dupade(FieldKo)
* Updated : 07th March 2024
* Purpose: Test Class for AsstCreateAssistantsController
 */

 @isTest
public with sharing class AsstCreateAssistantsControllerTest {


    @TestSetup
    private static void generateTestData() {
       

    }
     
    @isTest
    static void testcreateAssistants() {
                  
        Test.setMock(HttpCalloutMock.class, new GetAssistanceRestMock());
        Test.startTest();
            String parsedResponse = AsstCreateAssistantsController.createAssistants();
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }

    private class GetAssistanceRestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '{"object": "list", "data": [{"id": "asst_asdbcxcd", "object": "assistant", "created_at":1709519085, "name": "test assistant", "description": null, "model": "gpt-4", "instructions":"testing instructions", "tools": [{ "type":"retrieval"}], "metadata":{}, "file_ids":[]}]}';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
}