@isTest
public with sharing class TestDataFactory {
    
    public static List<Account> createAccounts(Integer numOfAccts) {
        List<Account> acctsToCreate = new List<Account>();
        for(Integer i=0; i < numOfAccts; i++) {
            Account a = new Account(Name = 'Test Account ' + i);
            acctsToCreate.add(a);
        }
        return acctsToCreate;
    }
    public static List<Contact> createContacts(List<Account> accts, Integer numOfConsPerAcct) {
        List<Contact> consToCreate = new List<Contact>();
        for(Account a : accts) {
            for(Integer i=0; i < numOfConsPerAcct; i++) {
                Contact c = new Contact(FirstName = 'Test' + i, LastName = 'Test' + i, AccountId = a.id);
                consToCreate.add(c);
            }
        }
        return consToCreate;
    }
    public static List<Opportunity> createOpportunities(List<Account> accts, Integer numOfOppsPerAcct) {
        List<Opportunity> oppsToCreate = new List<Opportunity>();
        for(Account a : accts) {
            for(Integer i=0; i < numOfOppsPerAcct; i++) {
                Opportunity o = new Opportunity(Name = 'Test' + i, StageName = 'New', CloseDate = Date.today(), AccountId = a.id);
                oppsToCreate.add(o);
            }
        }
        return oppsToCreate;
    }
    public static String findOddAndEvenNumber(Integer i) {
        Integer num1 = i/2;
        Integer result = num1 * 2;
        if(i == result) {
            return 'Even';
        }else{
            return 'Odd';
        }
    }
}