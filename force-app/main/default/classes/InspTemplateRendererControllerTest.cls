/**
 * Auther: Shankar Dupade
 * Purpose: test classes for InspTemplateRendererController
 * Date: 11-10-2022
 */
@isTest
public with sharing class InspTemplateRendererControllerTest {
    @TestSetup
    static void createData(){
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();

        List<Contact> conList = TestDataFactory.createContact(accList);
        List<Kinetics__Kinetic_Question__c> qestList = TestDataFactory.createQuestion();
        qestList.addAll(TestDataFactory.createQuestion());
        qestList.addAll(TestDataFactory.createQuestionForRelatedObject());
        List<Kinetics__Kinetic_Form__c> kfList = TestDataFactory.createKineticForm();
        for(Kinetics__Kinetic_Form__c kf: kfList ) {
            kf.Kinetics__Section_Metadata__c = '{"1":{"title":"Pest Management","questIndex":[1]}}';
            kf.Kinetics__Questions_By_Page_No__c = '{"1":[1]}';
        }
        update kfList;

        List<Kinetics__Kinetic_Form_Question__c> kfqList = TestDataFactory.createKineticFormQuestion(qestList, kfList);
        for(Kinetics__Kinetic_Form_Question__c kfq: kfqList) {
            kfq.Kinetics__Option_Score__c = '{"Yes":5,"No":0}';
        }
        update kfqList;

        List<Kinetics__Kinetic_Job__c> kjList = TestDataFactory.createKineticJob(kfList);
        List<Kinetics__Survey_Invitation__c> siList = TestDataFactory.createSurveyInvitation(conList, kjList);

        Kinetics__Inspection__c inspe = new Kinetics__Inspection__c();
        inspe.Kinetics__Account__c = accList[0].Id;
        inspe.Kinetics__Contact__c = conList[0].Id;
        inspe.Kinetics__Inspection_Date__c = Date.today();
        inspe.Kinetics__Status__c = 'Not Started';
        inspe.Kinetics__Template__c = kfList[0].Id;
        insert inspe;
        
        Kinetics__Kinetic_Form_Answer__c answer2Commit = new Kinetics__Kinetic_Form_Answer__c();
        answer2Commit.Kinetics__Answer_Index__c = 1;
        answer2Commit.Kinetics__Kinetic_Question__c = qestList[0].Kinetics__Question__c;
        answer2Commit.Kinetics__Kinetic_Question_Values__c = qestList[0].Kinetics__Values__c;
        answer2Commit.Kinetics__Kinetic_Form_Question__c = kfqList[0].Id;
        answer2Commit.Kinetics__Type__c = qestList[0].Kinetics__Field_Type__c;
        answer2Commit.Kinetics__Survey_Invitation__c = siList[0].Id;
        answer2Commit.Kinetics__Answer__c = 'Test Answer';
        answer2Commit.Kinetics__Kinetic_Question_Id__c = qestList[0].Id;
        answer2Commit.Kinetics__Inspection__c = inspe.Id;
        insert answer2Commit;

        TestDataFactory.createFileAttached(answer2Commit.Id, 'Test method running file');
    }

    @isTest
    static void getAllTemplatesDetailsByInspectionId_test() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        Test.startTest();
            System.assertNotEquals(inspList.size(), 0);
            String response = InspTemplateRendererController.getAllTemplatesDetailsByInspectionId(inspList[0].Id);
            System.assertNotEquals(response, null);
            String nullResponse = InspTemplateRendererController.getAllTemplatesDetailsByInspectionId('');
            System.assertNotEquals(nullResponse, null);
        Test.stopTest();       
    }
    @isTest
    static void updateInspectionToInprogress_Test() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        Test.startTest();
            System.assertNotEquals(inspList.size(), 0);
            String response = InspTemplateRendererController.updateInspectionToInprogress(inspList[0].Id);
            System.assertNotEquals(response, null);
            String nullResponse = InspTemplateRendererController.updateInspectionToInprogress('');
            System.assertNotEquals(nullResponse, null);
        Test.stopTest();       
    }
    @isTest
    static void getAllTemplateDetailsByInspectionId_Test() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        Test.startTest();
            System.assertNotEquals(inspList.size(), 0);
            String response = InspTemplateRendererController.getAllTemplateDetailsByInspectionId(inspList[0].Id, true);
            System.assertNotEquals(response, null);
            String nullResponse = InspTemplateRendererController.getAllTemplateDetailsByInspectionId('', true);
            System.assertNotEquals(nullResponse, null);
        Test.stopTest();       
    }
   
    @isTest
    static void createAnswer_Test() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        Test.startTest();
            System.assertNotEquals(inspList.size(), 0);
            InspTemplateRendererController.createAnswer(new List<Id>{inspList[0].Id});
            InspTemplateRendererController.createAnswer(new List<Id>());
        Test.stopTest(); 
    }    

    @isTest
    static void saveAnswers_Test() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        Kinetics__Kinetic_Form_Answer__c answer2Commit = [SELECT Id, Name, Kinetics__Inspection__c, Kinetics__Kinetic_Question_Id__c, Kinetics__Answer__c, Kinetics__Survey_Invitation__c, Kinetics__Type__c, Kinetics__Kinetic_Form_Question__c, Kinetics__Kinetic_Question_Values__c, Kinetics__Kinetic_Question__c, Kinetics__Answer_Index__c FROM Kinetics__Kinetic_Form_Answer__c LIMIT 1];
       
        String answerString = '{"'+answer2Commit.Kinetics__Kinetic_Form_Question__c+'":{"index":1,"templateQuestionId":"'+answer2Commit.Kinetics__Kinetic_Form_Question__c+'","questionId":"'+answer2Commit.Kinetics__Kinetic_Question_Id__c+'","questionDetails":"What is the Make/Model of Cash Drawer?","fieldType":"Radio Button","questionValues":"Micros, Aures, PAR","inspectionId":"'+inspList[0].Id+'","existingAnswerId":"'+answer2Commit.Id+'","answer":"Micros","scoreAttained":6,"outOfScore":6}}';
        System.assertNotEquals(answerString, null);
        Test.startTest();
            System.assertNotEquals(inspList.size(), 0);
            InspTemplateRendererController.saveAnswers(answerString);
        Test.stopTest(); 
    }   
    
    @isTest
    static void test_saveTheChunkFile() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        List<Kinetics__Kinetic_Form_Answer__c> kfAnswerList = [Select ID from Kinetics__Kinetic_Form_Answer__c];

        Test.startTest();
            Id parentId = inspList[0].Id;
            String surveyAnswerId = kfAnswerList[0].Id;
            String fileName = 'Test file image.png';
            String base64Data = Blob.valueOf('Test image content').toString();
            String contentType = 'image/png';
            String fileId = null;
            fileId = InspTemplateRendererController.saveTheChunkFile(parentId, surveyAnswerId, fileName, base64Data, contentType, fileId);
            System.assertNotEquals(fileId, null);
        Test.stopTest();
    }

    @isTest
    static void test_saveTheChunkFile_withAppend() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        List<Kinetics__Kinetic_Form_Answer__c> kfAnswerList = [Select ID from Kinetics__Kinetic_Form_Answer__c];
        Test.startTest();
            Id parentId = inspList[0].Id;
            String surveyAnswerId =  kfAnswerList[0].Id;
            String fileName = 'Test file image.png';
            String base64Data = Blob.valueOf('Test image content').toString();
            String contentType = 'image/png';
            String fileId = null;
            fileId = InspTemplateRendererController.saveTheChunkFile(parentId, surveyAnswerId, fileName, base64Data, contentType, fileId);
            base64Data = ' some more additions to the data';
            fileId = InspTemplateRendererController.saveTheChunkFile(parentId, surveyAnswerId, fileName, base64Data, contentType, fileId);
            System.assertNotEquals(fileId, null);
        Test.stopTest();
    }
    @isTest
    static void createTaskRecord_Test() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        String taskRecordString = '[{"Subject":"test scoring setting","Status":"Not Started","Priority":"Normal","WhatId":"'+inspList[0].Id+'","Description":"Does this KDS has Bumpbar?","OwnerId":"'+UserInfo.getUserId()+'","Type":"Other"}]';
        System.assertNotEquals(taskRecordString, null);
        Test.startTest();
            System.assertNotEquals(inspList.size(), 0);
            InspTemplateRendererController.createTaskRecord(taskRecordString);
        Test.stopTest(); 
    }  

    @isTest
    static void shareNoteRecord_Test() {
        String content = 'Hello';
        ContentNote note = new ContentNote(
            Title = 'Test',
            Content = Blob.valueOf(content)
        );
        insert note;

        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        List<Kinetics__Kinetic_Form_Answer__c> answerList = [SELECT Id From Kinetics__Kinetic_Form_Answer__c];
        Map<String, List<String>> shareWithIdListByNoteId = new Map<String, List<String>>();
        shareWithIdListByNoteId.put(note.Id, new List<String>{inspList[0].Id, answerList[0].Id});
        Test.startTest();
            System.assertNotEquals(shareWithIdListByNoteId.size(), 0);
            InspTemplateRendererController.shareNoteRecord(shareWithIdListByNoteId);
        Test.stopTest(); 
    }  
    @isTest
    static void updateTaskRecord_test() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        List<Kinetics__Kinetic_Form_Answer__c> answerList = [SELECT Id from Kinetics__Kinetic_Form_Answer__c];
        String taskRecordString = '[{"Subject":"test scoring setting","Status":"Not Started","Priority":"Normal","WhatId":"'+inspList[0].Id+'","Description":"Does this KDS has Bumpbar?","OwnerId":"'+UserInfo.getUserId()+'","Type":"Other"}]';
        System.assertNotEquals(taskRecordString, null);
        Test.startTest();
            System.assertNotEquals(inspList.size(), 0);
            String taskRecordResponse = InspTemplateRendererController.createTaskRecord(taskRecordString);
            List<Task> tlist = (List<Task>) JSON.deserialize(taskRecordResponse, List<Task>.class);
            Map<String,List<String>> tasksRecordIdListByAnswerId = new Map<String, List<String>>();
            tasksRecordIdListByAnswerId.put(answerList[0].Id, new List<String>{tlist[0].Id});
            InspTemplateRendererController.updateTaskRecord(tasksRecordIdListByAnswerId);
        Test.stopTest(); 
    }  
    
    @isTest
    static void collectInformationAboutParentRecords_test() {
        Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
        setting.Kinetics__Field_Name_for_Lookup__c = 'OwnerId';
        upsert setting;
        List<String> qidList = new List<String>();
        for(Kinetics__Kinetic_Question__c kd: [SELECT Id FROM Kinetics__Kinetic_Question__c ]) {
            qidList.add(kd.Id);
        }
        Test.startTest();
            InspTemplateRendererController.collectInformationAboutParentRecords(qidList);
        Test.stopTest();


    }
}