global class LatchFlowPlugin implements Process.Plugin {
    
    global Process.PluginResult invoke(Process.PluginRequest request) {
        Latch_Operation__mdt lo = [SELECT Operation_Id__c FROM Latch_Operation__mdt WHERE Label = 'Login' LIMIT 1];
        LatchClient lc = new LatchClient('Salesforce');
        Map<String, Object> result = new Map<String, Object>();
        result.put('IsLatchOpen', lc.isLatchOpen(lo.Operation_Id__c));
        
        return new Process.PluginResult(result);
    }
    
    global Process.PluginDescribeResult describe() {
        Process.PluginDescribeResult description = new Process.PluginDescribeResult();
        description.tag='Identity';
        description.name='Latch Plugin';
        description.description='Use latch to grant or deny access';
            
        description.outputParameters = new List<Process.PluginDescribeResult.OutputParameter> {
            new Process.PluginDescribeResult.OutputParameter(
                'IsLatchOpen',
                Process.PluginDescribeResult.ParameterType.BOOLEAN)
        };
        return description;
    }
}