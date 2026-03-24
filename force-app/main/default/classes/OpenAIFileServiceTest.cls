/**
 * Author: Shankar Dupade (FieldKo)
 * Purpose: Test class for controller class which is used for ProcessCallTranscriptionHomeController
 * Date: 23 Feb 2024
 */

 @isTest
public with sharing class OpenAIFileServiceTest {
   
    @isTest
    private static void uploadFile_test() {
        Test.setMock(HttpCalloutMock.class, new OpenAIAssistantFileUploadMock());
        Test.startTest();
            System.AssertNotEquals(UserInfo.getUserId(), null);
           
            String res = OpenAIFileService.uploadFile('testapikey', 'test file name', Blob.valueOf('test data'));
            System.AssertNotEquals(res, null);
        Test.stopTest();
    }
    @isTest
    private static void uploadFile_delete() {
        Test.setMock(HttpCalloutMock.class, new OpenAIAssistantFileUploadMock());
        Test.startTest();
            System.AssertNotEquals(UserInfo.getUserId(), null);
           
            Boolean res = OpenAIFileService.deleteFile('testapikey', 'file_testfileId');
        Test.stopTest();
    }

    private class OpenAIAssistantFileUploadMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullResponse = 'sucess response'; 
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullResponse);
            res.setStatusCode(201);
            return res;
        }
    }
}