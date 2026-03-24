({
    doInit : function(component, event, helper) {
        var deviceFormFactor = $A.get("$Browser.formFactor");
        if(deviceFormFactor === 'DESKTOP') {
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
            component.set('v.isNotDesktop', false);
            var navService = component.find("navService");
            var pageReference = {
                type: 'standard__component',
                attributes: {
                    componentName: 'Kinetics__inspTemplateQuestionRenderer'
                },
                state : {
                    c__inspectionRecordId : component.get('v.recordId'),
                    c__fetchAllQuestions : component.get('v.fetchAllQuestions')
                }
            };    
            navService.navigate(pageReference);
        } else {
            component.set('v.isloading', false);
        }
    }
})