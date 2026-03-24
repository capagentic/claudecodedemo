/**
 * Auther: Shankar Dupade
 * Purpose: test classes for GPTCallTranscriptionHelper
 * Date: 07-Mar-2024
 */
@isTest
public with sharing class GPTCallTranscriptionHelperTest {
    @TestSetup
    static void createData(){
        TestDataFactory.configureGPTSetting();
        Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
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
        kfList.add(template);
        insert kfList;

        Kinetics__Meeting__c meeting = new Kinetics__Meeting__c();
        meeting.Kinetics__GPT_Thread_ID__c = 'thread_asdascx';
        meeting.Kinetics__Transcript_RTF__c = 'test transcript message';
        meeting.Kinetics__Prompt_Template__c = kfList[0].Id;

        insert meeting;
    }

    @isTest
    static void create_update_Assistance_test() {
        Kinetics__Assistant__c ast = [SELECT Id FROM Kinetics__Assistant__c];
        List<String> astList = new List<String>();
        astList.add(ast.Id);
        System.assertNotEquals(astList.size(), 0);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
            GPTCallTranscriptionHelper.create_update_Assistance(astList);
        Test.stopTest();
    }
    @isTest
    static void testdelete_Assistance() {
                  
        List<String> gptIdList = new List<String>{'asst_UruYGBBr1MIhLvhRkMssr44c'};
        System.assertNotEquals(gptIdList, null);
        Test.setMock(HttpCalloutMock.class, new GPTCallTranscription_delete_RestMock());
        Test.startTest();
            GPTCallTranscriptionHelper.delete_Assistance(gptIdList);
        Test.stopTest();
    }

    @isTest
    static void testCreate_update_Thread() {
                  
        List<Kinetics__Meeting__c> meetingList = [SELECT Id FROM Kinetics__Meeting__c];

        Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
        Test.startTest();
            String parsedResponse = GPTCallTranscriptionHelper.create_update_Thread('asst_asdasdas', 'thread_asdasdas', meetingList[0].Id);
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }

    @isTest
    static void testCreate_update_Message() {
        List<Kinetics__Meeting__c> meetingList = [SELECT Id,Kinetics__Prompt_Template__c FROM Kinetics__Meeting__c];

        Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
        Test.startTest();
            String parsedResponse = GPTCallTranscriptionHelper.create_update_Message('asst_asdasdv', 'thread_asdad', meetingList[0].Id,meetingList[0].Kinetics__Prompt_Template__c);
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }
    @isTest
    static void testCreate_update_Message_For_a005g00003NSX2PAAX() {
        List<Kinetics__Meeting__c> meetingList = [SELECT Id,Kinetics__Prompt_Template__c FROM Kinetics__Meeting__c];

        Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
        Test.startTest();
            String parsedResponse = GPTCallTranscriptionHelper.create_update_Message('asst_asdasdv', 'thread_asdad', meetingList[0].Id,meetingList[0].Kinetics__Prompt_Template__c);
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }
    
    @isTest
    static void testCreate_Run() {

        Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
        Test.startTest();
            String parsedResponse = GPTCallTranscriptionHelper.create_Run('asst_asdasas', 'thread_asdasdas');
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }
    @isTest
    static void testCreate_Run_negative_without_assistant() {

        Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
        Test.startTest();
            try{
                String parsedResponse = GPTCallTranscriptionHelper.create_Run(null, 'thread_asdasdas');
                System.assertNotEquals(parsedResponse, null);
            }catch(Exception exc) {
                System.assertNotEquals(exc.getMessage(), null);
            }
        Test.stopTest();
    }

    @isTest
    static void testCreate_Run_negative_without_thread() {

        Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
        Test.startTest();
            try{
                String parsedResponse = GPTCallTranscriptionHelper.create_Run('asst_asdad', null);
                System.assertNotEquals(parsedResponse, null);
            }catch(Exception exc) {
                System.assertNotEquals(exc.getMessage(), null);
            }
        Test.stopTest();
    }
    
    @isTest
    static void testRetriveAllMessagesForThread() {

        Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
        Test.startTest();
            String parsedResponse = GPTCallTranscriptionHelper.retriveAllMessagesForThread('thread_asdasdas');
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }
    
    @isTest
    static void testGetAllAvailableAssistants() {
                  
        Test.setMock(HttpCalloutMock.class, new GPTCallTranscriptionRestMock());
        Test.startTest();
            String parsedResponse = GPTCallTranscriptionHelper.getAllAvailableAssistants();
            System.assertNotEquals(parsedResponse, null);
        Test.stopTest();
    }
    private class GPTCallTranscriptionRestMock implements HttpCalloutMock {

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
    private class GPTCallTranscription_delete_RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '{"id": "asst_UruYGBBr1MIhLvhRkMssr44c","object": "assistant.deleted","deleted": true}';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
}