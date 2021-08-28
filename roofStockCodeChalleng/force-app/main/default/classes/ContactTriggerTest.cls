@isTest()
private class ContactTriggerTest {
    @testSetup private static void setUpTests() {
        Integer numOfAcctsToCreate = 30;
        List<Account> accts = TestDataFactory.createAccounts(numOfAcctsToCreate);
        insert accts;
        Integer numOfAccts = [SELECT COUNT() FROM Account];
        System.assert(numOfAccts == numOfAcctsToCreate);
        List<Opportunity> opps = TestDataFactory.createOpportunities(accts, 1);
        Insert opps;
        Integer numOfOpps = [SELECT COUNT() FROM Opportunity];
        System.assert(numOfAccts == numOfOpps);
    }
    @isTest private static void testEmailAndPhoneOnInsertPositive() {
        List<Account> accts = [SELECT Id FROM Account LIMIT 2];
        List<Contact> consToCreate = TestDataFactory.createContacts(accts, 2);
        for(Contact c : consToCreate) {
            c.Email = 'test@test.com';
            c.Phone = '2125551000';
        }
        Test.startTest();
        Insert consToCreate;
        Test.stopTest();
        Integer acctsWithRelatedEmails = [SELECT COUNT() FROM Account WHERE Related_Email_Addresses__c != null];
        system.assert(accts.size() == acctsWithRelatedEmails);
        Integer acctsWithRelatedPhoness = [SELECT COUNT() FROM Account WHERE Related_Phone_Numbers__c != null];
        system.assert(accts.size() == acctsWithRelatedEmails);
        List<Account> acctsQuery = [SELECT Related_Email_Addresses__c, Related_Phone_Numbers__c 
                                    FROM Account 
                                    WHERE Related_Phone_Numbers__c != null OR Related_Email_Addresses__c != null];
        System.assert(acctsQuery[0].Related_Email_Addresses__c == 'test@test.com,test@test.com');
        System.assert(acctsQuery[1].Related_Email_Addresses__c == 'test@test.com,test@test.com');
        System.assert(acctsQuery[0].Related_Phone_Numbers__c == '2125551000,2125551000');
        System.assert(acctsQuery[1].Related_Phone_Numbers__c == '2125551000,2125551000');
    }
    @isTest private static void testEmailAndPhoneOnInsertNevative() {
        List<Account> accts = [SELECT Id FROM Account LIMIT 2];
        List<Contact> consToCreate = TestDataFactory.createContacts(accts, 2);
        Test.startTest();
        Insert consToCreate;
        Test.stopTest();
        Integer acctsWithRelatedEmails = [SELECT COUNT() FROM Account WHERE Related_Email_Addresses__c != null];
        system.assert(0 == acctsWithRelatedEmails);
        Integer acctsWithRelatedPhoness = [SELECT COUNT() FROM Account WHERE Related_Phone_Numbers__c != null];
        system.assert(0 == acctsWithRelatedEmails);
    }
    @isTest private static void verifyEmailPhoneOnConDelete() {
        List<Account> accts = [SELECT Id FROM Account LIMIT 2];
        List<Contact> consToCreate = TestDataFactory.createContacts(accts, 2);
        for(Contact c : consToCreate) {
            c.Email = 'test@test.com';
            c.Phone = '2125551000';
        }
        Insert consToCreate;
        Test.startTest();
        Integer acctsWithRelatedEmails = [SELECT COUNT() FROM Account WHERE Related_Email_Addresses__c = 'test@test.com,test@test.com'];
        Integer acctsWithRelatedPhones = [SELECT COUNT() FROM Account WHERE Related_Phone_Numbers__c = '2125551000,2125551000'];
        system.assert(acctsWithRelatedEmails == 2);
        system.assert(acctsWithRelatedPhones == 2);
        List<Contact> consToDelete = new List<Contact>();
        Integer loopCount = 0;
        for(Account a : [SELECT Id, (SELECT Id FROM Contacts) FROM Account WHERE Id IN :accts]) {
            for(Contact c : a.Contacts) {
                If(loopCount == 0) {
                    loopCount++;
                    continue;   
                } else {
                    consToDelete.add(c);
                }
                loopCount++;
            }
        }
        system.assert(consToDelete.size() == 3);
        delete consToDelete;
        Test.stopTest();
        Integer postDeleteRelatedEmail = [SELECT COUNT() FROM Account WHERE Related_Email_Addresses__c = 'test@test.com']; 
        Integer postDeleteRelatedPhone = [SELECT COUNT() FROM Account WHERE Related_Phone_Numbers__c = '2125551000'];
        system.assert(postDeleteRelatedEmail == 1);
        system.assert(postDeleteRelatedPhone == 1);
    }
}
