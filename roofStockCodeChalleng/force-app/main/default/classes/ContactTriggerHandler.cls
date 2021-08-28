public with sharing class ContactTriggerHandler {
    public static void handleAfterInsert(List<Contact> newContacts) {
        ContactTriggerController.setContactsEmailsAndPhonesOnAcct(newContacts);
    }
    /*
    public static void handleAfterUpdate(Map<Id, Contact> oldMap, List<Contact> newContacts) {

    }
    */
    public static void handleAfterDelete(List<Contact> deletedContacts) {
        ContactTriggerController.updateAcctEmailsAndPhoneOnDelete(deletedContacts);        
    }
}
