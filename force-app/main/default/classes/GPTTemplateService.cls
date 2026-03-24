public with sharing class GPTTemplateService {
    
    @InvocableMethod(label='Parse GPT Parameters' description='Parse GPT parameters and save values into salesforce fields on the template record' category='Template')
    public static void parseGPTParams(List<ID> templateID) {
        try{
            List<Kinetic_Form__c> templates = [SELECT ID, Chat_GPT_Parameters__c 
                                            FROM  Kinetic_Form__c
                                            WHERE ID =: templateID];

            Kinetic_Form__c t; 
            if(!templates.isEmpty()){
                t = templates.get(0);
                if(String.isBlank(t.Chat_GPT_Parameters__c)){
                    return;
                }
            }

            Map<String, String> gptParamMap = (Map<String, String>) JSON.deserialize(t.Chat_GPT_Parameters__c, Map<String, String>.class);
            t.Applicable_Standards_GPT__c = gptParamMap.get('applicableStandards');
            t.Inspection_Objective_GPT__c = gptParamMap.get('inspectionobjective');
            t.Is_Checklist_Needed_GPT__c = gptParamMap.get('checklistneed');
            t.User_Role_GPT__c = gptParamMap.get('yourrole');
            update t;
        }catch(Exception ex){
            system.debug('GPTTemplateService>parseGPTParams>ex message:' + ex.getMessage());
        }
        

    }
}