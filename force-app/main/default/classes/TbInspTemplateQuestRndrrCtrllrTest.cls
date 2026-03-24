/**
 * Author: Shankar Dupade
 * Purpose: Test class for TbInspTemplateQuestionRendererController
 * Date: 04-05-2023
 */
@isTest
public with sharing class TbInspTemplateQuestRndrrCtrllrTest {
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

        Task t = new Task();
        t.subject = 'test';
        insert t;

        ContentNote cn = new ContentNote();
        cn.Title = 'Note title';
        cn.Content = Blob.valueOf('This is test Note description');
        insert cn;

    }

    @isTest
    static void test_getInspectionDetails() {
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Test.startTest();
            System.assertNotEquals(insp, null);
            String response = TbInspTemplateQuestionRendererController.getInspectionDetails(insp.Id);
            System.assertNotEquals(response, null);
        Test.stopTest();
    }

     
    @isTest
    static void test_createAnswersForJSONBasedTemplate() {
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Kinetics__Kinetic_Form__c f = [SELECT Id, Kinetics__Template_Metadata__c FROM Kinetics__Kinetic_Form__c LIMIT 1];
        String templateMetadata = '[{"pageno":0,"displayno":1,"sectionlist":[{"sectionno":0,"stitle":"","sinstructions":"","displayno":1,"questionWrapperList":[{"uid":"0.0.1","Name":"star rating question","Kinetics__Field_Type__c":"Rating","Kinetics__Assign_Tasks__c":true,"Kinetics__Attach_Photos_or_Files__c":true,"Kinetics__Capture_Notes__c":true,"Kinetics__Required__c":true,"Kinetics__Values__c":[],"displayQuestionNo":"1.1","pageno":0,"sectionno":0,"isdragover":false,"gotfocus":true,"icon":"utility:rating"}]}]}]';
        Test.startTest();
            System.assertNotEquals(insp, null);
            TbInspTemplateQuestionRendererController.createAnswersForJSONBasedTemplate(insp.Id, templateMetadata);
        Test.stopTest();
    }

    @isTest
    static void test_SaveAnswers() {
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Kinetics__Kinetic_Form__c f = [SELECT Id, Kinetics__Template_Metadata__c FROM Kinetics__Kinetic_Form__c LIMIT 1];
        String templateMetadata = '[{"pageno":0,"displayno":1,"sectionlist":[{"sectionno":0,"stitle":"","sinstructions":"","displayno":1,"questionWrapperList":[{"uid":"0.0.1","Name":"star rating question","Kinetics__Field_Type__c":"Rating","Kinetics__Assign_Tasks__c":true,"Kinetics__Attach_Photos_or_Files__c":true,"Kinetics__Capture_Notes__c":true,"Kinetics__Required__c":true,"Kinetics__Values__c":[],"displayQuestionNo":"1.1","pageno":0,"sectionno":0,"isdragover":false,"gotfocus":true,"icon":"utility:rating"}]}]}]';
        Kinetics__Kinetic_Form_Answer__c kfa = [SELECT ID FROM Kinetics__Kinetic_Form_Answer__c LIMIT 1];
        TbInspTemplateQuestionRendererController.inspTemplateAnswer tanswerObj = new TbInspTemplateQuestionRendererController.inspTemplateAnswer();
        Map<String, TbInspTemplateQuestionRendererController.inspTemplateAnswer> answersObj = new Map<String, TbInspTemplateQuestionRendererController.inspTemplateAnswer>();
        tanswerObj.index = '1';
        tanswerObj.questionId = '0.0.1';
        tanswerObj.templateQuestionId = '0.0.1';
        tanswerObj.answer = 'test answer';
        tanswerObj.questionDetails = 'test question';
        tanswerObj.fieldType = 'Text';
        tanswerObj.questionValues = '';
        tanswerObj.inspectionId = insp.Id;
        tanswerObj.inspectionTemplateId = null;
        tanswerObj.templateId = null;
        tanswerObj.existingAnswerId = kfa.Id;
        tanswerObj.scoreAttained = 10;
        tanswerObj.outOfScore = 30;
        tanswerObj.chatgptguidance =  'text guidence text';
        answersObj.put('0.0.1',tanswerObj);
        Task t = [SELECT Id from Task LIMIT 1];
        Test.startTest();
            System.assertNotEquals(insp, null);
            TbInspTemplateQuestionRendererController.saveAnswers(JSON.serialize(answersObj));
            Map<String, String> answerIdMap = new  Map<String, String>();
            answerIdMap.put('0.0.1', kfa.Id);
            Map<String, List<String>> taskIdListByTemplateId = new Map<String, List<String>>();
            taskIdListByTemplateId.put('0.0.1', new List<String>{String.valueOf(t.Id)});
            TbInspTemplateQuestionRendererController.linkAnswerToTasks(JSON.serialize(answerIdMap), JSON.serialize(taskIdListByTemplateId));

            ContentNote cn = [SELECT Id from ContentNote LIMIT 1];
            Map<String, List<String>> noteIdListByTemplateId = new Map<String, List<String>>();
            noteIdListByTemplateId.put('0.0.1', new List<String>{String.valueOf(cn.Id)});
            TbInspTemplateQuestionRendererController.linkAnswerToNotes(JSON.serialize(answerIdMap), JSON.serialize(noteIdListByTemplateId));
        Test.stopTest();
    }

    @isTest
    static void test_updateStatusToInprogress() {
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Kinetics__Kinetic_Form__c f = [SELECT Id, Kinetics__Template_Metadata__c FROM Kinetics__Kinetic_Form__c LIMIT 1];
        Test.startTest();
            System.assertNotEquals(insp, null);
            String response = TbInspTemplateQuestionRendererController.updateStatusToInprogress(insp.Id);
            System.assertNotEquals(response, null);
        Test.stopTest();
    }
    @isTest
    static void test_getRelatedFieldInformation() {
        Kinetics__Inspection__c insp = [SELECT Id FROM Inspection__c LIMIT 1];
        Kinetics__Kinetic_Form__c f = [SELECT Id, Kinetics__Template_Metadata__c FROM Kinetics__Kinetic_Form__c LIMIT 1];
        Map<String, String> requiredInformationMap = new Map<String, String>();
        requiredInformationMap.put('relatedObjectName', 'Account');
        requiredInformationMap.put('relatedObjectFieldName', 'Name');
        requiredInformationMap.put('inspectionRecId', insp.Id);
        Test.startTest();
            System.assertNotEquals(insp, null);
            String response = TbInspTemplateQuestionRendererController.getRelatedFieldInformation(JSON.serialize(requiredInformationMap));
            System.assertNotEquals(response, null);
        Test.stopTest();
    }
    
    
}