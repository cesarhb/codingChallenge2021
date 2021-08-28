public with sharing class OpportunityTriggerHandler {
    public static void handleAfterInsert(List<Opportunity> newOpps) {
        OpportunityTriggerController.setPidOnAcct(newOpps);
    }
    
    public static void handleAfterDelete(List<Opportunity> deletedOpps) {
        OpportunityTriggerController.updatePIdsOnDelete(deletedOpps);        
    }
}
