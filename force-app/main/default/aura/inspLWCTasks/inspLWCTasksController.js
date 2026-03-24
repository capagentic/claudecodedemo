({
    doInit : function(component, event, helper) {
        var navService = component.find("navService");
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__inspTemplateQuestionRenderer'
            },
            state : {
                c__inspectionRecordId : component.get('v.recordId')
            }
        };        
         navService.navigate(pageReference);
    }
})