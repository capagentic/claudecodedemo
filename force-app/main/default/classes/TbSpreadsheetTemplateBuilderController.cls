/**
 * Author: Shankar Dupade (shankar.dupade@fieldko.com)
 * Date: 23-11-2023
 * Purpose: Controller class for Spreadsheet Builder
 */

public with sharing class TbSpreadsheetTemplateBuilderController {
   
    @AuraEnabled
    public static string getObjectAndFieldMapping(){
        try {
            List<Map<String, String>> objectList = new List<Map<String, String>>();
            Map<String, List<FieldWrapper>> objFieldsMap = new Map<String, List<FieldWrapper>>();
            
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
            Set<String> allowedObjectNameList = new Set<String>();
            allowedObjectNameList.add('Account');
            allowedObjectNameList.add('Contact');
            allowedObjectNameList.add('Lead');

            for(Schema.SObjectType d : gd.values())
            {
                Schema.DescribeSObjectResult ds = d.getDescribe();
                if(!ds.isCustomSetting() 
                    && ((ds.isCustom() && ds.getName().endsWith('__c')) || allowedObjectNameList.contains(ds.getName()))) {

                    

                    Map<String, Schema.SObjectField > mapFieldList = ds.fields.getMap();
                    List<FieldWrapper> fieldWrapperList = new List<FieldWrapper>();
                    for ( Schema.SObjectField field : mapFieldList.values() ) {    
                    
                        Schema.DescribeFieldResult fieldResult = field.getDescribe();
                        if(fieldResult.getName().endsWith('__c') || fieldResult.getName().toLowerCase() == 'name'){                        
                            FieldWrapper fw = new FieldWrapper();
                            fw.fieldName = fieldResult.getName();
                            fw.fieldLabel = fieldResult.getLabel();
                            
                            fw.fieldType = String.valueOf(fieldResult.getType());
                            
                            fieldWrapperList.add(fw);
                        }
                    }
                    objFieldsMap.put(ds.getName(), fieldWrapperList);

                    Map<String, String> obj = new Map<String, String>();
                    // obj.put(ds.getLabel(), ds.getName());
                    obj.put('label', ds.getLabel());
                    obj.put('value', ds.getName());
                    objectList.add(obj);
                }
            }

            Map<String, Object> resultWrapper = new Map<String, Object>();
            resultWrapper.put('objectList', objectList);
            resultWrapper.put('objFieldsMap', objFieldsMap);

            return JSON.serialize(resultWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class FieldWrapper {
        public String fieldLabel;
        public String fieldName;
        public String fieldType;

    }
}