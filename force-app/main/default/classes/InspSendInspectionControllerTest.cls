/**
 * Auther: Shankar Dupade
 * Purpose: test classes for InspSendInspectionController
 * Date: 10-10-2022
 */
@isTest
public with sharing class InspSendInspectionControllerTest {
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
    static void getTemplateDetailsByInspectionId_test() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        Test.startTest();
            System.assertNotEquals(inspList.size(), 0);
            String response = InspSendInspectionController.getTemplateDetailsByInspectionId(inspList[0].Id);
            System.assertNotEquals(response, null);
            String nullResponse = InspSendInspectionController.getTemplateDetailsByInspectionId('');
            System.assertNotEquals(nullResponse, null);
        Test.stopTest();       
    }

    @isTest
    static void updateAnswerToLinkWithSurveyInvitation_test() {
        List<Kinetics__Inspection__c> inspList = [select ID from Kinetics__Inspection__c];
        Test.startTest();
            System.assertNotEquals(inspList.size(), 0);
            String inspectionId = inspList[0].Id;
            
            String jobId = null;
            List<String> contactIds = new List<String>();
            String templateId = null;

            Kinetics__Survey_Invitation__c si = [SELECT Id, Kinetics__Contact__c, Kinetics__Kinetic_Form__c, Kinetics__Kinetic_Job__c, Kinetics__Inspection__c 
                                                    FROM Kinetics__Survey_Invitation__c];

            System.debug('si: ' + JSON.serialize(si));
            si.Kinetics__Inspection__c = inspectionId;
            update si;

            jobId = si.Kinetics__Kinetic_Job__c;
            contactIds.clear();
            contactIds.add(si.Contact__c);
            templateId = si.Kinetics__Kinetic_Form__c;
            String response = InspSendInspectionController.updateAnswerToLinkWithSurveyInvitation(inspectionId, jobId, contactIds, templateId);
            System.assertNotEquals(response, null);
            response = InspSendInspectionController.updateAnswerToLinkWithSurveyInvitation(inspectionId, '', contactIds, templateId);
        Test.stopTest();
    }
}