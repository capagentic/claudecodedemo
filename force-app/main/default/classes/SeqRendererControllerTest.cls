/**
* Author: Shankar Dupade(FieldKo)
* Updated : 11th Aug 2021
* Purpose: Test Class for seq Renderer controller
*/
@isTest
public with sharing class SeqRendererControllerTest {
    
    @TestSetup
    static void createData(){
        TestDataFactory.configureKineticSetting();
        List<Account> accList = TestDataFactory.createAccount();
        List<Contact> conList = TestDataFactory.createContact(accList);
        List<Kinetics__Kinetic_Question__c> qestList = TestDataFactory.createQuestion();
        List<Kinetics__Kinetic_Form__c> kfList = TestDataFactory.createKineticForm();
        List<Kinetics__Kinetic_Form_Question__c> kfqList = TestDataFactory.createKineticFormQuestion(qestList, kfList);

        List<Kinetics__Kinetic_Job__c> kjList = TestDataFactory.createKineticJob(kfList);
        List<Kinetics__Survey_Invitation__c> siList = TestDataFactory.createSurveyInvitation(conList, kjList);

    }

    @IsTest
    static void test_getSequenceById(){
        
        Test.startTest();
            Kinetics__Kinetic_Form__c kf = [select Id from Kinetics__Kinetic_Form__c limit 1];
            SeqRendererController sqC = new SeqRendererController();
            String responseString = SeqRendererController.getSequenceById(kf.Id);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2000'));
        Test.stopTest();   
    }

    @IsTest
    static void test_getSequenceById_empty(){
        
        Test.startTest();
            String responseString = SeqRendererController.getSequenceById(null);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2100'));
        Test.stopTest();
    }

    @isTest
    static void test_getSequenceBySurveyGuid_empty() {
        Test.startTest();
        String responseString = SeqRendererController.getSequenceBySurveyGuid(null);
        System.assertNotEquals(responseString, null);
        System.assert(responseString.contains('2100'));
        Test.stopTest();
    }

    @isTest
    static void test_getSequenceBySurveyGuid() {
        Test.startTest();
        Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
        String responseString = SeqRendererController.getSequenceBySurveyGuid(siObj.Kinetics__GUID__c);
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
        String responseString = SeqRendererController.getSequenceBySurveyGuid(siObj.Kinetics__GUID__c);
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
        String responseString = SeqRendererController.getSequenceBySurveyGuid(siObj.Kinetics__GUID__c);
        System.assertNotEquals(responseString, null);
        System.assert(responseString.contains('2100'));
        Test.stopTest();
    }

    @isTest
    static void test_updateSurvey2InProgress() {
        Test.startTest();
        Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
        String responseString = SeqRendererController.updateSurvey2InProgress(siObj.Kinetics__GUID__c);
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
            SeqRendererController.saveAnswers(siObj.Kinetics__GUID__c, answerString);
            
        Test.stopTest();
    }

    @isTest
    static void test_updateSurvey2InProgress_withEventCreation() {
        Kinetics__FieldKo_Kinetics_Setting__c setting = Kinetics__FieldKo_Kinetics_Setting__c.getInstance();
        setting.Kinetics__Create_Event__c = true;
        update setting;

        Test.startTest();
            Kinetics__Survey_Invitation__c siObj = [select Id, Kinetics__GUID__c from Kinetics__Survey_Invitation__c limit 1];
            String responseString = SeqRendererController.updateSurvey2InProgress(siObj.Kinetics__GUID__c);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2000'));
        Test.stopTest();
    }

    @isTest
    private static void test_getSequenceByIdForNewFormat () {
        Kinetics__Kinetic_Form__c template = new Kinetics__Kinetic_Form__c();
        template.Kinetics__Chat_GPT_Parameters__c = '{"yourrole":"Australia Certified Organic Inspector","checklistneed":"To check the compliance to Organic Handling Plan","inspectionobjective":"Inspect the compliance to the Organic Handling Standards","applicableStandards":"https://www.ecfr.gov/current/title-7/subtitle-B/chapter-I/subchapter-M/part-205/subpart-C/section-205.201,"}';
        template.Kinetics__Template_Metadata__c = '[{"pageno":0,"displayno":1,"sectionlist":[{"sectionno":0,"stitle":"","sinstructions":"","displayno":1,"questionWrapperList":[{"uid":"0.0.1","Name":"star rating question","Kinetics__Field_Type__c":"Rating","Kinetics__Assign_Tasks__c":true,"Kinetics__Attach_Photos_or_Files__c":true,"Kinetics__Capture_Notes__c":true,"Kinetics__Required__c":true,"Kinetics__Values__c":[],"displayQuestionNo":"1.1","pageno":0,"sectionno":0,"isdragover":false,"gotfocus":true,"icon":"utility:rating"}]}]}]';
        template.Name = 'Test star ratomg questions';
        template.Kinetics__Status__c = 'Active';
        insert template;

        Test.startTest();
            SeqRendererController sqC = new SeqRendererController();
            String responseString = SeqRendererController.getSequenceById(template.Id);
            System.assertNotEquals(responseString, null);
            System.assert(responseString.contains('2000'));
        Test.stopTest();
    }
}