public with sharing class OpportunityWebServiceHelper {
    // this method performs the following: validates PID in requestBody, generates needed collections, determines request context
    public static Map<String, String> initializeHandleRequest(List<OpportunityWebService> requests) {
        Map<String, String> response = new Map<String, String>();
        List<String> concatenatedPids = new List<String>();
        List<OpportunityWebService> emailNotNullRequests = new List<OpportunityWebService>();
        List<OpportunityWebService> emailIsNullRequests  = new List<OpportunityWebService>();
        List<Integer> emailRequestsPids = new List<Integer>();
        List<String> emailList         = new List<String>();
        List<Integer> emailNullRequestsPid = new List<Integer>();
        List<String> phoneList            = new List<String>();

        for(OpportunityWebService req : requests){
            // Make sure the request is valid and immediately return when invalid
            if(req.pid == null){
                response.put(Utils.validity, Utils.invalid);
                return response;
            } else {
                response.put(Utils.validity, Utils.valid);
            }
            concatenatedPids.add(String.valueOf(req.pid));
            if (req.Email != null) {
                emailNotNullRequests.add(req);
                emailRequestsPids.add(req.pid);
                emailList.add(req.email);
            } else {
                emailIsNullRequests.add(req);
                emailNullRequestsPid.add(req.pid);
                phoneList.add(req.phone);
            }
        }
        // Determine search context 
        If(!emailList.isEmpty() && phoneList.isEmpty()) {
            response.put(Utils.context, Utils.emailContext);
            response.put(Utils.emails, String.join(emailList, ','));
        } else if(emailList.isEmpty() && !phoneList.isEmpty()){
            response.put(Utils.context, Utils.phoneContext);
            response.put(Utils.phones, String.join(phoneList, ','));
        } else {
            response.put(Utils.context, Utils.phoneAndEmailContext);
            response.put(Utils.Emails, String.join(emailList, ','));
            response.put(Utils.Phones, String.join(phoneList, ','));
            response.put(Utils.emailRequests, JSON.serialize(emailNotNullRequests));
            response.put(Utils.phoneRequests, JSON.serialize(emailIsNullRequests));
        }
        
        response.put(Utils.pIds, string.join(concatenatedPids, ','));
        return response;
    }
    // method is called to query Contact - code runs on a switch based on Email / Phone search context
    public static List<Contact> queryContacts(String context, Set<Integer> pidList, List<String> filter) {
        system.debug('queryContacts ' + context);
        List<String> queryFilter = new List<String>();
        for(String s : filter) {
            if(s.contains(',')) {
                List<String> handleConcatenation = s.split(',');
                for(String eachEmailOrPhone : handleConcatenation) {
                    queryFilter.add(eachEmailOrPhone);
                }
            } else {
                queryFilter.add(s);
            }
        }
        system.debug(queryFilter);
        List<Contact> cons;
        Switch on context {
            when 'Email' {
                cons = [SELECT Id, Email, Phone, AccountId, Account.Related_Email_Addresses__c, Account.Related_PIds__c 
                        FROM Contact WHERE Email IN :queryFilter];
            }
            when 'Phone' {
                cons = [SELECT Id, Email, Phone, AccountId, Account.Related_Phone_Numbers__c, Account.Related_PIds__c
                        FROM Contact WHERE Phone IN :queryFilter];
            }
        }
        system.debug('cons found ' + cons.size());
        for(Contact c : cons) {
            system.debug('query result ' + c);
        }

        return cons;
    }

    // this method is called when a query in any of the three contexts - Email, Phone, Email and Phone - returns some data
    // in those scenarios, processData handles the remaining business logic and returns a List of Pids and realted OppIds
    public static List<String> processData(List<Contact> cons, String context, Map<Integer, String> pIdMap, List<OpportunityWebService> requests) {
        List<String> response = new List<String>();
        // Step 1: Segregate Requests into those with a matching Contact and those with no Matching Contact
        Map<String, Contact> contactMap                       = generateContactMap(cons, context);
        List<List<OpportunityWebService>> segregatedRequests  = segregateRequests(requests, contactMap, context);
        List<OpportunityWebService> requestsWithMatchingCons  = segregatedRequests[0];
        system.debug('requestsWithMatchingCons ' + requestsWithMatchingCons.size());
        List<OpportunityWebService> requestsNoMatchingCon     = segregatedRequests[1];
        system.debug('requestsNoMatchingCon ' + requestsNoMatchingCon.size());
        // Step 2: For Requests with Matching Contacts, check if the Opps related to the Con's Account contains the request's pId
        // Segregate requestsWithMatchingCons into requestsForOppUpdate & requestsForOppCreate 
        List<List<OpportunityWebService>> segregatedMatchingConsRequest = segregateMatchingConsRequests(requestsWithMatchingCons, contactMap, context);
        List<OpportunityWebService> requestsForUpdate                   = segregatedMatchingConsRequest[0];
        system.debug('requestsForUpdate ' + requestsForUpdate.size());
        List<OpportunityWebService> requestsForOppCreate                = segregatedMatchingConsRequest[1];
        system.debug('requestsForOppCreate ' + requestsForOppCreate.size());
        // Step 3: Perform DML
        if(requestsNoMatchingCon.size() > 0) response.addAll(handleCreateAllRequests(requestsNoMatchingCon));
        if(requestsForOppCreate.size() > 0)  response.addAll(handleOppCreate(requestsForOppCreate, contactMap, context));
        if(requestsForUpdate.size() > 0)     response.addAll(handleOppUpdate(requestsForUpdate, contactMap, context));
        return response;
    }
    // method determines if each element in the request has a corresponding SF contact - it returns two Lists of requests
    public static List<List<OpportunityWebService>> segregateRequests(List<OpportunityWebService> requests, Map<String, Contact> contactMap, String context) {
        List<List<OpportunityWebService>> response = new List<List<OpportunityWebService>>();
        List<OpportunityWebService> requestsWithMatchingCon = new List<OpportunityWebService>();
        List<OpportunityWebService> requestsNoMatchingCon   = new List<OpportunityWebService>();
        
        Switch on context {
            when 'Email' {
                system.debug(context);
                for(OpportunityWebService req : requests) {
                    system.debug(req);
                    system.debug(contactMap.get(req.email));
                    if(contactMap.get(req.email) != null) {
                        system.debug(contactMap.get(req.email));
                        requestsWithMatchingCon.add(req);
                    } else {
                        system.debug('here ' + req);
                        requestsNoMatchingCon.add(req);
                    }
                }
            }
            when 'Phone' {
                system.debug(context);
                for(OpportunityWebService req : requests) {
                    system.debug(req);
                    if(contactMap.get(req.phone) != null) {
                        system.debug(contactMap.get(req.phone));
                        requestsWithMatchingCon.add(req);
                    } else {
                        system.debug('here ' + req);
                        requestsNoMatchingCon.add(req);
                    }
                }
            }
        }
        response.add(requestsWithMatchingCon);
        response.add(requestsNoMatchingCon);          
        return response;
    }
    // method handles requests that have a corresponding SF contact, and determines if an Opp needs to be updated or created - returns two lists
    public static List<List<OpportunityWebService>> segregateMatchingConsRequests(List<OpportunityWebService> requests, Map<String, Contact> contactMap, String context) {
        List<List<OpportunityWebService>> response        = new List<List<OpportunityWebService>>();
        List<OpportunityWebService> requestsForUpdate     = new List<OpportunityWebService>();
        List<OpportunityWebService> requestsForOppCreate  = new List<OpportunityWebService>();
        Switch on context {
            When 'Email' {
                system.debug('context ' + context);
                for(OpportunityWebService req : requests) {
                    system.debug(req);
                    Contact c = contactMap.get(req.Email);
                    system.debug(c);
                    List<String> consAcctOppPIds = c.Account.Related_PIds__c.split(',');
                    system.debug(consAcctOppPIds);
                    for(String relatedOppPId : consAcctOppPIds) {
                        system.debug(relatedOppPId);
                        if(req.pid == Integer.valueOf(relatedOppPId)) {
                            system.debug(req.pid + ' ' + Integer.valueOf(relatedOppPId));
                            requestsForUpdate.add(req);
                        } else {
                            system.debug('req ' + req);
                            requestsForOppCreate.add(req);
                        }
                    }
                } 
            }
            When 'Phone' {
                system.debug(context);
                for(OpportunityWebService req : requests) {
                    system.debug(req);
                    Contact c = contactMap.get(req.Phone);
                    system.debug(c);
                    List<String> consAcctOppPIds = c.Account.Related_PIds__c.split(',');
                    system.debug(consAcctOppPIds);
                    for(String relatedOppPId : consAcctOppPIds) {
                        system.debug(relatedOppPId);
                        if(req.pid == Integer.valueOf(relatedOppPId)) {
                            system.debug(req.pid + ' ' + Integer.valueOf(relatedOppPId));
                            requestsForUpdate.add(req);
                        } else {
                            system.debug(req);
                            requestsForOppCreate.add(req);
                        }
                    }
                } 
            }
        }
        response.add(requestsForUpdate);
        response.add(requestsForOppCreate);  
        return response;
    }
    public static Map<String, Contact> generateContactMap(List<Contact> cons, String context) {
        Map<String, Contact> response = new Map<String, Contact>();
        for(Contact c : cons) {
            if(context == Utils.emailContext) {
                response.put(c.Email, c);
            } else {
                response.put(c.Phone, c);
            }
        }
        return response;
    }
    // method is called for requests that require creating an Account, Contact, and Opp - it returns pids & corresponding oppIds
    public static List<String> handleCreateAllRequests(List<OpportunityWebService> requests) {
        system.debug('handleCreateAllRequests');
        List<Account> acctsToCreate    = new List<Account>();
        List<Contact> consToCreate     = new List<Contact>();
        List<Opportunity> oppsToCreate = new List<Opportunity>();
        
        for(OpportunityWebService req : requests) {
            Account a = new Account();
            a.Name = req.fname + ' ' + req.lname;
            acctsToCreate.add(a);
        }
        Insert acctsToCreate;
        integer i = 0;
        for(OpportunityWebService req : requests) {
            Contact c = new Contact();
            c.FirstName = req.fname;
            c.LastName  = req.lname;
            c.Email     = req.email;
            c.Phone     = req.Phone;
            c.AccountId = acctsToCreate[i].id;
            consToCreate.add(c);
            Opportunity o = new Opportunity();
            o.Name = req.fname + ' ' + req.lname + ' ' + req.pid;
            o.AccountId = acctsToCreate[i].id;
            o.StageName = Utils.newStage;
            o.Pid__c    = req.pid;
            o.CloseDate = Utils.twoWeeksFromNow;
            oppsToCreate.add(o); 
            i++;
        } 
        
        Insert consToCreate;
        Insert oppsToCreate; 
        return generatePIdOppMap(oppsToCreate);
    }
    // method is called for requests with a matching Contact and an Account with no Opp with the req PId 
    // it creates a new Opp and associates it to the respective Contact's Account, returning pIds & corresponding oppIds 
    public static List<String> handleOppCreate(List<OpportunityWebService> requests, Map<String, Contact> contactMap, String context) {
        system.debug('handleOppCreate');
        system.debug('context ' + context);
        List<Opportunity> oppsToCreate = new List<Opportunity>();
        Switch on context {
            when 'Email' {
                for(OpportunityWebService req : requests) {
                    Opportunity o = new Opportunity(Name = req.fname + ' ' + req.lname + ' ' + req.pid, StageName = Utils.newStage,
                                                    Pid__c = req.pid, AccountId = contactMap.get(req.email).AccountId, CloseDate = Utils.twoWeeksFromNow);
                    system.debug(o.AccountId);
                    oppsToCreate.add(o);
                }
            }
            when 'Phone' {
                for(OpportunityWebService req : requests) {
                    Opportunity o = new Opportunity(Name = req.fname + ' ' + req.lname + ' ' + req.pid, StageName = Utils.newStage,
                                                    Pid__c = req.pid, AccountId = contactMap.get(req.phone).AccountId, CloseDate = Utils.twoWeeksFromNow);
                    oppsToCreate.add(o);
                }
            }
        }
        insert oppsToCreate;  
        return generatePIdOppMap(oppsToCreate);
    }
    // method is called for requests with a matching Contact whose Account has an Opp with the same PId
    // it updates the respective Opp and returns pIds & corresponding oppIds
    public static List<String> handleOppUpdate(List<OpportunityWebService> requests, Map<String, Contact> contactMap, String context) {
        system.debug('handleOppUpdate');
        List<String> response = new List<String>();
        Map<Opportunity, OpportunityWebService> oppToUpdateRequestMap = new Map<Opportunity, OpportunityWebService>();
        Map<OpportunityWebService, Contact> requestConMap = requestConMap(requests, contactMap, context);
        List<Id> acctIds = new List<Id>();
        for(Contact c : contactMap.values()) {
            acctIds.add(c.AccountId);
        }
        Map<Id, List<Opportunity>> acctIdOppsMap = generateAcctIdOppsMap(acctIds);
        for(OpportunityWebService req : requests) {
            Contact c = requestConMap.get(req);
            List<Opportunity> opps = acctIdOppsMap.get(c.AccountId);
            for(Opportunity o : opps) {
                if(req.pid == Integer.valueOf(o.Pid__c)) {
                    oppToUpdateRequestMap.put(o, req);
                    break;
                }
            }
        }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Opportunity o : oppToUpdateRequestMap.keySet()) {
            OpportunityWebService req = oppToUpdateRequestMap.get(o);
            o.Name = req.fname + ' ' + req.lname + req.pid;
            o.StageName = Utils.newStage;
            o.CloseDate = Utils.twoWeeksFromNow;
            oppsToUpdate.add(o);
        }
        system.debug('oppsToUpdate ' + oppsToUpdate.size());
        update oppsToUpdate;
        return generatePIdOppMap(oppsToUpdate);
    }
    public static Map<OpportunityWebService, Contact> requestConMap(List<OpportunityWebService> requests, Map<String, Contact> conMap, String context) {
        Map<OpportunityWebService, Contact> response = new Map<OpportunityWebService, Contact>();
        for(OpportunityWebService req : requests) {
            if(context == Utils.emailContext) {
                response.put(req, conMap.get(req.email));
            } else {
                response.put(req, conMap.get(req.phone));
            }
        }
        return response;
    }
    public static Map<Id, List<Opportunity>> generateAcctIdOppsMap(List<Id> acctIds) {
        Map<Id, List<Opportunity>> response = new Map<Id, List<Opportunity>>();
        for(Account a : [SELECT Id,(SELECT Id, Pid__c FROM Opportunities) FROM Account WHERE ID IN :acctIds]) {
            List<Opportunity> opps = new List<Opportunity>();
            for(Opportunity o : a.Opportunities) {
                opps.add(o);
            }
            response.put(a.id, opps);
        }
        return response;
    } 
    // method is used to return pIds and corresponding oppIds
    @TestVisible
    public static List<String> generatePIdOppMap(List<Opportunity> opps) {
        List<String> response = new List<String>();
        for(Opportunity o : opps) {
            response.add('[{"pid":"' + o.Pid__c + '","opportunityId":"' + o.id + '"}]');
        }
        return response;
    }
    // all requests are passed to this method - it returns two Maps, both of which contain PId as the key
    // pidEmailMap has emails as the search values; pidPhoneMap has phones as the values
    public static List<Map<Integer, String>> generatePidMap(List<OpportunityWebService> requests) {
        List<Map<Integer, String>> responseList = new List<Map<Integer, String>>();
        Map<Integer, String> pidEmailMap = new Map<Integer, String>();
        Map<Integer, String> pidPhoneMap = new Map<Integer, String>();
        for(OpportunityWebService req : requests) {
            if (req.email != null) {
                if (!pidEmailMap.containsKey(req.pid)) {
                    pidEmailMap.put(req.pid, req.Email);
                } else {
                    pidEmailMap.put(req.pid, pidEmailMap.get(req.PID) + ',' + req.Email);
                }
            } else {
                if (!pidPhoneMap.containsKey(req.pid)){
                    pidPhoneMap.put(req.pid, req.phone);
                } else {
                    pidPhoneMap.put(req.pid, pidPhoneMap.get(req.PID) + ',' + req.phone);
                }
            }
        }
        responseList.add(pidEmailMap);
        responseList.add(pidPhoneMap);
        return responseList;
    }
    
}


