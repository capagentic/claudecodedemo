/***
* Author: Shankar Dupade (FieldKo)
* Updated : 6rd Feb 2024
* Purpose: Batch Class for collecting and fetching messages from openAI
*/
global with sharing class ProcessQueuedCallTranscriptionBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        final integer MAX_HOUR_DIFFERENCE = 2;
        List<String> statusToCheck = new List<String>{'queued'};
		List<AsyncApexJob> apexJobList = [SELECT Id, CreatedDate FROM AsyncApexJob WHERE ApexClass.Name = 'ProcessQueuedCallTranscriptionBatch' 
											AND ID !=:BC.getJobId() AND JobType = 'BatchApex' 
											AND Status NOT IN ('Aborted', 'Completed', 'Failed')];
		List<AsyncApexJob> apexJobsToAbort = new List<AsyncApexJob>();

        //create empty list of survey invitation, so that no records are returned
		List<Kinetics__Meeting__c> meetingRecordList = new List<Kinetics__Meeting__c>();
		String query = '';
		DateTime currentDateTime = DateTime.now();
		for(AsyncApexJob asyncApexJob : apexJobList) {
			// If the job in context was of some past date or the time differenve between the jobs is greater than MAX_HOUR_DIFFERENCE 
			// hours then add that job in a the jobList to be aborted.
			if( !currentDateTime.isSameDay( (asyncApexJob.CreatedDate).date()) || 
				(currentDateTime.hourGMT() - (asyncApexJob.CreatedDate).hourGmt()) > MAX_HOUR_DIFFERENCE ) {
				apexJobsToAbort.add(asyncApexJob);
			}
		}

		if(!apexJobList.isEmpty() && apexJobsToAbort.IsEmpty()) {
			//currently same batch is exeuting, so DO NOT START new batch
			//create empty list and fire query so that no records are returned
			System.debug('Start: Earlier batch execution is not completed yet.');
			query = 'SELECT Id FROM Kinetics__Meeting__c WHERE Id IN :meetingRecordList';
		} else {
			// Abort all jobs of same name that are in processing for more than 2 hours.
			for(AsyncApexJob asyncApexJob : apexJobsToAbort) {
				System.abortJob(asyncApexJob.Id);
			}
			
			query = 'SELECT Id, Name, Kinetics__GPT_Assistant_ID__c, Kinetics__GPT_Thread_ID__c, Kinetics__GPT_Thread_Run_Id__c, Kinetics__GPT_Thread_Run_Job_Status__c '
                + ' FROM Kinetics__Meeting__c '
                + ' WHERE Kinetics__GPT_Thread_Run_Job_Status__c IN :statusToCheck limit 5';
		}
		System.debug('query  ==  ' + query);
		return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Kinetics__Meeting__c> meetingRecordList) {
      
        for(Kinetics__Meeting__c meetingRecord: meetingRecordList) {
            try {
                ProcessCallTranscriptionHomeController.retriveMessagesForThread(meetingRecord.Id);
            } catch(Exception exc) {
                // Note nRec = SeqReminderSenderBatchHelper.getNoteWithExceptionDetails(exc, sinvitation, noteByInvitationId);
                // exceptionNoteList.add(nRec);
                System.debug('Exception occurred: ' + exc.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {       
		
	}

    global class customException extends Exception {
        
    }
}