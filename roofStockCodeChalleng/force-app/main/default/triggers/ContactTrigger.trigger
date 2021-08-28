trigger ContactTrigger on Contact (after insert, after delete) {
    if(trigger.isAfter) {
        if(trigger.isInsert) {
            ContactTriggerHandler.handleAfterInsert(trigger.new);
        }
        /*
        if (trigger.isUpdate) {
            ContactTriggerHandler.handleAfterUpdate(trigger.oldMap, trigger.new);
        }
        */                                                                         
        if(trigger.isDelete) {
            ContactTriggerHandler.handleAfterDelete(trigger.old);
        }
    }

}