({
    doInit : function(component, event, helper) {
        // var inspectionPageRef = component.get("v.pageReference");
        // if(inspectionPageRef != undefined) {
        
        // }
    },
    onPageReferenceChanged: function(cmp, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    closePopup :  function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
        $A.get( "e.force:refreshView" ).fire();
        helper.navigateToRecord(component, event, helper);
	}, 
})