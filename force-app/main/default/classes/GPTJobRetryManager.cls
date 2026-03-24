public class GPTJobRetryManager implements Queueable {

    private Id recordId;
    
    public GPTJobRetryManager(Id recordId) {
        this.recordId = recordId;
    }

    public void execute(QueueableContext context) {
        GPT_Job__c job = [SELECT Id, Status__c FROM GPT_Job__c WHERE Id =: recordId ];
        job.Status__c = 'Submitted';
        update job;
    }
}