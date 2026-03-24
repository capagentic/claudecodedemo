({
    init : function(component, event, helper) {

    },
    closePopup :  function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
        $A.get( "e.force:refreshView" ).fire();
        component.set('v.isloading', false);
        helper.navigateToRecord(component, event, helper);
	}, 
})