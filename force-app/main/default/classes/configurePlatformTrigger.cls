/***
* Author: Shankar Dupade (FieldKo)
* Updated : 30th Aug 2021
* Purpose: Helpr class to configure automated process user for Platform Event triggers
*/
global with sharing class configurePlatformTrigger {
    
    //SELECT Id,DeveloperName,BatchSize,PlatformEventConsumerId,UserId FROM PlatformEventSubscriberConfig

    global static HttpResponse setRunningUserForKineticInviteReminderTrigger(String requireUserId) {

        List<ApexTrigger> apexTriggerList = [SELECT Id
                                                FROM ApexTrigger 
                                                WHERE NamespacePrefix = 'Kinetics' 
                                                AND Name = 'KineticInviteReminderTrigger' 
                                                AND TableEnumOrId = 'Kinetics__Kinetic_Invite_Reminder__e' 
                                                AND Status = 'Active' limit 1];
        String triggerId = apexTriggerList.size() > 0? apexTriggerList[0].Id : null;
        if(triggerId == null) {
            return null;
        }
        String instanceName = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());//[select InstanceName from Organization limit 1].InstanceName;

        String requestPayload = '{"BatchSize": "100","DeveloperName":"KineticInviteReminderTriggerConfig","MasterLabel":"KineticInviteReminderTriggerConfig","PlatformEventConsumerId": "'+ triggerId +'","UserId": "'+requireUserId +'"}';
        String httpMethod = 'POST';
        String instanceHost = instanceName ;
        String endPoint = instanceHost + '/services/data/v52.0/tooling/sobjects/PlatformEventSubscriberConfig';
        Map<String, String> requestHeader = new Map<String, String>();
        requestHeader.put('Content-Type', 'application/json');
        requestHeader.put('Authorization', 'Bearer ' + UserInfo.getSessionID());
        HttpResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeader);
        return res;
    }

    global static HttpResponse setRunningUserForKineticInviteJobTrigger(String requireUserId) {

        List<ApexTrigger> apexTriggerList = [SELECT Id
                                                FROM ApexTrigger 
                                                WHERE NamespacePrefix = 'Kinetics' 
                                                AND Name = 'KineticJobInviteTrigger' 
                                                AND TableEnumOrId = 'Kinetics__Kinetics_Jobs_Invites__e' 
                                                AND Status = 'Active' limit 1];
        String triggerId = apexTriggerList.size() > 0? apexTriggerList[0].Id : null;
        if(triggerId == null) {
            return null;
        }
        String instanceName = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());//[select InstanceName from Organization limit 1].InstanceName;

        String requestPayload = '{"BatchSize": "100","DeveloperName":"KineticInviteJobTriggerConfig","MasterLabel":"KineticInviteJobTriggerConfig","PlatformEventConsumerId": "'+ triggerId +'","UserId": "'+requireUserId +'"}';
        String httpMethod = 'POST';
        String instanceHost = instanceName ;
        String endPoint = instanceHost + '/services/data/v52.0/tooling/sobjects/PlatformEventSubscriberConfig';
        Map<String, String> requestHeader = new Map<String, String>();
        requestHeader.put('Content-Type', 'application/json');
        requestHeader.put('Authorization', 'Bearer ' + UserInfo.getSessionID());
        HttpResponse res = HttpRequestService.doRequest(requestPayload, httpMethod, endPoint, requestHeader);
        return res;
    }
}