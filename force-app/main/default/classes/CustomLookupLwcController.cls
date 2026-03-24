public class CustomLookupLwcController {
    // Method to fetch lookup search result   
     @AuraEnabled(cacheable=true)
     public static list<sObject> fetchLookupData(string searchKey , string sObjectApiName) {    
        List < sObject > returnList = new List < sObject > ();
        String processTypeValue = 'AutoLaunchedFlow';
        String processType_Screenflow_Value = 'Flow';
        string sWildCardText = '%' + searchKey + '%';
        string sQuery;
        if(sObjectApiName == 'FlowDefinitionView'){
            sQuery = 'Select Id, Label , ApiName, NamespacePrefix From ' + sObjectApiName + ' Where Label Like : sWildCardText and ProcessType =: processTypeValue LIMIT 5';
        }else{
            sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText order by createdDate DESC LIMIT 5';
        }    
        for (sObject obj: database.query(sQuery)) {
            returnList.add(obj);
        }
        return returnList;
     }

     @AuraEnabled(cacheable=true)
     public static list<sObject> fetchLookupDataForFlowObj(String searchKey , string sObjectApiName) {    
        List < sObject > returnList = new List < sObject > ();
        String processType_Screenflow_Value = 'Flow';
        string sWildCardText = '%' + searchKey + '%';
        string sQuery;
        if(sObjectApiName == 'FlowDefinitionView'){
            sQuery = 'Select Id, Label , ApiName, NamespacePrefix From ' + sObjectApiName + ' Where Label Like : sWildCardText and (ProcessType =: processType_Screenflow_Value) LIMIT 5';
        }else{
            sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText order by createdDate DESC LIMIT 5';
        }    
        for (sObject obj: database.query(sQuery)) {
            returnList.add(obj);
        }
        return returnList;
     }
     // Method to fetch lookup default value 
     @AuraEnabled
     public static sObject fetchDefaultRecord(string recordId , string sObjectApiName) {
         string sRecId = recordId;  
         string sQuery;
         if(sObjectApiName == 'FlowDefinitionView'){
            sQuery = 'Select Id, ApiName, Label, NamespacePrefix From ' + sObjectApiName + ' Where ApiName = : sRecId LIMIT 1';
         }else{
            sQuery = 'Select Id, Name From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
         }
         
         for (sObject obj: database.query(sQuery)) {
             return obj;
         }
         return null;
     }
     
 }