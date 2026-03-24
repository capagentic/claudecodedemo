public class GPTJobService {

    public static GPT_Job__c createJob(String srcRecId, String srcRecType, String jobType, String prompt){
        system.debug('GPTJobService>createJob>prompt=' + prompt);
        GPT_Job__c job = new GPT_Job__c();
        try{
            
            job.Status__c = 'Submitted';
            job.Type__c = jobType;

            if(prompt.length() <= 131072){  // max length for the Prompt__c field
                job.Prompt__c = prompt;
                job.Prompt_Stored_in_File__c = false;
            }else{
                job.Prompt__c = 'The promt string is too long and is stored in a file. Please navigate to the File related list under the Related tab.';
                job.Prompt_Stored_in_File__c = true;
            }
            
            job.Original_Request_Record_ID__c = srcRecId;
            job.Original_Request_Record_Object__c = srcRecType;
            job.New_Records_Owner_ID__c = UserInfo.getUserId();

            if(srcRecType == 'Inspection'){
                job.Inspection__c = job.Original_Request_Record_ID__c;
            }

            GPTChatRequest gptReq = (GPTChatRequest) JSON.deserialize(prompt, GPTChatRequest.class);
            String model = gptReq.model;
            Decimal temperature = gptReq.temperature;
            job.Model__c = model;
            job.Temperature__c = temperature;
            insert job;

            if(job.Prompt_Stored_in_File__c){
                String fileID = GPTJobFileService.createAndAttachFile(job.Id, prompt);
                system.debug('GPTJobService>createJob>fileID=' + fileID);
            }
        }catch(Exception ex){
            system.debug('error>ex:' + ex);
        }
        return job;
    }
    

    @InvocableMethod(label='Call ChatGPT' description='Fire an API call to ChatGPT' category='GPT Job')
    public static void submitJobToChatGPT(List<ID> jobID) {
        List<GPT_Job__c> jobs = [SELECT Id, Prompt__c, Prompt_Stored_in_File__c, Retry_Count__c, Retry_Count_Max__c, Error_Details__c 
                                    FROM GPT_Job__c 
                                    WHERE ID IN: jobID];
        

        GPT_Job__c job = jobs.get(0);
        String prompt = getPrompt(job);
        system.debug('******** prompt= ' + prompt);
        HTTPResponse res;
        try{
            Datetime startTime = Datetime.now();
            res = tbChatGPTController.doCallout(job.Prompt__c, new Map<String, String>());
            System.debug('res=' + res);
            Datetime endTime = Datetime.now();
            Long timeDifferenceMillis = endTime.getTime() - startTime.getTime();
            Integer timeDifferenceSeconds = (Integer)(timeDifferenceMillis / 1000); // Convert milliseconds to seconds

            GPTResponse gptRes = (GPTResponse) JSON.deserialize(res.getBody(), GPTResponse.class);
            job.Prompt_Token__c = gptRes.usage.prompt_tokens;
            job.Completion_Token__c = gptRes.usage.completion_tokens;
            job.Response_Payload__c = res.getBody();
            job.Status__c = 'Response Received';
            job.Callout_Duration__c = timeDifferenceSeconds;
            update job;

            Decimal tokenConsumed = job.Completion_Token__c + job.Prompt_Token__c;
            ChatGptManagerController.updateGptUsage(tokenConsumed);

        }catch(Exception e) {
            handleJobReTry(job, e.getMessage());
        }
    }

    @TestVisible 
    private static void handleJobReTry(GPT_Job__c job, String errorMessage) {
        if(job.Retry_Count__c < job.Retry_Count_Max__c){
            GPTJobRetryManager gptJobnMgr = new GPTJobRetryManager(job.ID);
            ID queueableJobID = System.enqueueJob(gptJobnMgr, 2);
        }
        logErrorToJob(job, errorMessage);
    }

    private static void logErrorToJob(GPT_Job__c job, String errorMessage){
        job.Status__c = 'Error';
        job.Retry_Count__c = job.Retry_Count__c + 1;

        String errorDetails = System.Now() + ':\n' +  errorMessage + '\n\n';
        job.Error_Details__c = (job.Error_Details__c != null) ? (job.Error_Details__c + '\n\n' + errorDetails): errorDetails;
        update job;
    }

    private static String getPrompt(GPT_Job__c job){
        String prompt;
system.debug('******** job= ' + job);
        if(!job.Prompt_Stored_in_File__c){
            prompt = job.Prompt__c;
        }else{
            prompt = GPTJobFileService.getFileContent(job.Id);
        }
        return prompt;
    }
}