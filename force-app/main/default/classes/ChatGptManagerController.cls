public class ChatGptManagerController {
    
    @AuraEnabled
    public static String hasManagerPanelAccess() {
        Response res = new Response();
        Boolean hasAccess = false;

        List<PermissionSetAssignment> assignments = [  SELECT Id, PermissionSet.Name 
                                                        FROM PermissionSetAssignment 
                                                        WHERE AssigneeId =: UserInfo.getUserId()
                                                    ];
        for (PermissionSetAssignment assignment : assignments) {
            if (assignment.PermissionSet.Name == 'ChatGPT_Manager') {
                hasAccess = true;
            }
        }

        res.statusCode = 2000;
        res.responseMessage = 'success';
        res.responseDetails = hasAccess;

        return JSON.serialize(res);
    }

    @AuraEnabled
    public static String getGptJobList() {
        Response res = new Response();
           
        List<GPT_Job__c> jobs = [SELECT Id, Name, Completion_Token__c, CreatedBy.Name, CreatedDate, Prompt_Token__c, Type__c 
                                    FROM GPT_Job__c 
                                    ORDER BY CreatedDate desc];
        List<GPTJobFE> jobList = new List<GPTJobFE>();
        for(GPT_Job__c j: jobs){
            if(j.Prompt_Token__c == null && j.Completion_Token__c == null){
                continue;
            }
            GPTJobFE jobFE = new GPTJobFE();
            jobFE.id = j.Id;
            jobFE.link = '/' + jobFE.id;
            jobFE.name = j.Name;
            jobFE.requestToken = j.Prompt_Token__c != null ? j.Prompt_Token__c : 0;
            jobFE.responseToken = j.Completion_Token__c != null ? j.Prompt_Token__c : 0;
            
            jobFE.createdDate = String.valueOf(j.CreatedDate.date());
            jobFE.createdBy = j.CreatedBy.Name;
            jobFE.type = j.Type__c;
            Decimal totalTokenDecimal = jobFE.requestToken + jobFE.responseToken;
            jobFE.totalToken = totalTokenDecimal.format();
            jobList.add(jobFE);
        }
        res.statusCode = 2000;
        res.responseMessage = 'success';
        res.responseDetails = jobList;
        return JSON.serialize(res); 

    }

    @AuraEnabled
    public static String getCurrentUsage(){
        Response res = new Response();
        GPT_Usage__c usageSetting = GPT_Usage__c.getOrgDefaults();
        if (usageSetting != null && usageSetting.Token_Available__c != null) {
            res.statusCode = 2000;
            res.responseMessage = 'success';
            Decimal decimalValue = usageSetting.Token_Available__c;
            res.responseDetails = decimalValue.format();
        } else {
            res.statusCode = 2100;
            res.responseMessage = 'error';
        }
        return JSON.serialize(res);
    }

    public static Boolean updateGptUsage(Decimal tokenConsumed){
        GPT_Usage__c usageSetting = GPT_Usage__c.getOrgDefaults();
        Boolean success = false;
        if (usageSetting != null && usageSetting.Token_Available__c != null) {
            Decimal newTokenNum = usageSetting.Token_Available__c - tokenConsumed;
            usageSetting.Token_Available__c = newTokenNum;
            update usageSetting;
            success = true;
        } else {

        }
        return success;
    }

    public class GPTJobFE{
        String link;
        String id;
        String name;
        Decimal requestToken;
        Decimal responseToken;
        String totalToken;
        String createdDate;
        String createdBy;
        String type;
    }

    public class Response{
        Integer statusCode;
        String responseMessage;
        Object responseDetails;
    }
}