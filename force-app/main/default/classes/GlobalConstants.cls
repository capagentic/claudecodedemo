/***
* Author: Shankar Dupade (FieldKo)
* Updated : 17th Aug 2021
* Purpose: Global Constant class to capture constant variables
*/
public with sharing class GlobalConstants {
    
    public static String sentToRecipientStage = 'Sent to recipient';
    public static String inProgressStage = 'In Progress';
    public static String expiredStage = 'Expired';
    public static String completedStage = 'Completed';
    public static String partiallyCompletedStage = 'Partially Completed';

    public static String jobNewStatus = 'New';
    public static String jobInProgressStatus = 'In Progress';
    public static String jobCompletedStatus = 'Completed';
    
    public static String channelSMS = 'SMS';
    public static String channelEMAIL = 'Email';

    public static String deliveryMethodSMS = 'Sms';
    public static String deliveryMethodEMAIL = 'Email';
    
    public static String googleapisBaseUrl = 'https://maps.googleapis.com';
    public static String geocodeAPIURL = GlobalConstants.googleapisBaseUrl+ '/maps/api/geocode/json';

    public static String surveyNotFoundMessage = 'The sequence you are requesting can not be found;';
    public static String surveyExpiredMessage = 'The sequence you are requesting has been expired.';
    public static String surveyCompletedMessage = 'The sequence you are requesting has been completed.';
    public static String surveyInstructionMessage = 'You are invited for survey';
    public static String emailTemplateNotFoundMessage = 'The email template can not be found.';
    
    public static String eventSubjectMessage = 'Kinetic Link - ';

    public static String allowedQuestionsLimitExceededString = System.Label.allowedQuestionsLimitExceededString;
    public static String allowedSMSEmailLimitExceededString = System.Label.allowedSMSEmailLimitExceededString;
}