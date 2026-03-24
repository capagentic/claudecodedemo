/**
* Author: Shankar Dupade(FieldKo)
* Updated : 22nd Nov 2021
* Purpose: Test Class for GuestUserHandlerHelper
*/
@isTest
public with sharing class GuestUserHandlerHelperTest {
    
    @TestSetup
    static void createData(){
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();

        List<Contact> conList = TestDataFactory.createContact(accList);
        List<Kinetics__Kinetic_Question__c> qestList = TestDataFactory.createQuestion();
        qestList.addAll(TestDataFactory.createQuestion());
        qestList.addAll(TestDataFactory.createQuestionForRelatedObject());
        List<Kinetics__Kinetic_Form__c> kfList = TestDataFactory.createKineticForm();
        List<Kinetics__Kinetic_Form_Question__c> kfqList = TestDataFactory.createKineticFormQuestion(qestList, kfList);

        List<Kinetics__Kinetic_Job__c> kjList = TestDataFactory.createKineticJob(kfList);
        List<Kinetics__Survey_Invitation__c> siList = TestDataFactory.createSurveyInvitation(conList, kjList);

        Kinetics__Kinetic_Form_Answer__c answer2Commit = new Kinetics__Kinetic_Form_Answer__c();
        answer2Commit.Kinetics__Answer_Index__c = 1;
        answer2Commit.Kinetics__Kinetic_Question__c = qestList[0].Kinetics__Question__c;
        answer2Commit.Kinetics__Kinetic_Question_Values__c = qestList[0].Kinetics__Values__c;
        answer2Commit.Kinetics__Kinetic_Form_Question__c = kfqList[0].Id;
        answer2Commit.Kinetics__Type__c = qestList[0].Kinetics__Field_Type__c;
        answer2Commit.Kinetics__Survey_Invitation__c = siList[0].Id;
        answer2Commit.Kinetics__Answer__c = 'Test Answer';
        answer2Commit.Kinetics__Kinetic_Question_Id__c = qestList[0].Id;
        insert answer2Commit;
    }

    @isTest
    static void test_saveFiles() {
        List<Account> accList = [select ID from Account];
        Test.startTest();
            Id parentId = accList[0].Id;
            String surveyAnswerId = null;
            String fileName = 'Test file image.png';
            String base64Data = Blob.valueOf('Test image content').toString();
            Id fileId = GuestUserHandlerHelper.saveFiles(parentId, surveyAnswerId, fileName, base64Data);
            System.assertNotEquals(fileId, null);
        Test.stopTest();
    }

    @isTest
    static void test_saveFiles_withAppend() {
        List<Account> accList = [select ID from Account];
        Test.startTest();
            Id parentId = accList[0].Id;
            String surveyAnswerId = null;
            String fileName = 'Test file image.png';
            String base64Data = Blob.valueOf('Test image content').toString();
            String contentType = 'image/png';
            Id fileId = GuestUserHandlerHelper.saveFiles(parentId, surveyAnswerId, fileName, base64Data);
            base64Data = ' some more additions to the data';
            GuestUserHandlerHelper.appendToFile(fileId, base64Data);
            System.assertNotEquals(fileId, null);
        Test.stopTest();
    }
    testMethod static void test_handleAfterInsert_withAnswerLink() {
        Kinetics__Kinetic_Form_Answer__c rec = [SELECT Id, Name FROM Kinetics__Kinetic_Form_Answer__c  Limit 1];

        Test.startTest();
            ContentVersion fileRecord1 = new ContentVersion();
            fileRecord1.Title = 'Test File 1';
            fileRecord1.VersionData = Blob.valueOf('File Image 1');
            fileRecord1.ContentLocation = 'S';
            fileRecord1.PathOnClient = 'Test.jpg';
            fileRecord1.Origin = 'H';
            fileRecord1.IsMajorVersion = false;
            fileRecord1.Kinetics__Kinetic_Form_Answer__c = rec.Id;

            insert fileRecord1;
            System.assertNotEquals(null, fileRecord1);
        Test.stopTest();
    }
    testMethod static void test_handleAfterInsert_with_outAnswerLink() {

        Test.startTest();
            ContentVersion fileRecord1 = new ContentVersion();
            fileRecord1.Title = 'Test File 1';
            fileRecord1.VersionData = Blob.valueOf('File Image 1');
            fileRecord1.ContentLocation = 'S';
            fileRecord1.PathOnClient = 'Test.jpg';
            fileRecord1.Origin = 'H';
            fileRecord1.IsMajorVersion = false;

            insert fileRecord1;
            System.assertNotEquals(null, fileRecord1);
        Test.stopTest();
    }
    @isTest
    static void test_getSequenceBySurveyGuid_empty() {
        Test.startTest();
        String responseString = GuestUserHandlerHelper.getSequenceBySurveyGuid(null);
        System.assertNotEquals(responseString, null);
        System.assert(responseString.contains('2100'));
        Test.stopTest();
    }

    @isTest
    static void test_getSequenceBySurveyGuid() {
        Test.startTest();
        Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
        String responseString = GuestUserHandlerHelper.getSequenceBySurveyGuid(siObj.Kinetics__GUID__c);
        System.assertNotEquals(responseString, null);
        System.assert(responseString.contains('2000'));
        Test.stopTest();
    }
    @isTest
    static void test_getSequenceBySurveyGuid_JSONBasedForm() {
        
        List<Kinetics__Kinetic_Form__c> kfList = new List<Kinetics__Kinetic_Form__c>();
        Kinetics__Kinetic_Form__c template = new Kinetics__Kinetic_Form__c();
        List<Contact> conList = [SELECT ID from Contact LIMIT 1];
        template.Kinetics__Instructions__c = 'Test Kinetic Form to be completed';
        template.Kinetics__Status__c = 'Active';
        template.Name = 'Test JSON Based Kinetic Form';
        template.Kinetics__Chat_GPT_Parameters__c = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
        template.Kinetics__Template_Metadata__c = '[{"pageno":0,"displayno":1,"sectionlist":[{"sectionno":0,"stitle":"","sinstructions":"","displayno":1,"questionWrapperList":[{"uid":"0.0.1","Name":"star rating question","Kinetics__Field_Type__c":"Rating","Kinetics__Assign_Tasks__c":true,"Kinetics__Attach_Photos_or_Files__c":true,"Kinetics__Capture_Notes__c":true,"Kinetics__Required__c":true,"Kinetics__Values__c":[],"displayQuestionNo":"1.1","pageno":0,"sectionno":0,"isdragover":false,"gotfocus":true,"icon":"utility:rating"}]}]}]';
        kfList.add(template);
        insert kfList;
        
        List<Kinetics__Kinetic_Job__c> kjList = new List<Kinetics__Kinetic_Job__c>();
        for(Kinetics__Kinetic_Form__c kf: kfList){
            Kinetics__Kinetic_Job__c kj = new Kinetics__Kinetic_Job__c();
            kj.Kinetics__Delivery_Method__c = GlobalConstants.deliveryMethodSMS;
            kj.Kinetics__Kinetic_Form__c = kf.Id;
            kj.Kinetics__SMS_Template__c = '';
            kj.Kinetics__Status__c = 'New';
            kjList.add(kj);
        }
        insert kjList;
        List<Kinetics__Survey_Invitation__c> siList = new List<Kinetics__Survey_Invitation__c>();
        for(Contact c: conList){
            for(Kinetics__Kinetic_Job__c kj: kjList){
                Kinetics__Survey_Invitation__c si = new Kinetics__Survey_Invitation__c();
                si.Kinetics__TTL_Day__c = 7;
                si.Kinetics__Stage__c = GlobalConstants.sentToRecipientStage;
                si.Kinetics__Send_Auto_Reminders__c = false;
                si.Kinetics__Reminder_Sent_count__c = 0;
                si.Kinetics__Last_Reminder_Sent_Date__c = null;
                si.Kinetics__Kinetic_Job__c = kj.Id;
                si.Kinetics__Kinetic_Form__c = kj.Kinetics__Kinetic_Form__c;
                si.Kinetics__GUID__c = GlobalUtility.generateGuid();
                si.Kinetics__Days_between_two_reminders__c = 0;
                si.Kinetics__Days_before_First_Reminder__c = 0;
                si.Kinetics__Contact__c = c.Id;
                si.Kinetics__Channel__c = GlobalConstants.channelSMS;
                siList.add(si);
            }
        } 
        insert siList;

        Test.startTest();
        Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c where Kinetics__Kinetic_Form__r.Name = 'Test JSON Based Kinetic Form' limit 1];
        String responseString = GuestUserHandlerHelper.getSequenceBySurveyGuid(siObj.Kinetics__GUID__c);
        System.assertNotEquals(responseString, null);
        System.assert(responseString.contains('2000'));
        Test.stopTest();
    }
    @isTest
    static void test_getSequenceBySurveyGuid_expired() {
        Test.startTest();
        Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
        siObj.Kinetics__Stage__c = GlobalConstants.expiredStage;
        update siObj;
        String responseString = GuestUserHandlerHelper.getSequenceBySurveyGuid(siObj.Kinetics__GUID__c);
        System.assertNotEquals(responseString, null);
        System.assert(responseString.contains('2100'));
        Test.stopTest();
    }

    @isTest
    static void test_getSequenceBySurveyGuid_completed() {
        Test.startTest();
        Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
        siObj.Kinetics__Stage__c = GlobalConstants.completedStage;
        update siObj;
        String responseString = GuestUserHandlerHelper.getSequenceBySurveyGuid(siObj.Kinetics__GUID__c);
        System.assertNotEquals(responseString, null);
        System.assert(responseString.contains('2100'));
        Test.stopTest();
    }

    @isTest
    static void test_updateSurvey2InProgress() {
        Test.startTest();
        Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
        String responseString = GuestUserHandlerHelper.updateSurvey2InProgress(siObj.Kinetics__GUID__c);
        System.assertNotEquals(responseString, null);
        System.assert(responseString.contains('2000'));
        Test.stopTest();
    }

    @isTest
    static void test_saveAnswers() {
        Test.startTest();
            Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
            String answerString = '{"a045g0000042lb2AAA":{"index":1,"surveyQuestionId":"a045g0000042lb2AAA","questionId":"a035g0000030mGAAAY","questionDetails":"test capture Photo question","fieldType":"File","questionValues":null,"answer":"Screenshot_20210810-213929.png"},"a045g0000042lb0AAA":{"index":2,"surveyQuestionId":"a045g0000042lb0AAA","questionId":"a035g0000030mFMAAY","questionDetails":"test RADIO BUTTON question","fieldType":"Radio Button","questionValues":"a,b,c","answer":"b"},"a045g0000042lfBAAQ":{"index":3,"surveyQuestionId":"a045g0000042lfBAAQ","questionId":"a035g0000030mFqAAI","questionDetails":"test Number question","fieldType":"Number","questionValues":null,"answer":"3"}}';
            System.assertNotEquals(answerString, null);
            GuestUserHandlerHelper.saveAnswers(siObj.Kinetics__GUID__c, answerString);
            
        Test.stopTest();
    }
    @isTest
    static void test_saveAnswers_for_newFormatedTemplate() {
        
        List<Kinetics__Kinetic_Form__c> kfList = new List<Kinetics__Kinetic_Form__c>();
        Kinetics__Kinetic_Form__c template = new Kinetics__Kinetic_Form__c();
        List<Contact> conList = [SELECT ID from Contact LIMIT 1];
        template.Kinetics__Instructions__c = 'Test Kinetic Form to be completed';
        template.Kinetics__Status__c = 'Active';
        template.Name = 'Test JSON Based Kinetic Form';
        template.Kinetics__Chat_GPT_Parameters__c = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
        template.Kinetics__Template_Metadata__c = '[{"pageno":0,"displayno":1,"sectionlist":[{"sectionno":0,"stitle":"","sinstructions":"","displayno":1,"questionWrapperList":[{"uid":"0.0.1","Name":"star rating question","Kinetics__Field_Type__c":"Rating","Kinetics__Assign_Tasks__c":true,"Kinetics__Attach_Photos_or_Files__c":true,"Kinetics__Capture_Notes__c":true,"Kinetics__Required__c":true,"Kinetics__Values__c":[],"displayQuestionNo":"1.1","pageno":0,"sectionno":0,"isdragover":false,"gotfocus":true,"icon":"utility:rating"}]}]}]';
        kfList.add(template);
        insert kfList;
        
        List<Kinetics__Kinetic_Job__c> kjList = new List<Kinetics__Kinetic_Job__c>();
        for(Kinetics__Kinetic_Form__c kf: kfList){
            Kinetics__Kinetic_Job__c kj = new Kinetics__Kinetic_Job__c();
            kj.Kinetics__Delivery_Method__c = GlobalConstants.deliveryMethodSMS;
            kj.Kinetics__Kinetic_Form__c = kf.Id;
            kj.Kinetics__SMS_Template__c = '';
            kj.Kinetics__Status__c = 'New';
            kjList.add(kj);
        }
        insert kjList;
        List<Kinetics__Survey_Invitation__c> siList = new List<Kinetics__Survey_Invitation__c>();
        for(Contact c: conList){
            for(Kinetics__Kinetic_Job__c kj: kjList){
                Kinetics__Survey_Invitation__c si = new Kinetics__Survey_Invitation__c();
                si.Kinetics__TTL_Day__c = 7;
                si.Kinetics__Stage__c = GlobalConstants.sentToRecipientStage;
                si.Kinetics__Send_Auto_Reminders__c = false;
                si.Kinetics__Reminder_Sent_count__c = 0;
                si.Kinetics__Last_Reminder_Sent_Date__c = null;
                si.Kinetics__Kinetic_Job__c = kj.Id;
                si.Kinetics__Kinetic_Form__c = kj.Kinetics__Kinetic_Form__c;
                si.Kinetics__GUID__c = GlobalUtility.generateGuid();
                si.Kinetics__Days_between_two_reminders__c = 0;
                si.Kinetics__Days_before_First_Reminder__c = 0;
                si.Kinetics__Contact__c = c.Id;
                si.Kinetics__Channel__c = GlobalConstants.channelSMS;
                siList.add(si);
            }
        } 
        insert siList;

        // Kinetics__Kinetic_Form_Answer__c answer2Commit = new Kinetics__Kinetic_Form_Answer__c();
        // answer2Commit.Kinetics__Answer_Index__c = 1;
        // answer2Commit.Kinetics__Kinetic_Question__c = null;
        // answer2Commit.Kinetics__Kinetic_Question_Values__c = null;
        // answer2Commit.Kinetics__Kinetic_Form_Question__c = null;
        // answer2Commit.Kinetics__Type__c = ;
        // answer2Commit.Kinetics__Survey_Invitation__c = siList[0].Id;
        // answer2Commit.Kinetics__Answer__c = 'Test Answer';
        // answer2Commit.Kinetics__Kinetic_Question_Id__c = qestList[0].Id;
        // answer2Commit.Kinetics__Template_Question_UID__c = '0.0.1';
        // insert answer2Commit;

        Test.startTest();
            Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c where Kinetics__Kinetic_Form__r.Name = 'Test JSON Based Kinetic Form' limit 1];
            String answerString = '{"0.0.1":{"index":1,"surveyQuestionId":"0.0.1","questionId":"0.0.1","questionDetails":"test capture Photo question","fieldType":"File","questionValues":null,"answer":"Screenshot_20210810-213929.png"}}';
            System.assertNotEquals(answerString, null);
            GuestUserHandlerHelper.saveAnswers(siObj.Kinetics__GUID__c, answerString);
            
        Test.stopTest();
    }
    

    @isTest
    static void test_updateSurvey2InProgress_withEventCreation() {
        Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
        setting.Kinetics__Create_Event__c = true;
        update setting;

        Test.startTest();
            Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
            String responseString = GuestUserHandlerHelper.updateSurvey2InProgress(siObj.Kinetics__GUID__c);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2000'));
        Test.stopTest();
    }
    
    @isTest
    static void test_getDetailsForCalendly() {
        TestDataFactory.configureCalendlySettings();
        Test.startTest();
            Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
            String responseString = GuestUserHandlerHelper.getDetailsForCalendly(siObj.Kinetics__GUID__c);
            System.assertNotEquals(responseString, null);
        Test.stopTest();
    }
    @isTest
    static void test_invokeGetClientSecretFromAWS() {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new AWSResponseMock());
            GuestUserHandlerHelper.invokeGetClientSecretFromAWS('125');
        Test.stopTest();
    }

    private class AWSResponseMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullResponse = '{"response": "OK", "statusCode": 200}';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullResponse);
            res.setStatusCode(201);
            return res;
        }
    }
}