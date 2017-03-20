({
	doInit : function(component, event, helper) {
		var setup = component.get('c.setup');
        setup.setCallback(this, function (response) {
            var latchAccount = {sobjectType: 'Latch_Account__c'};
            if (response.getState() === 'SUCCESS') {
                latchAccount = response.getReturnValue();
            }
            
            component.set('v.latchAccount', latchAccount);
        });
        
        $A.enqueueAction(setup);
	},
    doPair : function(component, event, helper) {
        var pairAction = component.get('c.pair');
        pairAction.setParams({'pairingToken': component.get('v.pairingToken')});
        pairAction.setCallback(this, function(res) {
            var latchAccount = '';
            if (res.getState() === 'SUCCESS') {
                var latchAccount = res.getReturnValue();
            	component.set('v.latchAccount.Account_Id__c', latchAccount);
            }
        });
        
        $A.enqueueAction(pairAction);
    },
    doUnpair : function(component, event, helper) {
        var unpairAction = component.get('c.unpair');
        unpairAction.setParams({'accountId': component.get('v.latchAccount.Account_Id__c')});
        unpairAction.setCallback(this, function(res) {
            if (res.getState() === 'SUCCESS') {
            	component.set('v.latchAccount', {sobjectType: 'Latch_Account__c'});
            	component.set('v.pairingToken', '');
            }
        });
        
        $A.enqueueAction(unpairAction);
    }
})