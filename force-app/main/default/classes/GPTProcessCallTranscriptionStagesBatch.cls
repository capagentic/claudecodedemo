/***
* Author: Shankar Dupade (FieldKo)
* Updated : 3rd Apr 2024
* Purpose: Batch Class for processing in progress meeting records to get the response for different stages
*/
global with sharing class GPTProcessCallTranscriptionStagesBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        final integer MAX_HOUR_DIFFERENCE = 2;
        List<String> statusToCheck = new List<String>{'completed'};
        String alldone = 'all_done';
		List<AsyncApexJob> apexJobList = [SELECT Id, CreatedDate FROM AsyncApexJob WHERE ApexClass.Name = 'GPTProcessCallTranscriptionStagesBatch' 
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
			
			query = 'SELECT Id, Name, '
                + ' Kinetics__Evaluting_Stage__c FROM Kinetics__Meeting__c '
                + ' WHERE Kinetics__GPT_Thread_Run_Job_Status__c IN :statusToCheck AND Kinetics__Evaluting_Stage__c != null AND Kinetics__Evaluting_Stage__c !=:alldone';
		}
		System.debug('query  ==  ' + query);
		return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Kinetics__Meeting__c> meetingRecordList) {
      
        for(Kinetics__Meeting__c meetingRecord: meetingRecordList) {
            try {
                if(meetingRecord.Kinetics__Evaluting_Stage__c == 'assessment') {
                    meetingRecord.Kinetics__Evaluting_Stage__c = 'next_steps';
                } else if(meetingRecord.Kinetics__Evaluting_Stage__c == 'next_steps') {
                    meetingRecord.Kinetics__Evaluting_Stage__c = 'opportunity';
                } else if(meetingRecord.Kinetics__Evaluting_Stage__c == 'opportunity') {
                    meetingRecord.Kinetics__Evaluting_Stage__c = 'risks';
                } else {
                    meetingRecord.Kinetics__Evaluting_Stage__c = 'all_done';
                }
                if(meetingRecord.Kinetics__Evaluting_Stage__c != 'all_done') {
                    ProcessCallTranscriptionHomeController.createMessageForSummaryGPTJob(meetingRecord.Id,meetingRecord.Kinetics__Evaluting_Stage__c);
                    ProcessCallTranscriptionHomeController.runSummaryGPTJob(meetingRecord.Id);
                }
            } catch(Exception exc) {
                // Note nRec = SeqReminderSenderBatchHelper.getNoteWithExceptionDetails(exc, sinvitation, noteByInvitationId);
                // exceptionNoteList.add(nRec);
                System.debug('Exception occurred: ' + exc.getMessage());
            }
        }
        update meetingRecordList;
    }

    global void finish(Database.BatchableContext BC) {       
		
	}

    global class customException extends Exception {
        
    }

}