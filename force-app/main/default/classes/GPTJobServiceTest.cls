@isTest
public class GPTJobServiceTest {
    
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
    
    @isTest static void testCreateJob() {

        Kinetics__Inspection__c inspection = [SELECT Id FROM Kinetics__Inspection__c Limit 1];


        // Prepare the data
        String srcRecId = inspection.Id; // Replace with an actual record ID
        String srcRecType = 'inspection'; // Replace with an actual record type
        String jobType = 'Create a summary'; // Replace with an actual job type
        String prompt = '{"temperature":0.2,"messages":[{"content":"abc","role":"user"}],"model":"gpt-4"}'; // Replace with an actual prompt

        // Call the method to test
        Test.startTest();
        GPT_Job__c job = GPTJobService.createJob(srcRecId, srcRecType, jobType, prompt);
        Test.stopTest();

        // Check the results
        System.assertNotEquals(null, job.Id, 'Job was not created.');
    }

    @isTest static void testSubmitJobToChatGPT_Success() {
        // Create a GPT Job
        GPT_Job__c job = new GPT_Job__c(
            // Initialize your job fields here
            Prompt__c = 'Your JSON here',
            Retry_Count__c = 0,
            Retry_Count_Max__c = 5
        );
        insert job;

        // Add the job ID to a list
        List<ID> jobIDs = new List<ID>();
        jobIDs.add(job.Id);

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new GPTMockHttpResponse());

        // Execute the method
        Test.startTest();
        GPTJobService.submitJobToChatGPT(jobIDs);
        Test.stopTest();

        // Retrieve the updated job
        GPT_Job__c updatedJob = [SELECT Id, Prompt_Token__c, Completion_Token__c, Response_Payload__c, Status__c FROM GPT_Job__c WHERE Id = :job.Id];

        // Add your assertions here to verify the job has been updated as expected
    }

    @isTest static void testSubmitJobToChatGPT_Exception() {
        // Create a GPT Job
        GPT_Job__c job = new GPT_Job__c(
            // Initialize your job fields here
            Prompt__c = null,
            Retry_Count__c = 0,
            Retry_Count_Max__c = 5,
            Status__c = 'Submitted'
        );
        insert job;

        // Add the job ID to a list
        List<ID> jobIDs = new List<ID>();
        jobIDs.add(job.Id);

        // Mock the HTTP callout to throw an exception
        Test.setMock(HttpCalloutMock.class, new GPTMockHttpResponse());

        // Execute the method
        Test.startTest();
        GPTJobService.submitJobToChatGPT(jobIDs);
        Test.stopTest();

        // Retrieve the updated job
        GPT_Job__c updatedJob = [SELECT Id, Retry_Count__c, Error_Details__c, Status__c FROM GPT_Job__c WHERE Id = :job.Id];

        // Add your assertions here to verify the job has been updated as expected
    }
    @isTest static void testhandleJobReTry() {
        // Create a GPT Job
        GPT_Job__c job = new GPT_Job__c(
            // Initialize your job fields here
            Prompt__c = null,
            Retry_Count__c = 0,
            Retry_Count_Max__c = 5,
            Status__c = 'Submitted'
        );
        insert job;

        // Add the job ID to a list
        List<ID> jobIDs = new List<ID>();
        jobIDs.add(job.Id);

        // Mock the HTTP callout to throw an exception
        Test.setMock(HttpCalloutMock.class, new GPTMockHttpResponse());

        // Execute the method
        Test.startTest();
            GPTJobService.handleJobReTry(job,'error message');
        Test.stopTest();

        // Retrieve the updated job
        GPT_Job__c updatedJob = [SELECT Id, Retry_Count__c, Error_Details__c, Status__c FROM GPT_Job__c WHERE Id = :job.Id];

        // Add your assertions here to verify the job has been updated as expected
    }
    

    private class GPTMockHttpResponse implements HttpCalloutMock {
        // Implement HttpCalloutMock.respond method
        public HTTPResponse respond(HTTPRequest request) {
            // Create a fake HTTP response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"id":"chatcmpl-7G5Bk4KGOBFmYBgNaznRuvH27RL3n","object":"chat.completion","created":1684067548,"model":"gpt-4-0314","usage":{"prompt_tokens":1150,"completion_tokens":403,"total_tokens":1553},"choices":[{"message":{"role":"assistant","content":"abc"},"finish_reason":"stop","index":0}]}');
            response.setStatusCode(200);
            return response;
        }
    }
}