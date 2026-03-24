({
    savePDFLocal : function(cmp, event, helper) {
            window.setTimeout(
                $A.getCallback(function() {
                    helper.callApex(cmp, event, helper);
                }), 
                5000
            );
    },
    callApex: function(cmp, event, helper) {
        var action = cmp.get("c.savePDF");
        action.setParams({ inspecRecId : cmp.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                //alert('Attachment saved successfully');
                var urlEvent = $A.get("e.force:navigateToURL") ;
                urlEvent.setParams({"url": response.getReturnValue()});
                urlEvent.fire();

                $A.get("e.force:closeQuickAction").fire();
                $A.get( "e.force:refreshView" ).fire();
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        alert("Error message: " + errors[0].message);
                    }
                } else {
                    alert("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }
})