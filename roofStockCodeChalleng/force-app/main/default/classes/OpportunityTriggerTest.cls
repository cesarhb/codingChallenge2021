@isTest
public with sharing class OpportunityTriggerTest {
    @testSetup private static void setUpTests() {
        Integer numOfAcctsToCreate = 30;
        List<Account> accts        = TestDataFactory.createAccounts(numOfAcctsToCreate);
        insert accts;
        Integer acctCount = [SELECT COUNT() FROM Account];
        system.assert(acctCount == numOfAcctsToCreate);
    }
    @isTest private static void testPIdOnInsertPositive() {
        List<Account> accts     = [SELECT Id FROM Account];
        List<Opportunity> opps  = TestDataFactory.createOpportunities(accts, 2);
        integer i = 1;
        for(Opportunity o : opps) {
            if(TestDataFactory.findOddAndEvenNumber(i) == 'Odd'){
                o.Pid__c = 1;
            } else {
                o.Pid__c = 2;
            }
            i++;
        }
        Test.startTest();
        insert opps;
        Integer oppWithPidCount = [SELECT COUNT() FROM Opportunity WHERE Pid__c = 1 OR PID__c = 2];
        system.assert(oppWithPidCount == 60);
        Test.stopTest();
        Integer acctsWithPidFieldUpdate = [SELECT COUNT() FROM Account WHERE Related_PIds__c = '2,1'];
        system.assert(acctsWithPidFieldUpdate == 30);
    }
    @isTest private static void testPIdOnInsertNegative() {
        List<Account> accts     = [SELECT Id FROM Account];
        List<Opportunity> opps  = TestDataFactory.createOpportunities(accts, 2);
        Test.startTest();
        // create Opps with null values for PId__c
        insert opps;
        Integer oppWithPidCount = [SELECT COUNT() FROM Opportunity WHERE Pid__c != null];
        system.assert(oppWithPidCount == 0);
        Test.stopTest();
        Integer acctsWithPidFieldUpdate = [SELECT COUNT() FROM Account WHERE Related_PIds__c != null];
        system.assert(acctsWithPidFieldUpdate == 0);
    }
    @isTest private static void testPIdAcctUpdateOnOppDelete() {
        List<Account> accts     = [SELECT Id FROM Account];
        List<Opportunity> opps  = TestDataFactory.createOpportunities(accts, 2);
        integer i = 1;
        for(Opportunity o : opps) {
            if(TestDataFactory.findOddAndEvenNumber(i) == 'Odd'){
                o.Pid__c = 1;
            } else {
                o.Pid__c = 2;
            }
            i++;
        }
        insert opps;
        Test.startTest();
        Integer oppWithPidCount = [SELECT COUNT() FROM Opportunity WHERE Pid__c = 1 OR PID__c = 2];
        system.assert(oppWithPidCount == 60);
        Integer acctsWithPidFieldUpdate = [SELECT COUNT() FROM Account WHERE Related_PIds__c = '2,1'];
        system.assert(acctsWithPidFieldUpdate == 30);
        List<Opportunity> oppsToDelete = [SELECT Id FROM Opportunity];
        delete oppsToDelete;
        Test.stopTest();
        Integer acctsWithPidsAfterOppDelete = [SELECT COUNT() FROM Account WHERE Related_PIds__c != null];
        system.assert(acctsWithPidsAfterOppDelete == 0);
        
    }

}
