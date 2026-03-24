/***
* Author: Shankar Dupade (FieldKo)
* Updated : 4th Aug 2021
* Purpose: Helper class for Batch Class for sending auto reminders of Survey Invitation
*/
public with sharing class SeqReminderSenderBatchHelper {
    
    //return stages for which we don't want send reminders
    public static List<String> getStagesToSkip() {
        List<String> stageToSkip = new List<String>();
        stageToSkip.add(GlobalConstants.completedStage);
        stageToSkip.add(GlobalConstants.expiredStage);
        //stageToSkip.add(GlobalConstants.sentToRecipientStage);
        return stageToSkip;
    }

    public static Boolean isValidForInvitation(Kinetics__Survey_Invitation__c sinvitation) {
        return (String.isNotEmpty(sinvitation.Kinetics__GUID__c) 
            && String.isNotEmpty(sinvitation.Kinetics__Contact__c)
            && String.isNotEmpty(sinvitation.Kinetics__Kinetic_Form__c)
            && String.isNotEmpty(sinvitation.Kinetics__Kinetic_Job__c));
    }

    public static Boolean doSendReminder(Kinetics__Survey_Invitation__c sinvitation) {
        Boolean sendReminder = sinvitation.Kinetics__Send_Auto_Reminders__c;
        Date createdDateLocal = sinvitation.CreatedDate.date();
        if(sendReminder == false) {
            return false;
        }

        //check for reminder for first time
        Date firstReminderDate = createdDateLocal;
        Date invitationExpirationDate = createdDateLocal.addDays(Integer.valueOf(sinvitation.Kinetics__TTL_Day__c));
        
        //check if invitation has expired
        if(invitationExpirationDate < Date.today()) {
            return false;
        }

        if(sinvitation.Kinetics__Days_before_First_Reminder__c != null 
            && sinvitation.Kinetics__Days_before_First_Reminder__c > 0) {
            firstReminderDate = firstReminderDate.addDays(Integer.valueOf(sinvitation.Kinetics__Days_before_First_Reminder__c));
            if(firstReminderDate <= Date.today() 
                && (sinvitation.Kinetics__Reminder_Sent_count__c == 0 || sinvitation.Kinetics__Reminder_Sent_count__c == null)
                && firstReminderDate <= invitationExpirationDate) {
                return true;
            } else if(firstReminderDate > Date.today()) {
                //we have not reached to date from where we can send reminders
                return false;
            }
        }
        system.debug('firstReminderDate > Date.today(): ' + (firstReminderDate > Date.today()));
        System.debug('check for recurring reminder ');
        //check for recurring reminder 
        Date lastReminderSentDate = sinvitation.Kinetics__Last_Reminder_Sent_Date__c;
        if(lastReminderSentDate == null) {
            //ideally this should not happen, because first reminder should been sent before reaching here
           // lastReminderSentDate = firstReminderDate;
        }

        Date nextReminderDate =  lastReminderSentDate;
        if(sinvitation.Kinetics__Days_between_two_reminders__c != null 
            && sinvitation.Kinetics__Days_between_two_reminders__c != 0) {
            nextReminderDate = nextReminderDate.addDays(Integer.valueOf(sinvitation.Kinetics__Days_between_two_reminders__c));
        }

        if(nextReminderDate == lastReminderSentDate 
            || nextReminderDate > invitationExpirationDate ) {
            return false;
        } else if(nextReminderDate == Date.today()) {
            return true;
        } 

        return false;
    }

    public static Boolean doExpireInvitation(Kinetics__Survey_Invitation__c sinvitation) {
        Date createdDateLocal = sinvitation.CreatedDate.date();
        
        Date invitationExpirationDate = createdDateLocal.addDays(Integer.valueOf(sinvitation.Kinetics__TTL_Day__c));
        if(invitationExpirationDate < Date.today()) {
            return true;
        }
        return false;
    }
    
    // public static Note getNoteWithExceptionDetails(Exception exc, Kinetics__Survey_Invitation__c sinvitation, Map<String, Note> noteByInvitationId) {
    //     Note nRec = new Note();
    //     String bodyString = '';
    //     if(String.isNotEmpty(sinvitation.Id) && noteByInvitationId.containsKey(sinvitation.Id)) {
    //         nRec = noteByInvitationId.get(sinvitation.Id);
    //     }

    //     nRec.Title = 'Exception Occurred while sending invitation reminder';
    //     bodyString = 'Exception Details are as - \nMessage :' + exc.getMessage() + '\nStackTraceString: ' + exc.getStackTraceString() + '\nCause: ' +exc.getCause();
    //     bodyString = bodyString + '\n' + nRec.Body;
    //     bodyString = bodyString.subString(0,255);
    //     nRec.Body = bodyString;
    //     nRec.ParentId = sinvitation.Id;

    //     return nRec;
    // }
}