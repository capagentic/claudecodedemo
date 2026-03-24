global class InspFlowRouter {
    

    @InvocableMethod(label='Inspection Form Flow Router' description='Inspection Form Flow Router' category='Inspection')
    global static List<InspFlowValidationResult> validateInspFlow(List<InspFlowValidationRequest> requests) {
        List<InspFlowValidationResult> results = new List<InspFlowValidationResult>();
        InspFlowValidationRequest req;
        if(!requests.isEmpty()){
            req = requests.get(0);
        }
        List<Kinetics__Inspection__c> inspList = [SELECT Id, Kinetics__Email_Notification_Controller__c, Kinetics__Email_Notification_Recipient__c,
                                                            Kinetics__Email_Notification_Required__c, Kinetics__Follow_up_Inspection_Control_Answer__c,
                                                            Kinetics__Follow_up_Inspection_Control_Question__c, Kinetics__Follow_up_Inspection_Controller__c,
                                                            Kinetics__Follow_up_Inspection_ID__c, Kinetics__Follow_up_Inspection_Required__c 
                                                        FROM Kinetics__Inspection__c
                                                        WHERE Id =: req.inspID ];
        Kinetics__Inspection__c insp = inspList.get(0);                                             
        if(req.flowType == 'Followup Inspection'){
            
            String questionText = insp.Kinetics__Follow_up_Inspection_Control_Question__c;
            String answerTextExpected = insp.Kinetics__Follow_up_Inspection_Control_Answer__c;


        
            List<Kinetic_Form_Answer__c> answers = [SELECT Answer__c, Kinetics__Kinetic_Question__c
                                                FROM Kinetic_Form_Answer__c
                                                WHERE Inspection__c =: req.inspID];

            Boolean validateResult = false;
            for(Kinetic_Form_Answer__c ans: answers){
                system.debug('**** ans.Kinetics__Kinetic_Question__c=' + ans.Kinetics__Kinetic_Question__c);
                system.debug('**** ans.Answer__c=' + ans.Answer__c);
                system.debug('**** questionText=' + questionText);
                system.debug('**** answerTextExpected=' + answerTextExpected);
                if(ans.Kinetics__Kinetic_Question__c == questionText && ans.Answer__c == answerTextExpected){
                    validateResult = true;
                    break;
                }
            }    
            
            InspFlowValidationResult res = new InspFlowValidationResult();
            res.valid = validateResult;
            results.add(res);

        }
        
        return results;
    }

    global class InspFlowValidationRequest {
        @InvocableVariable
        global String flowType; 
    
        @InvocableVariable
        global ID inspID;

        // @InvocableVariable
        // global String control;
    }

    global class InspFlowValidationResult {
        @InvocableVariable
        global Boolean valid; 

    }
}