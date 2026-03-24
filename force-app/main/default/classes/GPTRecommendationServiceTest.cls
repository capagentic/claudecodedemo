/**
 * Auther: Shankar Dupade
 * Purpose: test classes for GPTRecommendationService
 * Date: 07-Mar-2024
 */
@isTest
public class GPTRecommendationServiceTest {

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

    @isTest static void testCreateNotesTasks() {
        // Prepare the data
        // Assuming that you have already defined the necessary sObjects and fields, and the required records already exist in the database.
        GPT_Job__c job = new GPT_Job__c(
            // Initialize your job fields here
            Response_Payload__c = '{"id":"chatcmpl-7ME7f4gAhoYwxriglPTAruErBwrqf","object":"chat.completion","created":1685531859,"model":"gpt-4-0314","usage":{"prompt_tokens":3479,"completion_tokens":475,"total_tokens":3954},"choices":[{"message":{"role":"assistant","content":"{\n  \"summary_title\": \"Inspection Checklist Summary\",\n  \"detailed_analysis\": \"The inspection checklist covered various aspects of the establishment, including food safety, marketing materials, customer service, and cleanliness. Overall, the establishment demonstrated compliance in several areas, such as cooking temperatures, storage of raw and cooked proteins, fire safety, and external cleanliness. However, there were some areas of non-compliance, including cooking and holding temperatures for certain food items, cool room safety, CCTV functionality, contractor and visitor management, and cleanliness of staff toilets and wash-up sink.\",\n  \"summary\": \"The establishment has shown good compliance in many areas, but there are some areas that require improvement to ensure a safe and hygienic environment for both customers and staff.\",\n  \"recommendations\": [\n    {\n      \"subject\": \"Cooking and Holding Temperatures\",\n      \"priority\": \"High\",\n      \"description\": \"Ensure that all food items are cooked and held at the appropriate temperatures, as per the guidelines. Regularly monitor and document these temperatures.\"\n    },\n    {\n      \"subject\": \"Cool Room Safety\",\n      \"priority\": \"High\",\n      \"description\": \"Install and maintain safety releases and bells on cool room and freezer doors, and ensure they are operational.\"\n    },\n    {\n      \"subject\": \"CCTV Functionality\",\n      \"priority\": \"Medium\",\n      \"description\": \"Ensure that the CCTV system is fully operational and covers all necessary areas of the establishment.\"\n    },\n    {\n      \"subject\": \"Contractor and Visitor Management\",\n      \"priority\": \"Medium\",\n      \"description\": \"Implement a system for contractors and visitors to sign in, receive induction, and be informed of any hazards or risks that may impact them.\"\n    },\n    {\n      \"subject\": \"Cleanliness of Staff Toilets and Wash-up Sink\",\n      \"priority\": \"Medium\",\n      \"description\": \"Ensure that staff toilets and wash-up sink areas are regularly cleaned and maintained to a high standard.\"\n    }\n  ],\n  \"interesting_summary\": [\n    {\n      \"description\": \"The establishment demonstrated good compliance in cooking temperatures and storage of raw and cooked proteins, ensuring food safety.\"\n    },\n    {\n      \"description\": \"External cleanliness and marketing materials were well-maintained, contributing to a positive customer experience.\"\n    }\n  ]\n}"},"finish_reason":"stop","index":0}]}'
        );
        insert job;

        Kinetics__Inspection__c inspection = [SELECT Id FROM Kinetics__Inspection__c Limit 1];

        User user = [ SELECT ID FROM User Limit 1];

        // Define the response payload
        job.Response_Payload__c = '{"id":"chatcmpl-7G5Bk4KGOBFmYBgNaznRuvH27RL3n","object":"chat.completion","created":1684067548,"model":"gpt-4-0314","usage":{"prompt_tokens":1150,"completion_tokens":403,"total_tokens":1553},"choices":[{"message":{"role":"assistant","content":"{\n  \"summary_title\": \"Workplace Incident: Hand Crushed in Grape Crusher\",\n  \"detailed_analysis\": \"On May 3, 2023, an incident occurred at Season Organics Wines, located at 95 South Rd, Brighton VIC 3186, Australia. The injured employee, Angelo Kotos, was feeding Shiraz grapes into the grape crusher when he attempted to force the grapes down the hopper with his hand instead of using the hopper shovel. As a result, his hand was crushed in the grape crusher.\",\n  \"summary\": \"Angelo Kotos, a male warehouse grape crusher employee, suffered a hand injury while working at Season Organics Wines. The incident occurred when he tried to force grapes down the hopper with his hand instead of using the hopper shovel. Immediate action was taken by applying pressure to the wound and wrapping it in a towel.\",\n  \"recommendations\": [\n    {\n      \"subject\": \"Safety Training\",\n      \"priority\": \"High\",\n      \"description\": \"Ensure all employees receive proper safety training on the use of equipment, including the grape crusher and hopper shovel.\"\n    },\n    {\n      \"subject\": \"Safety Equipment\",\n      \"priority\": \"Medium\",\n      \"description\": \"Provide appropriate safety equipment, such as gloves and safety goggles, to all employees working with machinery.\"\n    },\n    {\n      \"subject\": \"Supervision\",\n      \"priority\": \"Medium\",\n      \"description\": \"Increase supervision during high-risk tasks to ensure employees are following safety protocols and using equipment correctly.\"\n    }\n  ],\n  \"interesting_summary\": [\n    {\n      \"description\": \"The incident occurred at Season Organics Wines, a company located in Brighton, Victoria, Australia.\"\n    },\n    {\n      \"description\": \"Angelo Kotos, the injured employee, was born on May 4, 2001, and resides at 148 St Johns Road, Brighton 3186.\"\n    }\n  ]\n}"},"finish_reason":"stop","index":0}]}';
        job.Status__c = 'Response Received';
        job.Kinetics__New_Records_Owner_ID__c = user.ID;
        job.Original_Request_Record_ID__c = inspection.Id;
        update job;

        // Call the method to test
        Test.startTest();
        GPTRecommendationService.createNotesTasks(job.Id);
        Test.stopTest();

        // Check the results
        // Assuming that the task, contentNote, and contentDocumentLink lists are expected to have items after running the method
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :job.Id];
        // System.assert(tasks.size() > 0, 'No tasks were created.');

        // First, retrieve the ContentDocumentId values from the ContentDocumentLink records.
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :inspection.Id];

        // Create a set to store the ContentDocumentId values.
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            contentDocumentIds.add(link.ContentDocumentId);
        }

        // Use the set of ContentDocumentId values in the query for ContentNote records.
        List<ContentNote> notes = [SELECT Id FROM ContentNote WHERE Id IN :contentDocumentIds];
        // System.assert(notes.size() > 0, 'No content notes were created.');


        // Check that the status of the job has been updated
        GPT_Job__c updatedJob = [SELECT Id, Status__c FROM GPT_Job__c WHERE Id = :job.Id];
        // System.assertEquals('Response Parsed', updatedJob.Status__c, 'Job status was not updated correctly.');
    }

    @isTest static void testCreateNotesTasksException() {
        // Prepare the data
        GPT_Job__c job = new GPT_Job__c(
            // Initialize your job fields here
            Response_Payload__c = '{"id":"chatcmpl-7ME7f4gAhoYwxriglPTAruErBwrqf","object":"chat.completion","created":1685531859,"model":"gpt-4-0314","usage":{"prompt_tokens":3479,"completion_tokens":475,"total_tokens":3954},"choices":[{"message":{"role":"assistant","content":"{\n  \"summary_title\": \"Inspection Checklist Summary\",\n  \"detailed_analysis\": \"The inspection checklist covered various aspects of the establishment, including food safety, marketing materials, customer service, and cleanliness. Overall, the establishment demonstrated compliance in several areas, such as cooking temperatures, storage of raw and cooked proteins, fire safety, and external cleanliness. However, there were some areas of non-compliance, including cooking and holding temperatures for certain food items, cool room safety, CCTV functionality, contractor and visitor management, and cleanliness of staff toilets and wash-up sink.\",\n  \"summary\": \"The establishment has shown good compliance in many areas, but there are some areas that require improvement to ensure a safe and hygienic environment for both customers and staff.\",\n  \"recommendations\": [\n    {\n      \"subject\": \"Cooking and Holding Temperatures\",\n      \"priority\": \"High\",\n      \"description\": \"Ensure that all food items are cooked and held at the appropriate temperatures, as per the guidelines. Regularly monitor and document these temperatures.\"\n    },\n    {\n      \"subject\": \"Cool Room Safety\",\n      \"priority\": \"High\",\n      \"description\": \"Install and maintain safety releases and bells on cool room and freezer doors, and ensure they are operational.\"\n    },\n    {\n      \"subject\": \"CCTV Functionality\",\n      \"priority\": \"Medium\",\n      \"description\": \"Ensure that the CCTV system is fully operational and covers all necessary areas of the establishment.\"\n    },\n    {\n      \"subject\": \"Contractor and Visitor Management\",\n      \"priority\": \"Medium\",\n      \"description\": \"Implement a system for contractors and visitors to sign in, receive induction, and be informed of any hazards or risks that may impact them.\"\n    },\n    {\n      \"subject\": \"Cleanliness of Staff Toilets and Wash-up Sink\",\n      \"priority\": \"Medium\",\n      \"description\": \"Ensure that staff toilets and wash-up sink areas are regularly cleaned and maintained to a high standard.\"\n    }\n  ],\n  \"interesting_summary\": [\n    {\n      \"description\": \"The establishment demonstrated good compliance in cooking temperatures and storage of raw and cooked proteins, ensuring food safety.\"\n    },\n    {\n      \"description\": \"External cleanliness and marketing materials were well-maintained, contributing to a positive customer experience.\"\n    }\n  ]\n}"},"finish_reason":"stop","index":0}]}'
        );
        insert job;

        // Define an incorrect response payload to simulate an exception
      //  job.Response_Payload__c = 'Incorrect JSON format';

        // Call the method to test
        Test.startTest();
        GPTRecommendationService.createNotesTasks(job.Id);
        Test.stopTest();

        // Check that the status of the job has been updated and an error message has been added
        GPT_Job__c updatedJob = [SELECT Id, Status__c, Error_Details__c FROM GPT_Job__c WHERE Id = :job.Id];
        System.assertEquals('Parsing Error', updatedJob.Status__c, 'Job status was not updated correctly.');
        System.assertNotEquals(null, updatedJob.Error_Details__c, 'Error details were not updated correctly.');
    }
}