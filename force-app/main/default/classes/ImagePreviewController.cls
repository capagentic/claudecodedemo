/**
 * Author: Shankar Dupade
 * Date: 06-09-2021
 * Purpose: show image in large from the record page
 * 
 */
public with sharing class ImagePreviewController {
   @AuraEnabled
    public static string getImageURLForRelatedRecord(String objectAPIName, String recordId, String urlFieldName){
        try {
            if(String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID can not be blank');
            }
            if(String.isBlank(objectAPIName)) {
                throw new AuraHandledException('objectAPIName can not be blank');
            }

            if(String.isBlank(urlFieldName)) {
                throw new AuraHandledException('urlFieldName can not be blank');
            }
            
            String queryString = 'SELECT ID, '+ String.escapeSingleQuotes(urlFieldName) + ' FROM ' + String.escapeSingleQuotes(objectAPIName) + ' WHERE ID = :recordId LIMIT 1';
            List<sObject> sObjectList = Database.query(queryString);
            if(sObjectList.size() == 0) {
                throw new AuraHandledException('No records found');
            }
            String urlFieldValue = '';
            for(sObject so: sObjectList) {
                if(so.get(urlFieldName) != null) {
                    urlFieldValue = String.valueOf(so.get(urlFieldName));
                    break;
                }
            }
            return urlFieldValue;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
 }