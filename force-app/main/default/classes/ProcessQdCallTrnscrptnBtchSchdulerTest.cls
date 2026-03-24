/**
 * Author: Shankar Dupade (FieldKo)
 * Purpose: Test class for controller class which is used for ProcessQdCallTrnscrptnBtchSchduler
 * Date: 11 Mar 2024
 */

@isTest
public with sharing class ProcessQdCallTrnscrptnBtchSchdulerTest {
     static String responseString = '{}';
 
     @TestSetup
     static void createData(){
         TestDataFactory.configureKineticSetting();
         List<Account> accList = TestDataFactory.createAccount();
         TestDataFactory.createContact(accList);
 
         TestDataFactory.configureGPTSetting();
         Test.setMock(HttpCalloutMock.class, new OpenAIAssistantMock());
         Kinetics__Assistant__c asst = new Kinetics__Assistant__c();
         asst.Kinetics__ChatGPT_Id__c = 'asst_asdasf';
         asst.Kinetics__File_Ids__c = '[]';
         asst.Kinetics__Instructions__c = 'test assistant instruction';
         asst.Kinetics__Model__c = 'gpt-4';
         asst.Name = 'test assistant';
         asst.Kinetics__Retrieval__c = true;
         asst.Kinetics__Code_Interpreter__c = true;
         insert asst;
 
         Kinetics__Spreadsheet_Configuration__c sc = new Kinetics__Spreadsheet_Configuration__c();
         sc.Kinetics__Row_Metadata__c = '[{"columnWrapperList":[{"label":"Name","fieldName":"Name","uid":0,"type":"Text","wrapText":true,"editable":true},{"label":"Active","fieldName":"Kinetics__Active__c","uid":1,"type":"Text","wrapText":true,"editable":true},{"label":"Other stuff","fieldName":"Kinetics__SLASerialNumber__c","uid":2,"type":"Text","wrapText":true,"editable":true}],"rowno":0}]';
         sc.Name = 'Test';
         sc.Kinetics__Object_API_Name__c = 'Account';
         sc.Kinetics__Instructions__c = 'some instructions here';
         insert sc;
         
         List<Kinetics__Kinetic_Form__c> kfList = new List<Kinetics__Kinetic_Form__c>();
         Kinetics__Kinetic_Form__c template = new Kinetics__Kinetic_Form__c();
         template.Kinetics__Instructions__c = 'Test Kinetic Form to be completed';
         template.Kinetics__Status__c = 'Active';
         template.Name = 'Test JSON Based Kinetic Form';
         template.Kinetics__Chat_GPT_Parameters__c = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
         template.Kinetics__Template_Metadata__c = '[{"pageno":0,"displayno":1,"sectionlist":[{"sectionno":0,"stitle":"","sinstructions":"","displayno":1,"questionWrapperList":[{"uid":"0.0.1","Name":"star rating question","Kinetics__Field_Type__c":"Rating","Kinetics__Assign_Tasks__c":true,"Kinetics__Attach_Photos_or_Files__c":true,"Kinetics__Capture_Notes__c":true,"Kinetics__Required__c":true,"Kinetics__Values__c":[],"displayQuestionNo":"1.1","pageno":0,"sectionno":0,"isdragover":false,"gotfocus":true,"icon":"utility:rating"}]}]}]';
         template.Kinetics__Spreadsheet_Template__c = sc.Id;
         template.Kinetics__Assistant__c = asst.Id;
         kfList.add(template);
         insert kfList;
 
         Kinetics__Meeting__c meeting = new Kinetics__Meeting__c();
         meeting.Kinetics__GPT_Thread_ID__c = 'thread_asdascx';
         meeting.Kinetics__Transcript_RTF__c = 'test transcript message';
         meeting.Kinetics__Prompt_Template__c = kfList[0].Id;
         meeting.Kinetics__GPT_Thread_Run_Job_Status__c = 'queued';
         meeting.Kinetics__GPT_Assistant_ID__c = 'asst_asdasfas';
         insert meeting;
     }
 
     @IsTest
     static void test_scheduleEvery5Mins(){
        Test.setMock(HttpCalloutMock.class, new OpenAIAssistantMock());
        Test.startTest();
            ProcessQdCallTranscriptionBatchScheduler ssbs = new ProcessQdCallTranscriptionBatchScheduler();
            ssbs.setBatchSize(1);
            // String sch = '0 0 23 * * ?'; 
            // System.assertNotEquals(null, ssbs);
            // System.schedule('Test Batch Schedule', sch, ssbs); 
            ssbs.scheduleEvery5Mins();
        Test.stopTest();
     }
     private class OpenAIAssistantMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullResponse = ProcessQdCallTrnscrptnBtchSchdulerTest.responseString; 
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullResponse);
            res.setStatusCode(201);
            return res;
        }
    }
 }