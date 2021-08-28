trigger OpportunityTrigger on Opportunity (after insert, after delete) {
    if(trigger.isAfter) {
        if(trigger.isInsert) {
            OpportunityTriggerHandler.handleAfterInsert(trigger.new);
        }
                                                                                
        if(trigger.isDelete) {
            OpportunityTriggerHandler.handleAfterDelete(trigger.old);
        }
    }
}