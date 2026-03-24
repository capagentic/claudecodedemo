/**
* Author: Shankar Dupade(FieldKo)
* Updated : 31st Aug 2021
* Purpose: Test Class for HttpRequestService
*/
@isTest
public with sharing class HttpRequestServiceTest {
    static String responseString = '{"id":"3JK000000000000000","success":true,"errors":[],"warnings":[],"infos":[]}';

    @IsTest
    static void test_doRequest_setRunningUserForKineticInviteReminderTrigger(){
        Test.setMock(HttpCalloutMock.class, new PlatformConfigurationMock());
        Test.startTest();
            System.AssertNotEquals(UserInfo.getUserId(), null);
            //using this method to cover the Http helper method 
            HttpResponse res = configurePlatformTrigger.setRunningUserForKineticInviteReminderTrigger(UserInfo.getUserId());
        Test.stopTest();
    }

    private class PlatformConfigurationMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullResponse = HttpRequestServiceTest.responseString; 
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullResponse);
            res.setStatusCode(201);
            return res;
        }
    }
}