global inherited sharing class SeqRendererWithFlowHelper {

    global static String getRelatedParentRecordIdBySurveyGuid(String surveyGUID, String objectName){
        
        System.debug('****** surveyGUID=' + surveyGUID);
        List<Schema.DescribeFieldResult> surveyInvitationFieldList = new List<Schema.DescribeFieldResult>{
            Kinetics__Survey_Invitation__c.Kinetics__GUID__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Stage__c.getDescribe(),
            Kinetics__Survey_Invitation__c.Kinetics__Kinetic_Form__c.getDescribe()
        };
        
        if(!(CheckUserPermission.checkObjectReadAccess(Schema.sObjectType.Kinetics__Survey_Invitation__c) 
            && CheckUserPermission.checkFieldsReadAccess(surveyInvitationFieldList))) {
            throw new AuraHandledException(System.Label.Kinetics.You_do_not_have_valid_permissions_to_perform_this_operation);
        }
        
        
        List<Kinetics__Kinetic_Link_Recipient_Configuration__mdt> confList = GlobalUtility.getRequiredRecordForSurveyInvitaion(objectName);

        if(confList.size()  == 0) {
            return null;
        }

        Kinetics__Kinetic_Link_Recipient_Configuration__mdt confObj = confList[0];

        String queryString = 'SELECT Id ';
        if(String.isNotBlank(confObj.Kinetics__Relationship_Field_API_Name__c)) {
            queryString = queryString + ', ' + confObj.Kinetics__Relationship_Field_API_Name__c;
        }

        queryString = queryString + ' FROM Kinetics__Survey_Invitation__c WHERE Kinetics__GUID__c = :surveyGUID LIMIT 1';

        List<sObject> invites = Database.query(queryString);

        if(invites.size() == 0) {
            return null;
        }
        sObject sinvite = invites[0];
        if(String.isNotBlank(confObj.Kinetics__Relationship_Field_API_Name__c) 
            && sinvite.get(confObj.Kinetics__Relationship_Field_API_Name__c) != null) {
            return String.valueOf(sinvite.get(confObj.Kinetics__Relationship_Field_API_Name__c));
        }

        return null;
    }
}