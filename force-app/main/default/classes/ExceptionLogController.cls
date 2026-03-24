/**
 * Author: Shankar Dupade (FieldKo)
 * Date: 10-09-2021
 * Purpose: Controller for handling Exceptions
 */
public with sharing class ExceptionLogController {
    
    public static void logException(List<ExceptionWrapper> errorList) {
        List<Kinetics__Exception_Log__c> exceptionLogList = new List<Kinetics__Exception_Log__c>();
        for(ExceptionWrapper ewr: errorList) {
            Kinetics__Exception_Log__c el = new Kinetics__Exception_Log__c();
            el.Affected_Record_Id__c = ewr.affectedRecordId;
            el.Method_Name__c = ewr.methodName;
            el.Error_Message__c = ewr.errorString;
            el.StackTrace__c = ewr.stackTrace;
            el.Error_Cause__c = ewr.errorCause;
            exceptionLogList.add(el);
        }
        if(exceptionLogList.size() > 0 ){
            insert exceptionLogList;
        }
    }

    public class ExceptionWrapper {
        public String methodName;
        public String errorString;
        public String stackTrace;
        public String errorCause;
        public String affectedRecordId;
    }
}