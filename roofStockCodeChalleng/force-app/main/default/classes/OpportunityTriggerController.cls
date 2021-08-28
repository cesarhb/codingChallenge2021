public with sharing class OpportunityTriggerController {
    // method runs in Opportunity after insert context - it updates Related_PIds__c with a concatenated Opp PIds onto the related Acct
    public static void setPidOnAcct(List<Opportunity> newOpps) {
        List<Id> acctIds = new List<Id>();
        for(Opportunity o : newOpps) {
            if(o.AccountId != null) acctIds.add(o.AccountId);
        }
        updatePIdsOnAcct(acctIds);
    }

    public static void updatePIdsOnDelete(List<Opportunity> deletedOpps) {
        List<Id> acctIds = new List<Id>();
        for(Opportunity o : deletedOpps) {
            if(o.AccountId != null) acctIds.add(o.AccountId);
        }
        // handle Account DML asynchronously
        updatePIdsOnAcct(acctIds);
    }

    // method queries Accounts with Opps - loops through each Account, and then each Opp related to that Acct
    // it performs the DML to update Related_PIds__c on the Account
    public static void updatePIdsOnAcct(List<Id> acctIds) {
        List<Account> acctsWithOpps = [SELECT Id, (SELECT Pid__c FROM Opportunities)
                                        FROM Account 
                                        WHERE Id IN :acctIds];

        List<Account> acctsToUpdate = new List<Account>();
        for(Account a : acctsWithOpps) {
            Set<String> pIds = new Set<String>();
            for(Opportunity o : a.Opportunities) {
                if(o.Pid__c == null) {
                    continue;
                } else {
                    pIds.add(String.valueOf(o.Pid__c));
                }
            }
            a.Related_PIds__c = String.join(new List<String>(pIds), ',');
            acctsToUpdate.add(a);
        }
        try {
            update acctsToUpdate;
        } catch (exception e) {
            system.debug('exception ' + e.getMessage());
        }
    } 
}
