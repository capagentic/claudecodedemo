public class InspFlowService {
    
    public static void callFlow(){
        
    }

    @AuraEnabled
    public static List<Map<String, String>> getFlows(){
        List<FlowDefinitionView> flows = [SELECT id, ApiName, Label, ProcessType 
                                            FROM FlowDefinitionView 
                                            WHERE ProcessType = 'AutoLaunchedFlow' AND IsActive = true];
        List<Map<String, String>> options = new List<Map<String, String>>();
        for(FlowDefinitionView f: flows){
            Map<String, String> flowOption = new Map<String, String>();
            flowOption.put('label', f.Label);
            flowOption.put('value', f.ApiName);

            options.add(flowOption);
        }

        return options;
    }

    @InvocableMethod(label='Invoke pre-defined flows based on answers from an inspection' description='Invoke pre-defined flows based on answers from an inspection')
    public static void callFlows(List<Id> inspectionRecList) {
        

        String inspId = inspectionRecList.get(0);

        List<Kinetics__Kinetic_Form_Answer__c> answers = [SELECT Id, Kinetics__Answer__c, Kinetics__Dependent_Flows__c
                                                                    FROM Kinetics__Kinetic_Form_Answer__c
                                                                    WHERE Kinetics__Inspection__c = :inspId];

        Map<String, Object> params = new Map<String, Object>();
        params.put('recordId',inspId);
        for(Kinetics__Kinetic_Form_Answer__c ans: answers){
            String flowMapString = ans.Kinetics__Dependent_Flows__c;
            String answerString = ans.Kinetics__Answer__c;
            system.debug('***** flowMapString=' + flowMapString);
            Map<String, String> flowMap = convertString2Map(flowMapString);

            for(String a :flowMap.keySet()){
                system.debug('***** a=' + a);
                system.debug('***** flowName=' + flowMap.get(a));
                if(a == answerString){
                    String flowName = flowMap.get(a);
                    Flow.Interview flow2Invoke = Flow.Interview.createInterview(flowName, params);
                    flow2Invoke.start();
                }
            }
   
        }

        

        


        // String flowName = 'Beta_Testing_Invoking_Email_Send_Flow';
        // Flow.Interview myFlow = Flow.Interview.createInterview(flowName, params);
        // myFlow.start();
    }

    private static Map<String, String> convertString2Map(String flowMapString){
        // Remove curly braces and split into key-value pairs
        flowMapString = flowMapString.substring(1, flowMapString.length() - 1);
        String[] keyValuePairs = flowMapString.split(',');

        // Create a Map to store key-value pairs
        Map<String, String> flowMap = new Map<String, String>();

        // Iterate through the keyValuePairs and add them to the map
        for (String pair : keyValuePairs) {
            String[] parts = pair.split('=');
            if (parts.size() == 2) {
                String key = parts[0].trim();
                String value = parts[1].trim();
                flowMap.put(key, value);
            }
        }

        return flowMap;
    }
}