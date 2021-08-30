@RestResource(urlMapping='/Opportunity')
global with sharing class OpportunityWebService {

    @HttpPatch
    global static void doPatch() { 
        List<String> response = new List<String>();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        // Begin parsing the request payload     
        List<OpportunityWebService> parsedReqList;
        try{
            parsedReqList = parse(req.RequestBody.toString());
        } catch (exception e) {
            res.statusCode = 400;
            res.ResponseBody = Blob.valueOf(Utils.parseExceptionMsg);
            return;
        }
        // Generate needed collections & identify context (i.e. requests only require search by email, or only search by phone, or both)
        Map<String, String> initializationMap = OpportunityWebServiceHelper.initializeHandleRequest(parsedReqList);
        // Ensure that no element in the request payload contains a pId value that is null -- if it does, it is invalid
        If(initializationMap.get(Utils.validity) == Utils.invalid) {
            res.statusCode = 400;
            res.ResponseBody = Blob.valueOf(Utils.pidErrorMsg);
            return;
        }
        // call generatePidMap to create two maps: 1. pIds & corresponding Emails, 2. pids and corresponding Phone #s
        List<Map<Integer, String>> pidMapList = OpportunityWebServiceHelper.generatePidMap(parsedReqList);
        Map<Integer, String> pidEmailMap = pidMapList[0];
        Map<Integer, String> pidPhoneMap = pidMapList[1];
        String requestContext = initializationMap.get(Utils.context);
        Switch on requestContext {
            // when all elements in the request contain an email address, the requestContext = 'Email'
            when 'Email' {
                List<Contact> cons = OpportunityWebServiceHelper.queryContacts(Utils.emailContext, pidEmailMap.keySet(), pidEmailMap.values());    
                If(cons.isEmpty()) {
                    // create an Acct, Con, & Opp for each request. Add to response a List of Strings, i.e. {"pid":x,"opportunityId":"y"},{"pi.... 
                    response = OpportunityWebServiceHelper.handleCreateAllRequests(parsedReqList);
                    
                } else {
                    // some records were found - processData handles the rest, returning pIds and corresponding oppIds
                    response.addAll(OpportunityWebServiceHelper.processData(cons, requestContext, pidEmailMap, parsedReqList)); 
                }

                res.ResponseBody = Blob.valueOf(String.join(response, ','));
                return; 
            }
            // when no elements in the request contain an email address, the requestContext = 'Phone'
            when 'Phone' {
                List<Contact> cons = OpportunityWebServiceHelper.queryContacts(Utils.phoneContext, pidPhoneMap.keySet(), pidPhoneMap.values());
                if(cons.isEmpty()) {
                    // create an Acct, Con, & Opp for each request. Add to response a List of Strings, i.e. {"pid":x,"opportunityId":"y"},{"pi.... 
                    response = OpportunityWebServiceHelper.handleCreateAllRequests(parsedReqList);
                } else {
                    // some records were found - processData handles the rest, returning pIds and corresponding oppIds
                    response.addAll(OpportunityWebServiceHelper.processData(cons, requestContext, pidPhoneMap, parsedReqList)); 
                }
                res.ResponseBody = blob.valueOf(String.join(response, ','));
                return;  
            }
            // when some elements in the request, but not all contain an email address, the requestContext = 'Email and Phone'
            when 'Email and Phone' {
                // lists of Contacts queried by Email and Phone, respectively
                List<Contact> consByEmail  = OpportunityWebServiceHelper.queryContacts(Utils.emailContext, pidEmailMap.keySet(), pidEmailMap.values());    
                List<Contact> consByPhone = OpportunityWebServiceHelper.queryContacts(Utils.phoneContext, pidPhoneMap.keySet(), pidPhoneMap.values());
                if(consByEmail.isEmpty()) {
                    // create an Acct, Con, & Opp for each request. Add to response a List of Strings, i.e. {"pid":x,"opportunityId":"y"},{"pi.... 
                    response.addAll(OpportunityWebServiceHelper.handleCreateAllRequests(parse(initializationMap.get(Utils.emailRequests))));
                } else {
                    response.addAll(OpportunityWebServiceHelper.processData(consByEmail, Utils.emailContext, pidEmailMap, parse(initializationMap.get(Utils.emailRequests))));
                }
                if(consByPhone.isEmpty()) {
                    // create an Acct, Con, & Opp for each request. Add to response a List of Strings, i.e. {"pid":x,"opportunityId":"y"},{"pi.... 
                    response.addAll(OpportunityWebServiceHelper.handleCreateAllRequests(parse(initializationMap.get(Utils.phoneRequests))));
                } else {
                    response.addAll(OpportunityWebServiceHelper.processData(consByPhone, Utils.phoneContext, pidPhoneMap, parse(initializationMap.get(Utils.phoneRequests))));
                }
                String resString = String.join(response, ',');
                res.ResponseBody = blob.valueOf(resString);
                return;  
            }   
        } 
    }

    public Integer pid;
    public String email;
    public String phone;
    public String fname;
    public String lname;

    public static List<OpportunityWebService> parse(String json) {
        return (List<OpportunityWebService>) System.JSON.deserialize(json, List<OpportunityWebService>.class);  
    } 
}