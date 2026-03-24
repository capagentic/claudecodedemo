/**
 * Author: Shankar Dupade
 * Purpose: controller class for creating assistants from OpenAI
 * Date: 13-2-2024
 */
public with sharing class AsstCreateAssistantsController {
    
    @AuraEnabled
    public static string createAssistants(){
        try {

            List<Kinetics__Assistant__c> assistantsList = [SELECT Id, Name, Kinetics__ChatGPT_Id__c FROM Kinetics__Assistant__c];
            Map<String, Kinetics__Assistant__c> assistantMap = new Map<String, Kinetics__Assistant__c>();
            for(Kinetics__Assistant__c asst: assistantsList) {
                assistantMap.put(asst.Kinetics__ChatGPT_Id__c, asst);
            }

            List<Kinetics__Assistant__c> assistantList = new List<Kinetics__Assistant__c>();
            String allAssistantResponse = ProcessCallTranscriptionHomeController.getAllAvailableAssistants();
            AssistantsListAPIResponse assistantResponseWrapper = (AssistantsListAPIResponse) JSON.deserialize(allAssistantResponse, AssistantsListAPIResponse.class);
            for(AssistantsListAPIResponse.Data dataobj : assistantResponseWrapper.data) {
                Kinetics__Assistant__c assistantObj = new Kinetics__Assistant__c();
                if(assistantMap.containsKey(dataobj.id)) {
                    assistantObj.Id = assistantMap.get(dataobj.id).Id;
                }

                assistantObj.Kinetics__ChatGPT_Id__c = dataobj.id;
                assistantObj.Kinetics__Instructions__c = dataobj.instructions;
                assistantObj.Kinetics__Model__c = dataobj.model;
                assistantObj.Name = dataobj.name;
                assistantObj.Kinetics__File_Ids__c = JSON.serialize(dataobj.file_ids);
                assistantObj.Kinetics__Code_Interpreter__c = false;
                assistantObj.Kinetics__Retrieval__c = false;
               // assistantObj.function = false;

                for(Integer j=0;j<dataobj.tools.size(); j++) {
                    if(dataobj.tools[j].type == 'code_interpreter') {
                        assistantObj.Kinetics__Code_Interpreter__c = true;
                    }
                    if(dataobj.tools[j].type == 'retrieval') {
                        assistantObj.Kinetics__Retrieval__c = true;
                    }
                    //if(dataobj.tools[j].type == 'function') {
                    //     assistantObj.function = true;
                    // }
                }
                assistantList.add(assistantObj);
            }
            upsert assistantList;
            return 'done';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}