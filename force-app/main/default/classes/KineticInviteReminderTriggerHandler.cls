/**
* Author: Shankar Dupade(FieldKo)
* Updated : 27th Aug 2021
* Purpose: Handler class for Trigger on Platform Event to sent reminder for Kinetic invites
*/
public with sharing class KineticInviteReminderTriggerHandler {
    public static void handleAfterInsert(List<Kinetics__Kinetic_Invite_Reminder__e> kjInviteList) {
        List<Kinetics__Survey_Invitation__c> recordsToUpdate = new List<Kinetics__Survey_Invitation__c>();
        final List<String> stageToSkip = SeqReminderSenderBatchHelper.getStagesToSkip();
        List<String> invitationRecordIdList = new List<String>();
        for(Kinetics__Kinetic_Invite_Reminder__e kir: kjInviteList) {
            invitationRecordIdList.addAll((List<String>) JSON.deserialize(kir.Kinetics__Kinetic_Invitation_Ids__c, List<String>.class));
        }

        List<Kinetics__Survey_Invitation__c> invitationList = [SELECT Id, Name, Kinetics__Days_before_First_Reminder__c, Kinetics__Days_between_two_reminders__c, Kinetics__GUID__c, Kinetics__Contact__c, 
                                                                Kinetics__Kinetic_Job__c, Kinetics__Send_Auto_Reminders__c, Kinetics__Stage__c, Kinetics__Kinetic_Form__c, Kinetics__TTL_Day__c, Kinetics__Last_Reminder_Sent_Date__c,
                                                                Kinetics__Reminder_Sent_count__c, Kinetics__Channel__c, CreatedDate 
                                                            FROM Kinetics__Survey_Invitation__c 
                                                            WHERE Kinetics__Stage__c != :stageToSkip 
                                                            AND Kinetics__GUID__c != null AND Kinetics__Contact__c != null AND Kinetics__Kinetic_Form__c != null AND Kinetics__Kinetic_Job__c != null 
                                                            AND Kinetics__Send_Auto_Reminders__c = true
                                                            AND Id IN :invitationRecordIdList];
        for(Kinetics__Survey_Invitation__c sinvitation: invitationList) {
            if(SeqReminderSenderBatchHelper.isValidForInvitation(sinvitation)
                && sinvitation.Kinetics__Channel__c == GlobalConstants.channelSMS
                && SeqReminderSenderBatchHelper.doSendReminder(sinvitation)) {
                    
                    //set stage of invitation to 'Sent to Receipient' so that process builder will send the invite sms again
                    sinvitation.Kinetics__Stage__c = GlobalConstants.sentToRecipientStage;
                    if(sinvitation.Kinetics__Reminder_Sent_count__c == null) {
                        sinvitation.Kinetics__Reminder_Sent_count__c = 0;
                    }
                    sinvitation.Kinetics__Reminder_Sent_count__c = sinvitation.Kinetics__Reminder_Sent_count__c + 1;
                    sinvitation.Kinetics__Last_Reminder_Sent_Date__c = Date.today();
                    recordsToUpdate.add(sinvitation);
            } else if (SeqReminderSenderBatchHelper.isValidForInvitation(sinvitation)
                && sinvitation.Kinetics__Channel__c == GlobalConstants.channelEMAIL
                && SeqReminderSenderBatchHelper.doSendReminder(sinvitation)) {
                //implement the email reminder sending
                    //set stage of invitation to 'Sent to Receipient' so that process builder will send the invite sms again
                    sinvitation.Kinetics__Stage__c = GlobalConstants.sentToRecipientStage;
                    if(sinvitation.Kinetics__Reminder_Sent_count__c == null) {
                        sinvitation.Kinetics__Reminder_Sent_count__c = 0;
                    }
                    sinvitation.Kinetics__Reminder_Sent_count__c = sinvitation.Kinetics__Reminder_Sent_count__c + 1;
                    sinvitation.Kinetics__Last_Reminder_Sent_Date__c = Date.today();
                    recordsToUpdate.add(sinvitation);
            }
        }
        
        List<Schema.DescribeFieldResult> surveyinvitationFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Survey_Invitation__c.Kinetics__Stage__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Reminder_Sent_count__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Last_Reminder_Sent_Date__c.getDescribe()
        };

        if(CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c)
            && CheckUserPermission.checkFieldsUpdateAccess(surveyinvitationFieldList)) {   
            if(recordsToUpdate.size() > 0) {
                update recordsToUpdate;
            }
        }
    }
}