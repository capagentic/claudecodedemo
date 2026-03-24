/***
* Author: Shankar Dupade (FieldKo)
* Updated : 3rd Aug 2021
* Purpose: Batch Class for sending auto reminders of Survey Invitation
*/
global with sharing class SeqReminderSenderBatch implements Database.Batchable<sObject>, Database.Stateful {
    

    global Database.QueryLocator start(Database.BatchableContext BC) {
        final integer MAX_HOUR_DIFFERENCE = 2;
        final List<String> stageToSkip = SeqReminderSenderBatchHelper.getStagesToSkip();
		List<AsyncApexJob> apexJobList = [SELECT Id, CreatedDate FROM AsyncApexJob WHERE ApexClass.Name = 'SeqReminderSenderBatch' 
											AND ID !=:BC.getJobId() AND JobType = 'BatchApex' 
											AND Status NOT IN ('Aborted', 'Completed', 'Failed')];
		List<AsyncApexJob> apexJobsToAbort = new List<AsyncApexJob>();

        //create empty list of survey invitation, so that no records are returned
		List<Kinetics__Survey_Invitation__c> invitationList = new List<Kinetics__Survey_Invitation__c>();
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
			query = 'SELECT Id FROM Kinetics__Survey_Invitation__c WHERE Id IN :invitationList';
		} else {
			// Abort all jobs of same name that are in processing for more than 2 hours.
			for(AsyncApexJob asyncApexJob : apexJobsToAbort) {
				System.abortJob(asyncApexJob.Id);
			}
			
			query = 'SELECT Id, Name, Kinetics__Days_before_First_Reminder__c, Kinetics__Days_between_two_reminders__c, Kinetics__GUID__c, Kinetics__Contact__c, '
                + ' Kinetics__Kinetic_Job__c, Kinetics__Send_Auto_Reminders__c, Kinetics__Stage__c, Kinetics__Kinetic_Form__c, Kinetics__TTL_Day__c, Kinetics__Last_Reminder_Sent_Date__c, '
                + ' Kinetics__Reminder_Sent_count__c, Kinetics__Channel__c, CreatedDate '
                + ' FROM Kinetics__Survey_Invitation__c '
                + ' WHERE Kinetics__Stage__c != :stageToSkip '
                + ' AND Kinetics__GUID__c != null AND Kinetics__Kinetic_Form__c != null AND Kinetics__Kinetic_Job__c != null '
                + ' AND Kinetics__Send_Auto_Reminders__c = true ';
		}
		System.debug('query  ==  ' + query);
		return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Kinetics__Survey_Invitation__c> invitationList) {
        List<Schema.DescribeFieldResult> surveyInvitationFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Survey_Invitation__c.Kinetics__Days_before_First_Reminder__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Days_between_two_reminders__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__GUID__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Contact__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Send_Auto_Reminders__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Stage__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Form__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__TTL_Day__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Last_Reminder_Sent_Date__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Reminder_Sent_count__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Channel__c.getDescribe()
        };

        if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
            && CheckUserPermission.checkFieldsReadAccess(surveyInvitationFieldList)
            && CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
            && CheckUserPermission.checkFieldsUpdateAccess(surveyInvitationFieldList))) {
                throw new customException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }

        List<String> recordsIdsToUpdate = new List<String>();
        // List<Note> exceptionNoteList = new List<Note>();
        // Map<String, Note> noteByInvitationId = new Map<String, Note>();
        // for(Note n: [select Id, Title, Body, ParentId from Note where ParentId IN :invitationList and Title = 'Exception Occurred while sending invitation reminder']){
        //     noteByInvitationId.put(n.ParentId, n);
        // }
        List<Kinetics__Survey_Invitation__c> expiredInvitations= new List<Kinetics__Survey_Invitation__c>();
        for(Kinetics__Survey_Invitation__c sinvitation: invitationList) {
            try {
                if(SeqReminderSenderBatchHelper.isValidForInvitation(sinvitation)
                    && sinvitation.Kinetics__Channel__c == GlobalConstants.channelSMS
                    && SeqReminderSenderBatchHelper.doSendReminder(sinvitation)) {
                        
                        recordsIdsToUpdate.add(sinvitation.Id);
                } else if (SeqReminderSenderBatchHelper.isValidForInvitation(sinvitation)
                    && sinvitation.Kinetics__Channel__c == GlobalConstants.channelEMAIL
                    && SeqReminderSenderBatchHelper.doSendReminder(sinvitation)) {
                    //implement the email reminder sending
                    recordsIdsToUpdate.add(sinvitation.Id);
                } else if(SeqReminderSenderBatchHelper.doExpireInvitation(sinvitation)) {
                    sinvitation.Kinetics__Stage__c = GlobalConstants.expiredStage;
                    expiredInvitations.add(sinvitation);
                }
            } catch(Exception exc) {
                // Note nRec = SeqReminderSenderBatchHelper.getNoteWithExceptionDetails(exc, sinvitation, noteByInvitationId);
                // exceptionNoteList.add(nRec);
                System.debug('Exception occurred: ' + exc.getMessage());
            }
        }
        if(!(CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
            && CheckUserPermission.checkFieldsUpdateAccess(surveyInvitationFieldList))) {
                throw new customException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }
        if(expiredInvitations.size() > 0) {
            update expiredInvitations;
        }
        if(recordsIdsToUpdate.size() > 0) {
            Kinetics__Kinetic_Invite_Reminder__e kiro = new Kinetics__Kinetic_Invite_Reminder__e();
            String invitationIdString = JSON.serialize(recordsIdsToUpdate);
            kiro.Kinetics__Kinetic_Invitation_Ids__c = invitationIdString;
            //update the running user for platform Event to current user
            //
            EventBus.publish(kiro);
        }
        // if(exceptionNoteList.size() > 0) {
        //     upsert exceptionNoteList;
        // }
    }

    global void finish(Database.BatchableContext BC) {       
		
	}

    global class customException extends Exception {
        
    }
}