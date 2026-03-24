/**
 * Author: Shankar Dupade (FieldKo)
 * Purpose: Test class for controller class which is used for SmsService
 * Date: 10 Auth 2021
 */
@isTest
public with sharing class SmsServiceTest {
    
    @TestSetup
    public static void createData() {
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        TestDataFactory.createContact(accList);
    }
    @IsTest
    static void test_sendSMSAsync(){
        Test.setMock(HttpCalloutMock.class, new SendSMSMock());
        Test.startTest();
            SmsService smsobj = new SmsService();
            Contact c = [select Id, MobilePhone from Contact where MobilePhone != null limit 1];
            System.assertNotEquals(c, null);
            SmsService.sendSMSAsync(c.MobilePhone, 'This is test message sent from Test class');
        Test.stopTest();
    }

    @IsTest
    static void test_sendSMS(){
        Test.setMock(HttpCalloutMock.class, new SendSMSMock());
        Test.startTest();
            SmsService smsobj = new SmsService();
            Contact c = [select Id, MobilePhone from Contact where MobilePhone != null limit 1];
            System.assertNotEquals(c, null);
            SmsService.sendSMS(c.MobilePhone, 'This is test message sent from Test class');
        Test.stopTest();
    }

    private class SendSMSMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullResponse = '<PublishResponse xmlns="http://sns.amazonaws.com/doc/2010-03-31/">';
            fullResponse = fullResponse + '<PublishResult> <MessageId>ef55013a-e715-5c8a-9bde-58b697f49e40</MessageId></PublishResult>';
            fullResponse = fullResponse + '<ResponseMetadata>';
            fullResponse = fullResponse + '<RequestId>b3307410-bf74-5525-a404-2d9ccf9587ef</RequestId>';
            fullResponse = fullResponse + '</ResponseMetadata>';
            fullResponse = fullResponse + '</PublishResponse>';
            
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullResponse);
            res.setStatusCode(200);
            return res;
        }
    }
}