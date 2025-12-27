({
    handleRequestCreated : function(component, event, helper) {
        var requestId = event.getParam('requestId'); // Get request Id

        var navEvent = $A.get("e.force:navigateToSObject");
        navEvent.setParams({
            "recordId": requestId,
            "slideDevName": "detail" // Optional: show detail view
        });
        navEvent.fire();
    },
    handleClose : function(component, event, helper) {
        var navEvent = $A.get("e.force:navigateToObjectHome");
        navEvent.setParams({
            "scope": "Request__c"   // Your object API name
        });
        navEvent.fire();
    }
    
})
