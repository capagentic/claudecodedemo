/**
 * Author: Shankar Dupade
 * Purpose: controller class to support setup assistance functionality
 * Date: 29-11-2021
 *
 */
public with sharing class seqSetupAssistantController {
//This class implementation is in progress when package was created, thats why the code is commentted


    // @AuraEnabled
    // public static string getKineticCustomSettingMetadataDetails(){
    //     Map<String, String> describeResultsByApiName = new Map<String, String>();
    //     try {
    //         Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(
    //                                                                new String[]{'Kinetics__FieldKo_Kinetics_Setting__c'});

    //         Schema.DescribeSObjectResult objdescResult = descResult[0];
    //         describeResultsByApiName.put('settingkeyPrefix', objdescResult.getKeyPrefix());
    //         describeResultsByApiName.put('settinglabel', objdescResult.getLabel());
    //         describeResultsByApiName.put('settingcreatepermission', ''+objdescResult.isCreateable());
    //         describeResultsByApiName.put('settingupdatepermission', ''+objdescResult.isUpdateable());
    //         describeResultsByApiName.put('createeventhelptext', Kinetics__FieldKo_Kinetics_Setting__c.Kinetics__Create_Event__c.getDescribe().getInlineHelpText());
    //         describeResultsByApiName.put('createeventlabel', Kinetics__FieldKo_Kinetics_Setting__c.Kinetics__Create_Event__c.getDescribe().getLabel());
    //         describeResultsByApiName.put('googleapikeyhelptext', Kinetics__FieldKo_Kinetics_Setting__c.Kinetics__Google_API_Key__c.getDescribe().getInlineHelpText());
    //         describeResultsByApiName.put('googleapikeylabel', Kinetics__FieldKo_Kinetics_Setting__c.Kinetics__Google_API_Key__c.getDescribe().getLabel());
    //         describeResultsByApiName.put('formrendereurlhelptext', Kinetics__FieldKo_Kinetics_Setting__c.Kinetics__Form_Renderer_Page_URL__c.getDescribe().getInlineHelpText());
    //         describeResultsByApiName.put('formrendereurllabel', Kinetics__FieldKo_Kinetics_Setting__c.Kinetics__Form_Renderer_Page_URL__c.getDescribe().getLabel());
    //         describeResultsByApiName.put('smstemplatehelptext', Kinetics__FieldKo_Kinetics_Setting__c.Kinetics__SMS_Template__c.getDescribe().getInlineHelpText());
    //         describeResultsByApiName.put('smstemplatelabel', Kinetics__FieldKo_Kinetics_Setting__c.Kinetics__SMS_Template__c.getDescribe().getLabel());

    //         return JSON.serialize(describeResultsByApiName);
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    // @AuraEnabled
    // public static string getKineticCustomSettingRecordDetails(){
    //     try {
    //         String kineticsRecord = JSON.serialize(Kinetics__FieldKo_Kinetics_Setting__c.getOrgDefaults());
    //         return kineticsRecord;
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    // @AuraEnabled
    // public static string getPermissionSetIds(){
    //     try {
    //         Map<String, String> permissionSetIdByName = new Map<String, String>();
    //         for(PermissionSet pSet : [SELECT Id, Name FROM PermissionSet 
    //                                                 WHERE Name IN ('Kinetics_Admin_User_Permissions','Kinetics_Guest_User_Permissions') ORDER BY Name]) {
    //             permissionSetIdByName.put(pSet.Name, pSet.Id);
    //         }
    //         return JSON.serialize(permissionSetIdByName);
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    // @AuraEnabled
    // public static string setRunningUserForPlatformEvent(String userId){
    //     try {
    //         configurePlatformTrigger.setRunningUserForKineticInviteJobTrigger(userId);
    //         configurePlatformTrigger.setRunningUserForKineticInviteReminderTrigger(userId);
    //         return 'success';
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }
    // @AuraEnabled
    // public static string getRunningUserForPlatformEvent(){
    //     try {
    //         List<String> userIdList = new List<String>();
    //         // for(PlatformEventSubscriberConfig pesconfig :[SELECT Id,DeveloperName,BatchSize,PlatformEventConsumerId,UserId FROM PlatformEventSubscriberConfig WHERE DeveloperName IN ('KineticInviteReminderTriggerConfig', 'KineticInviteJobTriggerConfig')]){
    //         //     userIdList.add(pesconfig.UserId);
    //         // }

    //         Map<String, String> userDetailsMap = new Map<String, String>();
    //         // for(User u: [SELECT Id, Name FROM User WHERE Id IN :userIdList AND isActive = true]) {
    //         //     userDetailsMap.put('userId', u.Id);
    //         //     userDetailsMap.put('userName', u.Name);
    //         // }
    //         userDetailsMap.put('userId', '0055g00000BV93c');
    //         userDetailsMap.put('userName', 'Jeffrey Busch');
    //         return JSON.serialize(userDetailsMap);
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }


}