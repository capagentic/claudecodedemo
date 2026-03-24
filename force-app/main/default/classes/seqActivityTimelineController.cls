public with sharing class seqActivityTimelineController {
    @AuraEnabled
    public static string getSurveyInvitationsForContact(String contactId){
        List<Schema.DescribeFieldResult> surveyInvitationFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Survey_Invitation__c.Kinetics__Channel__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Contact__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Stage__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Form__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__TTL_Day__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__GUID__c.getDescribe()
        };

        if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
            && CheckUserPermission.checkFieldsReadAccess(surveyInvitationFieldList))) {
                throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }

        List<Kinetics__Survey_Invitation__c> siList = [SELECT Id, Name, Kinetics__Channel__c, Kinetics__Contact__c, Kinetics__Contact__r.Name, Kinetics__Stage__c, Kinetics__Kinetic_Form__c,Kinetics__Kinetic_Form__r.Name, Kinetics__TTL_Day__c, Kinetics__GUID__c, CreatedDate, LastModifiedDate
                                            FROM Kinetics__Survey_Invitation__c WHERE Kinetics__Contact__c = :contactId ORDER BY LASTMODIFIEDDATE DESC];
        return JSON.serialize(siList);
    }

    @AuraEnabled
    public static string updateSurveyInvitation(String surveyInvitationId, String newstage){
        List<Schema.DescribeFieldResult> surveyInvitationFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Survey_Invitation__c.Kinetics__Stage__c.getDescribe()
        };

        if(!(CheckUserPermission.checkObjectUpdateAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
            && CheckUserPermission.checkFieldsUpdateAccess(surveyInvitationFieldList))) {
                throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }
        Kinetics__Survey_Invitation__c siRecord = new Kinetics__Survey_Invitation__c(Id=surveyInvitationId, Kinetics__Stage__c=newstage);
        update siRecord;
        return siRecord.Id;
    }
}