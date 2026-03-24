/**
 * Author: Shankar Dupade
 * Purpose: Test class for InspSpreadsheetController
 * Date: 29-12-2023
 */
@isTest
public with sharing class InspSpreadsheetControllerTest {
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

        Kinetics__Spreadsheet_Configuration__c sc = new Kinetics__Spreadsheet_Configuration__c();
        sc.Kinetics__Row_Metadata__c = '[{"columnWrapperList":[{"label":"Name","fieldName":"Name","uid":0,"type":"Text","wrapText":true,"editable":true},{"label":"Active","fieldName":"Kinetics__Active__c","uid":1,"type":"Text","wrapText":true,"editable":true},{"label":"Other stuff","fieldName":"Kinetics__SLASerialNumber__c","uid":2,"type":"Text","wrapText":true,"editable":true}],"rowno":0}]';
        sc.Name = 'Test';
        sc.Kinetics__Object_API_Name__c = 'Account';
        sc.Kinetics__Instructions__c = 'some instructions here';
        insert sc;

        Kinetics__Inspection__c insp = new Kinetics__Inspection__c();
        insp.Kinetics__Template__c = template.Id;
        insp.Kinetics__Contact__c = conList[0].Id;
        insp.Kinetics__Account__c = accList[0].Id;
        insp.Kinetics__Spreadsheet_Configuration__c = sc.Id;
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

        Task t = new Task();
        t.subject = 'test';
        insert t;

        ContentNote cn = new ContentNote();
        cn.Title = 'Note title';
        cn.Content = Blob.valueOf('This is test Note description');
        insert cn;

    }

    @isTest
    static void test_getHeader() {
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Test.startTest();
            System.assertNotEquals(insp, null);
            String response = InspSpreadsheetController.getHeader(insp.Id);
            System.assertNotEquals(response, null);
        Test.stopTest();
    }

    @isTest
    static void test_createCustomObjectRecord() {
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Test.startTest();
            System.assertNotEquals(insp, null);
            List<Map<String, String>> newRecordList = new List<Map<String, String>>();
            Map<String, String> record = new Map<String, String>();
            record.put('Name', 'test record');
            record.put('Kinetics__Active__c', 'Active');
            record.put('Kinetics__SLASerialNumber__c', 'asda');
            newRecordList.add(record);

            String response = InspSpreadsheetController.createCustomObjectRecord(insp.Id, JSON.serialize(newRecordList), JSON.serialize(new List<Map<String, String>>()));
            System.assertNotEquals(response, null);
        Test.stopTest();
    }
    @isTest
    static void test_getSpreadsheetData() {
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Test.startTest();
            System.assertNotEquals(insp, null);
            String response = InspSpreadsheetController.getSpreadsheetData();
            System.assertNotEquals(response, null);
        Test.stopTest();
    }

    
}