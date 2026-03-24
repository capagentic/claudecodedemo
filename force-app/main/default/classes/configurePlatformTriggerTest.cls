/**
* Author: Shankar Dupade(FieldKo)
* Updated : 31st Aug 2021
* Purpose: Test Class for configurePlatformTrigger
*/
@isTest
public with sharing class configurePlatformTriggerTest {
    static String responseString = '{"id":"3JK000000000000000","success":true,"errors":[],"warnings":[],"infos":[]}';

    @IsTest
    static void test_setRunningUserForKineticInviteReminderTrigger(){
        Test.setMock(HttpCalloutMock.class, new PlatformConfigurationMock());
        Test.startTest();
            System.AssertNotEquals(UserInfo.getUserId(), null);
            HttpResponse res = configurePlatformTrigger.setRunningUserForKineticInviteReminderTrigger(UserInfo.getUserId());
        Test.stopTest();
    }

    @IsTest
    static void test_setRunningUserForKineticInviteJobTrigger(){
        Test.setMock(HttpCalloutMock.class, new PlatformConfigurationMock());
        Test.startTest();
            System.AssertNotEquals(UserInfo.getUserId(), null);
            HttpResponse res = configurePlatformTrigger.setRunningUserForKineticInviteJobTrigger(UserInfo.getUserId());
        Test.stopTest();
    }

    private class PlatformConfigurationMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullResponse = configurePlatformTriggerTest.responseString; 
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullResponse);
            res.setStatusCode(201);
            return res;
        }
    }
}