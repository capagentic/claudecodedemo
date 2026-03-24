/**
 * Author: Shankar Dupade (FieldKo)
 * Purpose: Test class for controller class which is used for OpenAIFileController
 * Date: 9-March-2024
 */

 @isTest
public with sharing class OpenAIFileControllerTest {
   
    @isTest
    private static void uploadFile_test() {
        ContentVersion fileRecord1 = new ContentVersion();
		fileRecord1.Title = 'Test File 1';
		fileRecord1.VersionData = Blob.valueOf('File Image 1');
		fileRecord1.ContentLocation = 'S';
		fileRecord1.PathOnClient = 'Test.jpg';
		fileRecord1.Origin = 'H';
		fileRecord1.IsMajorVersion = false;

		insert fileRecord1;
        ContentVersion version1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileRecord1.Id];

        Test.setMock(HttpCalloutMock.class, new OpenAIAssistantFileUploadMock());
        Test.startTest();
            System.AssertNotEquals(UserInfo.getUserId(), null);
           
            String res = OpenAIFileController.uploadFile(fileRecord1.Title,version1.ContentDocumentId);
            System.AssertNotEquals(res, null);
        Test.stopTest();
    }
    @isTest
    private static void uploadFile_delete() {
        ContentVersion fileRecord1 = new ContentVersion();
		fileRecord1.Title = 'Test File 1';
		fileRecord1.VersionData = Blob.valueOf('File Image 1');
		fileRecord1.ContentLocation = 'S';
		fileRecord1.PathOnClient = 'Test.jpg';
		fileRecord1.Origin = 'H';
		fileRecord1.IsMajorVersion = false;
        fileRecord1.Kinetics__External_ID__c = 'externalID';

		insert fileRecord1;
        ContentVersion version1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileRecord1.Id limit 1];

        Test.setMock(HttpCalloutMock.class, new OpenAIAssistantFileUploadMock());
        Test.startTest();
            System.AssertNotEquals(UserInfo.getUserId(), null);
           
            String res = OpenAIFileController.deleteFile(version1.ContentDocumentId);
        Test.stopTest();
    }

    private class OpenAIAssistantFileUploadMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullResponse = '{"id":"asdazsd", "status": "Sucess"}'; 
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullResponse);
            res.setStatusCode(200);
            return res;
        }
    }
}