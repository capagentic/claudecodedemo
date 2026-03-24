public with sharing class InspSpreadsheetController {

    @AuraEnabled
    public static String getHeader(String inspId){
        System.debug('******* inspId=' + inspId);
        // String column = '[{"label":"Inspection","fieldName":"date","wrapText":true,"editable":true, "type":"date"},{"label":"Outside - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Outside - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Unaffected - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Unaffected - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Chamber 1 - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Chamber 1 - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Dehu - Chamber 1 - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Dehu - Chamber 1 - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Outside - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Outside - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Chamber 2 - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Chamber 2 - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Dehu - Chamber 2 - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Dehu - Chamber 2 - RH%","fieldName":"name","wrapText":true,"editable":true}]';
        //String column = '[{"label":"Inspection","fieldName":"date","wrapText":true,"editable":true,"type":"date"},{"label":"Outside-°F","fieldName":"name","wrapText":true,"editable":true},{"label":"Outside-RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Unaffected-°F","fieldName":"name","wrapText":true,"editable":true},{"label":"Unaffected-RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Chamber 1-°F","fieldName":"name","wrapText":true,"editable":true}]';
        Response res = new Response();
        res.statusCode = 2000;
        res.responseMessage ='';
        res.responseDetails = new Map<String, String>();

        List<Kinetics__Inspection__c> inspesList = [SELECT Id, Name, Kinetics__Spreadsheet_Configuration__c 
                                                        FROM Kinetics__Inspection__c 
                                                        WHERE ID = :inspId
                                                        LIMIT 1];
        if(inspesList.size() == 0) {
            res.statusCode = 2001;
            res.responseMessage = 'Inspection Not found';
            return JSON.serialize(res);
        }

        List<Kinetics__Spreadsheet_Configuration__c> spreadSheetConfList = [SELECT Id, Name, Kinetics__Row_Metadata__c, Kinetics__Object_API_Name__c, Kinetics__Instructions__c 
                                                                        FROM Kinetics__Spreadsheet_Configuration__c 
                                                                        WHERE Id = :inspesList[0].Kinetics__Spreadsheet_Configuration__c
                                                                        LIMIT 1];


        Map<String, Object> responseMap = new Map<String, Object>();
        List<Map<String, String>> columnsList = new List<Map<String, String>>();
        List<columnConf> columnConfList = new List<columnConf>();
        for(Kinetics__Spreadsheet_Configuration__c sc: spreadSheetConfList) {
            List<Object> rowMetadataListRaw = (List<Object>)JSON.deserializeUntyped(sc.Kinetics__Row_Metadata__c);
            for(Object rowMetadataObj: rowMetadataListRaw) {
                 Map<String,Object> rowMetadata = (Map<String,Object>)rowMetadataObj;
                if(rowMetadata.containsKey('columnWrapperList')) {
                    List<Object> columnWrapperListObj = (List<Object> )rowMetadata.get('columnWrapperList');
                    for(Object columnWrapperObj: columnWrapperListObj){
                        Map<String, Object> columnWrapper = (Map<String, Object>)columnWrapperObj;
                        columnConf cconf = new columnConf();
                        cconf.label = columnWrapper.containsKey('label')? (String)columnWrapper.get('label') : '';
                        cconf.fieldName = columnWrapper.containsKey('fieldName')? (String)columnWrapper.get('fieldName') : '';
                        cconf.wrapText = columnWrapper.containsKey('wrapText')? (Boolean)columnWrapper.get('wrapText') : false;
                        cconf.editable = columnWrapper.containsKey('editable')? (Boolean)columnWrapper.get('editable') : false;
                        cconf.type = columnWrapper.containsKey('type')? (((String)columnWrapper.get('type')).toLowerCase()) : 'text';
                        columnConfList.add(cconf);
                    }
                    break;
                }
            }
        }

        SpreadsheetConf sc = new SpreadsheetConf();
        sc.confName = spreadSheetConfList[0].Name;
        sc.instructions = spreadSheetConfList[0].Kinetics__Instructions__c;
        sc.objectName = spreadSheetConfList[0].Kinetics__Object_API_Name__c;
        responseMap.put('SpreadsheetConf', sc);
        
        responseMap.put('column', columnConfList);
        
        res.responseDetails = responseMap;
        res.responseMessage = 'sucess';
        return JSON.serialize(res);

    }

    @AuraEnabled
    public static String createCustomObjectRecord(String inspId, String newRecordListString, String updatedRecordListString){
        System.debug('******* inspId=' + inspId);
        // String column = '[{"label":"Inspection","fieldName":"date","wrapText":true,"editable":true, "type":"date"},{"label":"Outside - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Outside - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Unaffected - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Unaffected - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Chamber 1 - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Chamber 1 - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Dehu - Chamber 1 - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Dehu - Chamber 1 - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Outside - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Outside - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Chamber 2 - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Chamber 2 - RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Dehu - Chamber 2 - °F","fieldName":"name","wrapText":true,"editable":true},{"label":"Dehu - Chamber 2 - RH%","fieldName":"name","wrapText":true,"editable":true}]';
        //String column = '[{"label":"Inspection","fieldName":"date","wrapText":true,"editable":true,"type":"date"},{"label":"Outside-°F","fieldName":"name","wrapText":true,"editable":true},{"label":"Outside-RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Unaffected-°F","fieldName":"name","wrapText":true,"editable":true},{"label":"Unaffected-RH%","fieldName":"name","wrapText":true,"editable":true},{"label":"Chamber 1-°F","fieldName":"name","wrapText":true,"editable":true}]';
        Response res = new Response();
        res.statusCode = 2000;
        res.responseMessage ='';
        res.responseDetails = new Map<String, String>();

        List<Kinetics__Inspection__c> inspesList = [SELECT Id, Name, Kinetics__Spreadsheet_Configuration__c,
                                                    Kinetics__Spreadsheet_Configuration__r.Kinetics__Object_API_Name__c
                                                        FROM Kinetics__Inspection__c 
                                                        WHERE ID = :inspId
                                                        LIMIT 1];
        if(inspesList.size() == 0) {
            res.statusCode = 2001;
            res.responseMessage = 'Inspection Not found';
            return JSON.serialize(res);
        }

        List<Map<String,String>> newRecordList = new List<Map<String, String>>();
        List<Map<String,String>> updatedRecordList = new List<Map<String, String>>();

        newRecordList = (List<Map<String, String>>) JSON.deserialize(newRecordListString, List<Map<String, String>>.class);
        updatedRecordList = (List<Map<String, String>>) JSON.deserialize(updatedRecordListString, List<Map<String, String>>.class);
        system.debug('****** updatedRecordList=' + updatedRecordList);
        if(String.isBlank(inspesList[0].Kinetics__Spreadsheet_Configuration__r.Kinetics__Object_API_Name__c)) {
            res.statusCode = 2001;
            res.responseMessage = 'Object Name not configured';
            return JSON.serialize(res);
        }
        List<Map<String, String>> listOfRecordsToUpsert = new List<Map<String, String>>();
        listOfRecordsToUpsert.addAll(newRecordList);
        listOfRecordsToUpsert.addAll(updatedRecordList);

        List<sObject> listOfSObject = new List<sObject>(); 
        for(Map<String, String> recordMap : listOfRecordsToUpsert) {
            sObject so = (sObject)Type.forName(inspesList[0].Kinetics__Spreadsheet_Configuration__r.Kinetics__Object_API_Name__c).newInstance();
            String a_Object_API_Name = inspesList[0].Kinetics__Spreadsheet_Configuration__r.Kinetics__Object_API_Name__c;
            Map<String, Schema.SObjectField> M_Objects_Schema_Field = Schema.getGlobalDescribe().get(a_Object_API_Name).getDescribe().fields.getMap();
            Map<String, String> dataTypeByFieldAPIName = new Map<String, String>();

            for( String a_Field_Name : M_Objects_Schema_Field.keySet() ) {
                
                Schema.DescribeFieldResult a_Field_Description = M_Objects_Schema_Field.get( a_Field_Name ).getDescribe();
                dataTypeByFieldAPIName.put(a_Field_Description.getName(), String.valueOf(a_Field_Description.getType()));
            }

            for(String key : recordMap.keySet()) {
                String value = recordMap.get(key);
system.debug('**** key=' + key);
system.debug('**** value=' + value);
                if(value.isNumeric()) {
                    so.put(key, Decimal.valueOf(value));
                } else if(key =='Kinetics__Inspection_Date_Time__c') {
                    so.put(key, Date.valueOf(value));
                } else if( key == 'localKey' ){
                    if(dataTypeByFieldAPIName.containsKey('Kinetics__Reference_ID__c')) {
                        so.put('Kinetics__Reference_ID__c', value);
                    }
                }else if(String.isBlank(value)){
                    so.put(key, null);
                }else {
                    if(dataTypeByFieldAPIName.containsKey(key) 
                        && dataTypeByFieldAPIName.get(key) == 'TIME'){
                            Datetime dt = (Datetime) JSON.deserialize('"' + value + '"', Datetime.class);

                            so.put(key, dt.time());
                    } else if(dataTypeByFieldAPIName.containsKey(key) 
                        && dataTypeByFieldAPIName.get(key) == 'DATE'){
                            
                            Datetime dt = (Datetime) JSON.deserialize('"' + value + '"', Datetime.class);

                            so.put(key, dt.date());
                    }
                    else {
                        so.put(key, value);
                    }
                }
            }
            if(dataTypeByFieldAPIName.containsKey('Kinetics__Inspection__c')) {
                so.put('Kinetics__Inspection__c', inspId);
            }
            listOfSObject.add(so);
        }
system.debug('listOfSObject: ' + JSON.serialize(listOfSObject));
        upsert listOfSObject;

        // if(){

        // }


        res.responseMessage = 'sucess';
        res.responseDetails = listOfSObject;
        return JSON.serialize(res);

    }

    @AuraEnabled
    public static String getSpreadsheetData(){
        List<Map<String, String>> ssData = new List<Map<String, String>>();
        
        // create dummy data for now
        Date today = System.today();
        for(Integer i = 0; i < 5; i++){
            Map<String, String> sRow = new Map<String, String>();
            sRow.put('date', today.adddays(i) + '');
            sRow.put('name', ' ');
            ssData.add(sRow);
        }

        Response res = new Response();
        res.statusCode = 2000;
        res.responseMessage = 'sucess';
        res.responseDetails = ssData;

        return JSON.serialize(res);

    }

    public class Response{
        Integer statusCode;
        String responseMessage;
        Object responseDetails;
    }
    public class SpreadsheetConf {
        public String confName;
        public String instructions;
        public String objectName;
    }
    public class columnConf {
        public String label;
        public String fieldName;
        public String type;
        public Boolean wrapText;
        public Boolean editable;
    }
}