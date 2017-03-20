public with sharing class LatchClient {
    final private static String API_URL = '/api/1.1';
    final private static String CHECK_STATUS_URL = '/status/{0}/op/{1}';
    final private static String PAIRING_URL = '/pair/{0}';
    final private static String UNPAIRING_URL = '/unpair/{0}';
	final private LatchConnection lc;
   	
    private String accId;
    private Boolean userPaired = false;
    
    public LatchClient(String latchApplicationName) {
        List<Latch_Account__c> accts = [SELECT Account_Id__c FROM Latch_Account__c WHERE User__c = :UserInfo.getUserId()];
        if (!accts.isEmpty()) {
            this.accId = accts.get(0).Account_Id__c;
            this.userPaired = true;
        }
        this.lc = createConnection(latchApplicationName);
    }
    
    public LatchClient(String latchApplicationName, String accId) {
        this.accId = accId;
        this.userPaired = true;
        this.lc = createConnection(latchApplicationName);
    }
    
    public Boolean isLatchOpen(String opId) {
        if (userPaired) {
            String url = String.format(API_URL + CHECK_STATUS_URL, new String[] {
                accId, opId
            });
            
            return parseLatchStatus(lc.get(url), opId);
        } else {
            System.debug('The user is not paired with latch, returning latch as opened');
            return true;
        }
    }
    
    public void unpair(String accountId) {
        if (userPaired) {
        	String jsonLatchResponse = lc.get(String.format(API_URL + UNPAIRING_URL, new String[] {accountId}));
            if (isUnpairingSuccessful(jsonLatchResponse)) {
            	userPaired = false;
                removeLatchAccount(accountId);
            }
        } else {
            System.debug(UserInfo.getName() + ' was not paired');
        }
        
    }
    
    public String pair(String pairingToken) {
        return pair(pairingToken, false);
    }
    
    public String pair(String pairingToken, Boolean force) {
        if (userPaired && !force) {
            System.debug('User already paired with latch');
            return accId;
        }
        
        String jsonLatchResponse = lc.get(String.format(API_URL + PAIRING_URL, new String[] {pairingToken}));
        
        String newAccId = parseAccountFromPair(jsonLatchResponse);
        if (newAccId != null) {
            accId = newAccId;
            userPaired = true;
            
            addLatchPairing(newAccId);
        }
        
        return newAccId;
    }
    
    private void addLatchPairing(String accId) {
        Latch_Account__c acct = new Latch_Account__c(
        	User__c = UserInfo.getUserId(),
            Account_Id__c = accId
        );
        
        insert acct;
    }
    
    private void removeLatchAccount(String accId) {
        List<Latch_Account__c> las = [
            SELECT Account_Id__c
              FROM Latch_Account__c
             WHERE Account_Id__c = :accId
               AND User__c = :UserInfo.getUserId()
        ];
        
        delete las;
    }
    
    private Boolean isUnpairingSuccessful(String jsonObject) {
        Map<String, Object> latchResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonObject);
        Boolean failed = true;
        
        if (latchResponse.get('error') != null) {
            Map<String, Object> error = (Map<String, Object>) latchResponse.get('error');
            System.debug('Latch Pairing Error: (' 
                         + error.get('code') + ') ' 
                         + error.get('message'));
            failed = false;
        }
        
        return failed;
    }
    
    private String parseAccountFromPair(String jsonObject) {
         Map<String, Object> latchResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonObject);
        
        System.debug('Latch Response: ' + latchResponse);
        
        if (latchResponse.get('data') != null) {
            Map<String, Object> data = (Map<String, Object>) latchResponse.get('data');
        	return (String) data.get('accountId');
        } else if (latchResponse.get('error') != null) {
            Map<String, Object> error = (Map<String, Object>) latchResponse.get('error');
            System.debug('Latch Pairing Error: (' 
                         + error.get('code') + ') ' 
                         + error.get('message'));
        } else {
            System.debug('Cannot parse Latch response while pairing: ' + jsonObject);
        }
        
        return null;
    }
    
    private Boolean parseLatchStatus(String jsonLatchResponse, String opId) {
        Map<String, Object> latchResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonLatchResponse);
        if (latchResponse.get('data') != null) {
            Map<String, Object> data = (Map<String, Object>) latchResponse.get('data');
            Map<String, Object> operations = (Map<String, Object>) data.get('operations');
            Map<String, Object> loginOperation = (Map<String, Object>) operations.get(opId);
            String latchStatus = (String) loginOperation.get('status');
            
            return latchStatus == 'on';
        } else {
            return true;
        }
    }
    
    private LatchConnection createConnection(String latchApplicationName) {
        List<Latch_Application__mdt> las = [
            SELECT Application_Id__c,
             	   Secret__c 
			  FROM Latch_Application__mdt
             WHERE Label = :latchApplicationName];
        
        return new LatchConnection(las.get(0).Application_Id__c, las.get(0).Secret__c);
    }
}