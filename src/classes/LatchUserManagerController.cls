public with sharing class LatchUserManagerController {
    @AuraEnabled
    public static Latch_Account__c setup() {
        List<Latch_Account__c> las = [
            SELECT Account_Id__c
              FROM Latch_Account__c
             WHERE User__c = :UserInfo.getUserId()
        ];

        return las.isEmpty() ? new Latch_Account__c() : las.get(0);
    }
    
    @AuraEnabled
    public static String pair(String pairingToken) {
        return new LatchClient('Salesforce').pair(pairingToken);
    }
    
    @AuraEnabled
    public static void unpair(String accountId) {
        new LatchClient('Salesforce').unpair(accountId);
    }
}