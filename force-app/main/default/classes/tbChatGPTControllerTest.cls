/**
 * Author: Shankar Dupade
 * Purpose: Test class for tbChatGPTController
 * Date: 04-05-2023
 */
@isTest
public with sharing class tbChatGPTControllerTest {
    
    @TestSetup
    static void createData() {
        TestDataFactory.configureKineticSetting();
        TestDataFactory.configureGPTSetting();
        List<Account> accList = TestDataFactory.createAccount();
        List<Contact> conList = TestDataFactory.createContact(accList);
        List<Kinetics__Kinetic_Question__c> qestList = TestDataFactory.createQuestion();
        List<Kinetics__Kinetic_Form__c> kfList = TestDataFactory.createKineticForm();
        List<Kinetics__Kinetic_Form_Question__c> kfqList = TestDataFactory.createKineticFormQuestion(qestList, kfList);

        List<Kinetics__Kinetic_Job__c> kjList = TestDataFactory.createKineticJob(kfList);
        List<Kinetics__Survey_Invitation__c> siList = TestDataFactory.createSurveyInvitation(conList, kjList);
        List<Kinetics__Kinetic_Form_Answer__c> ansList = TestDataFactory.createAnswers(siList, kfqList, qestList);

        Kinetics__Kinetic_Form__c template = new Kinetics__Kinetic_Form__c();
        template.Kinetics__Chat_GPT_Parameters__c = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
        template.Kinetics__Template_Metadata__c = '[{"pageno":0,"displayno":1,"sectionlist":[{"sectionno":0,"stitle":"","sinstructions":"","displayno":1,"questionWrapperList":[{"uid":"0.0.1","Name":"star rating question","Kinetics__Field_Type__c":"Rating","Kinetics__Assign_Tasks__c":true,"Kinetics__Attach_Photos_or_Files__c":true,"Kinetics__Capture_Notes__c":true,"Kinetics__Required__c":true,"Kinetics__Values__c":[],"displayQuestionNo":"1.1","pageno":0,"sectionno":0,"isdragover":false,"gotfocus":true,"icon":"utility:rating"}]}]}]';
        template.Name = 'Test star ratomg questions';
        template.Kinetics__Status__c = 'Active';
        insert template;

        Kinetics__Inspection__c insp = new Kinetics__Inspection__c();
        insp.Kinetics__Template__c = template.Id;
        insp.Kinetics__Contact__c = conList[0].Id;
        insp.Kinetics__Account__c = accList[0].Id;
        insert insp;

        Kinetics__Kinetic_Form_Answer__c kfa = new Kinetics__Kinetic_Form_Answer__c();
        kfa.Kinetics__Answer__c = 'b';
        kfa.Kinetics__Answer_Index__c = 1;
        kfa.Kinetics__Attachment__c = false;
        kfa.Kinetics__has_Multiple_Attachments__c = false;
        kfa.Kinetics__Is_Uploaded_Image__c = false;
        kfa.Kinetics__Kinetic_Form_Question__c = null;
        kfa.Kinetics__Kinetic_Question__c = null;
        kfa.Kinetics__Kinetic_Question_Values__c = 'a,b,c';
        kfa.Inspection__c = insp.Id;
        kfa.Kinetics__Template_Question_UID__c = '0.0.1';
        kfa.Kinetics__Type__c = 'Radio Button';
        kfa.Kinetics__AI_Guidance__c = 'test value';
        insert kfa;    
    }

    @isTest
    static void test_invokeGeneratChecklistModel() {
        String gptParameters = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
        Test.setMock(HttpCalloutMock.class, new GPTMock());
        Test.startTest();
            System.assertNotEquals(gptParameters, null);
            String response = tbChatGPTController.invokeGeneratChecklistModel(gptParameters);
            System.assertNotEquals(response, null);
        Test.stopTest();
    }
    @isTest
    static void test_invokeGeneratChecklistModel_withoutyourrole() {
        String gptParameters = '{"checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
        Test.setMock(HttpCalloutMock.class, new GPTMock());
        Test.startTest();
            System.assertNotEquals(gptParameters, null);
            String response = tbChatGPTController.invokeGeneratChecklistModel(gptParameters);
            System.assertNotEquals(response, null);
        Test.stopTest();
    }

    
    @isTest
    static void test_constructGenerateSummaryRequestPayload() {
        String gptParameters = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new GPTMock());
        Test.startTest();
            System.assertNotEquals(gptParameters, null);
            String response = tbChatGPTController.constructGenerateSummaryRequestPayload(insp.Id, gptParameters);
            System.assertNotEquals(response, null);
        Test.stopTest();
    }
    @isTest
    static void test_createGPTJob() {
        String gptParameters = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new GPTMock());
        Test.startTest();
            System.assertNotEquals(gptParameters, null);
            String response = tbChatGPTController.createGPTJob(insp.Id, gptParameters);
            System.assertNotEquals(response, null);
        Test.stopTest();
    }


    @isTest
    static void test_createNotesTasks() {
        String gptParameters = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new GPTMock());
        Test.startTest();
            System.assertNotEquals(gptParameters, null);
            String response = tbChatGPTController.createGPTJob(insp.Id, gptParameters);
            System.assertNotEquals(response, null);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
            
            Object jobObj = responseMap.get('responseDetails');
            Map<String, Object> jobMap = (Map<String, Object>) jobObj;
            tbChatGPTController.createNotesTasks(new List<Id>{(String)jobMap.get('Id')});
        Test.stopTest();
    }
    
    @isTest
    static void test_getGPTParameters() {
        String gptParameters = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new GPTMock());
        Test.startTest();
            System.assertNotEquals(gptParameters, null);
            String response = tbChatGPTController.getGPTParameters(insp.Id);
            System.assertNotEquals(response, null);
        Test.stopTest();
    }

    // @isTest
    // static void test_createRecords() {
    //     String gptParameters = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
    //     String noteString = 'This is test note record';
    //     Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];

    //     List<Task> taskList = new List<Task>();
    //     Task taskRecord = new Task();
    //     taskRecord.Subject = '\uD83D\uDE80 ' + 'title';
    //     taskRecord.ActivityDate = Date.today();
    //     taskRecord.Status = 'Not Started';
    //     taskRecord.Priority = 'High';
    //     taskRecord.WhatId = insp.Id;
    //     taskRecord.Description = 'Text task record description';
    //     taskRecord.OwnerId = UserInfo.getUserId();
    //     taskList.add(taskRecord);

    //     Test.setMock(HttpCalloutMock.class, new GPTMock());
    //     Test.startTest();
    //         System.assertNotEquals(gptParameters, null);
    //         String response = tbChatGPTController.createRecords(noteString, JSON.serialize(taskList), insp.Id);
    //         System.assertNotEquals(response, null);
    //     Test.stopTest();
    // }

    @isTest
    static void test_transcribeAudio() {
       
        Test.startTest();
            String response = tbChatGPTController.transcribeAudio('dummycontentVersionId', 'dummyInspectionid');
            System.assertNotEquals(response, null);
        Test.stopTest();
    }
    @isTest
    static void test_createAudioFile() {
       
        Test.startTest();
            String response = tbChatGPTController.createAudioFile('test audio date','dummyfilename', 'dummyInspectionid');
            System.assertNotEquals(response, null);
        Test.stopTest();
    }
    @isTest
    static void test_getRelatedAnswersForInspection() {
        Kinetics__Inspection__c insp = [SELECT Id from Kinetics__Inspection__c limit 1];
        Test.startTest();
            String response = tbChatGPTController.getRelatedAnswersForInspection(insp.Id);
            System.assertNotEquals(response, null);
        Test.stopTest();
    }
    
    private class GPTMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullResponse = '{{"Summary": "test summary"}, {"title": "abc title"}}';
           
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullResponse);
            res.setStatusCode(200);
            return res;
        }
    }
}