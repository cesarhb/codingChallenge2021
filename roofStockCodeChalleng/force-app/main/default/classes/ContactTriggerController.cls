public class ContactTriggerController {
    public static void setContactsEmailsAndPhonesOnAcct(List<Contact> newContacts) {
        List<Map<Id, String>> acctMaps = generateAcctMaps(newContacts);
        Map<Id, String> acctEmailMap   = acctMaps[0];
        Map<Id, String> acctPhoneMap   = acctMaps[1];
        
        List<Account> acctsToUpdate = [SELECT Id FROM Account WHERE Id IN :acctEmailMap.keySet()];
        if(acctsToUpdate.isEmpty()) return;
        for(Account a : acctsToUpdate) {
            a.Related_Email_Addresses__c = acctEmailMap.get(a.id);
            a.Related_Phone_Numbers__c   = acctPhoneMap.get(a.id);
        }
        try{
            update acctsToUpdate;
        } catch (exception e) {
            system.debug('exception ' + e.getMessage());
        }
    }
    public static void updateAcctEmailsAndPhoneOnDelete(List<Contact> deletedContacts) {
        List<Contact> cons = [SELECT Id, Phone, Email FROM Contact WHERE Id IN :deletedContacts];
        List<Map<Id, String>> acctMaps = generateAcctMaps(deletedContacts);
        Map<Id, String> acctEmailMap   = acctMaps[0];
        Map<Id, String> acctPhoneMap   = acctMaps[1];
        List<Account> acctsToUpdate = [SELECT Id, Related_Email_Addresses__c, Related_Phone_Numbers__c 
                                        FROM Account WHERE Id IN :acctEmailMap.keySet()];
        if(acctsToUpdate.isEmpty()) return;
        for(Account a : acctsToUpdate) {
            a.Related_Email_Addresses__c = acctEmailMap.get(a.id);
            a.Related_Phone_Numbers__c   = acctPhoneMap.get(a.id);
        }
        try {
            update acctsToUpdate;
        } catch (exception e) {
            system.debug('exception ' + e.getMessage());
        }
    }
    public static List<Map<Id, String>> generateAcctMaps(List<Contact> contacts){
        List<Map<Id, String>> response = new List<Map<Id, String>>();
        Map<Id, String> acctEmailMap = new Map<Id, String>();
        Map<Id, String> acctPhoneMap = new Map<Id, String>();
        for(Contact c : contacts) {
            if(!acctEmailMap.containsKey(c.AccountId)) {
                if(c.Email != null) acctEmailMap.put(c.AccountId, c.Email);
            } else {
                if(c.Email != null) acctEmailMap.put(c.AccountId, acctEmailMap.get(c.AccountId) + ',' + c.Email);
            }
            if(!acctPhoneMap.containsKey(c.AccountId)) {
                if(c.Phone != null) acctPhoneMap.put(c.AccountId, c.Phone);
            } else {
                if(c.Phone != null) acctPhoneMap.put(c.AccountId, acctPhoneMap.get(c.AccountId) + ',' + c.Phone);
            }
        }
        response.add(acctEmailMap);
        response.add(acctPhoneMap);
        return response;
    }
}
