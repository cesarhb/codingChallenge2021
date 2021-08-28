@isTest
private class OpportunityWebServiceTest {
    public static final String oppApiEndpoint      = URL.getSalesforceBaseUrl() + '/services/apexrest/Opportunity';
    public static final String setUpPayload        = '[{"pid":1,"email":"joe@roofstock.com","phone":"510366225","fname":"joe","lname":"bryant"},{"pid":2,"email":"raj@roofstock.com","phone":"5103662252","fname":"raj","lname":"bryant"},' +
                                                      '{"pid":3,"email":"dan@roofstock.com","phone":"5103662251","fname":"dan","lname":"short"},{"pid":4,"email":"sree@roofstock.com","phone":"5103662253","fname":"sree","lname":"menon"},' +
                                                      '{"pid":2,"email":null,"phone":"5103662253","fname":"ana","lname":"joshi"},{"pid":3,"email":"danny@roofstock.com","phone":"5103662252","fname":"danny","lname":"lamont"}]';
    public static final String pidNullPayload      = '[{"pid":null,"email":"joe@roofstock.com","phone":"510366225","fname":"joe","lname":"bryant"}]';
    public static final String newAndExistingPhone = '[{"pid":2,"email":null,"phone":"5103662253","fname":"ana","lname":"joshi"},{"pid":2,"email":null,"phone":"2125551010","fname":"joe","lname":"lewis"}]';
    public static final String newAndExistingEmail = '[{"pid":1,"email":"dbones@test.com","phone":"510366225","fname":"danny","lname":"bones"},{"pid":2,"email":"raj@roofstock.com","phone":"5103662252","fname":"raj","lname":"bryant"}]';
    public static final String emailNewPayload     = '[{"pid":1,"email":null,"phone":"3235550909","fname":"mary","lname":"smith"},{"pid":2,"email":null,"phone":"2124445858","fname":"dan","lname":"davis"}]';
    public static final String phoneNewPayload     = '[{"pid":1,"email":null,"phone":"4153339090","fname":"jen","lname":"davis"},{"pid":2,"email":null,"phone":"3307784343","fname":"mike","lname":"tyson"}]';
    public static final String existingAcctNewOpp  = '[{"pid":3,"email":null,"phone":"5103662253","fname":"ana","lname":"joshi"},{"pid":3,"email":"joe@roofstock.com","phone":"510366225","fname":"joe","lname":"bryant"}]';
    public static final String parseException      = '[{"pid":2,email:null,"phone":5103662253,"fname":"ana","lname":"joshi"}]';

    @TestSetup // setup method that receives a payload with 6 elements - verifies that 6 Accounts, Contacts & Opps were created
    static void makeData(){
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri  = oppApiEndpoint;
        RestContext.request.requestBody = Blob.valueOf(setUpPayload);
        RestContext.request.httpMethod  = 'PATCH';
        Test.startTest();
        OpportunityWebService.doPatch();
        Test.stopTest();
        Integer acctCount = [SELECT COUNT() FROM Account];
        Integer conCount  = [SELECT COUNT() FROM Contact];
        Integer oppCount  = [SELECT COUNT() FROM Opportunity];
        for(account a : [select id, name from account]) {
            system.debug(a);
        }
        system.assert(acctCount == 6);
        system.assert(conCount == 6);
        system.assert(oppCount == 6);
        List<Opportunity> opps = [SELECT Id, PId__c FROM Opportunity];
        String responseMsg = String.join(OpportunityWebServiceHelper.generatePIdOppMap(opps), ',');
        System.assert(responseMsg == RestContext.response.responseBody.toString());
    } 
    @isTest // method tests the same payload as in the setUp method - it verifies that no new records are created
    private static void verifyNoNewRecords(){
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri  = oppApiEndpoint;
        RestContext.request.requestBody = Blob.valueOf(setUpPayload); // note the setUpPayLoad, which was used in the TestSetup method
        RestContext.request.httpMethod  = 'PATCH';
        Test.startTest();
        OpportunityWebService.doPatch();
        Test.stopTest();
        Integer acctCountAfterApiCall = [SELECT COUNT() FROM Account];
        Integer conCountAfterApiCall  = [SELECT COUNT() FROM Contact];
        Integer oppCountAfterApiCall  = [SELECT COUNT() FROM Opportunity];
        
        system.assert(acctCountAfterApiCall == 6);
        system.assert(conCountAfterApiCall == 6);
        system.assert(oppCountAfterApiCall == 6);
        Integer oppsNotUpdated = 0;
        for(Opportunity o : [SELECT CreatedDate, LastModifiedDate FROM Opportunity]) {
            if(o.CreatedDate == o.LastModifiedDate) oppsNotUpdated++;
        }
        // all opps should have been updated, so the createdDate should != lastModified
        system.assert(oppsNotUpdated == 0);
    }
    @isTest // method calls the API with JSON payload that causes a parsing exception - verify the response
    private static void testParsingError() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri  = oppApiEndpoint;
        RestContext.request.requestBody = Blob.valueOf(parseException);
        RestContext.request.httpMethod  = 'PATCH';
        Test.startTest();
        OpportunityWebService.doPatch();
        Test.stopTest();
        String responseMsg = Utils.parseExceptionMsg;
        System.assert(responseMsg == RestContext.response.responseBody.toString());
    }  
    @isTest // method verifies that a PId error message is shown when a payload is provided with a null PId value
    private static void verifyPidNullErrorResponse() {
        RestRequest req = new RestRequest();
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        req.requestUri  = oppApiEndpoint;
        req.requestBody = Blob.valueOf(pidNullPayload);
        req.httpMethod  = 'PATCH';
        RestContext.request = req;
        Test.startTest();
        OpportunityWebService.doPatch();
        Test.stopTest();
        String responseMsg = Utils.pidErrorMsg;
        System.assert(responseMsg == RestContext.response.responseBody.toString());
    } 
    @isTest // method tests two elements in the payload both with Email - verifies that new Account, Contacts and Opps were created
    private static void testCreateAllPhoneContext() {
        RestRequest req = new RestRequest();
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        req.requestUri  = oppApiEndpoint;
        req.requestBody = Blob.valueOf(phoneNewPayload);
        req.httpMethod  = 'PATCH';
        RestContext.request = req;
        Test.startTest();
        OpportunityWebService.doPatch();
        Test.stopTest();
        Integer acctCountAfterApiCall = [SELECT COUNT() FROM Account];
        Integer conCountAfterApiCall  = [SELECT COUNT() FROM Contact];
        Integer oppCountAfterApiCall  = [SELECT COUNT() FROM Opportunity WHERE Pid__c != null];
        system.assert(acctCountAfterApiCall == 8);
        system.assert(conCountAfterApiCall == 8);
        system.assert(oppCountAfterApiCall == 8);
    }
    @isTest // method tests two elements in the payload both with Email - verifies that new Account, Contacts and Opps were created
    private static void testCreateAllEmailContext() {
        Integer acctCount = [SELECT COUNT() FROM Account];
        Integer conCount  = [SELECT COUNT() FROM Contact];
        Integer oppCount  = [SELECT COUNT() FROM Opportunity WHERE Pid__c != null];
        system.assert(acctCount == 6);
        system.assert(conCount == 6);
        system.assert(oppCount == 6);
        RestRequest req = new RestRequest();
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        req.requestUri  = oppApiEndpoint;
        req.requestBody = Blob.valueOf(emailNewPayload);
        req.httpMethod  = 'PATCH';
        RestContext.request = req;
        Test.startTest();
        OpportunityWebService.doPatch();
        Test.stopTest();
        Integer acctCountAfterApiCall = [SELECT COUNT() FROM Account];
        Integer conCountAfterApiCall  = [SELECT COUNT() FROM Contact];
        Integer oppCountAfterApiCall  = [SELECT COUNT() FROM Opportunity WHERE Pid__c != null];
        system.assert(acctCountAfterApiCall == 8);
        system.assert(conCountAfterApiCall == 8);
        system.assert(oppCountAfterApiCall == 8);
    }
    @isTest // method tests phone only context, Contact match with Opp with same pId - and a Con with no match - verifies records created
    private static void verifyNewAndExistingPhonePayload() {
        RestRequest req = new RestRequest();
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        req.requestUri  = oppApiEndpoint;
        req.requestBody = Blob.valueOf(newAndExistingPhone);
        req.httpMethod  = 'PATCH';
        RestContext.request = req;
        Test.startTest();
        OpportunityWebService.doPatch();
        Test.stopTest();
        Integer acctCountPostTest = [SELECT COUNT() FROM Account];
        Integer conCountPostTest  = [SELECT COUNT() FROM Contact];
        Integer oppCountPostTest  = [SELECT COUNT() FROM Opportunity];
        system.assert(oppCountPostTest == 7);
        system.assert(conCountPostTest == 7);
        system.assert(acctCountPostTest == 7);
        Integer countOfOppsUpdated = 0;
        for(Opportunity o : [SELECT CreatedDate, LastModifiedDate FROM Opportunity]) {
            if(o.createdDate != o.LastModifiedDate) countOfOppsUpdated++;
        }
        // also verify that one opp was updated
        system.assert(countOfOppsUpdated == 1);
    } 
    @isTest // method tests email only context, Contact match with Opp with same pId - one new request altogether - verifies records created
    private static void verifyNewAndExistingEmailPayload() {
        RestRequest req = new RestRequest();
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        req.requestUri  = oppApiEndpoint;
        req.requestBody = Blob.valueOf(newAndExistingEmail);
        req.httpMethod  = 'PATCH';
        RestContext.request = req;
        Test.startTest();
        OpportunityWebService.doPatch();
        Test.stopTest();
        Integer acctCountPostTest = [SELECT COUNT() FROM Account];
        Integer conCountPostTest  = [SELECT COUNT() FROM Contact];
        Integer oppCountPostTest  = [SELECT COUNT() FROM Opportunity];
        system.assert(oppCountPostTest == 7);
        system.assert(conCountPostTest == 7);
        system.assert(acctCountPostTest == 7);
        Integer countOfOppsUpdated = 0;
        for(Opportunity o : [SELECT CreatedDate, LastModifiedDate FROM Opportunity]) {
            if(o.createdDate != o.LastModifiedDate) countOfOppsUpdated++;
        }
        // also verify that one opp was updated
        system.assert(countOfOppsUpdated == 1);
    }  
    @isTest // method tests payload for two existing records with no matching opp PId - verify new Opps created under same acct
    private static void createNewOppsAssocToExistingAcct(){
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri  = oppApiEndpoint;
        RestContext.request.requestBody = Blob.valueOf(existingAcctNewOpp);
        RestContext.request.httpMethod  = 'PATCH';
        Test.startTest();
        OpportunityWebService.doPatch();
        Test.stopTest();
        Integer acctCountPostTest = [SELECT COUNT() FROM Account];
        Integer conCountPostTest  = [SELECT COUNT() FROM Contact];
        Integer oppCountPostTest  = [SELECT COUNT() FROM Opportunity];
        system.assert(oppCountPostTest == 8);
        system.assert(conCountPostTest == 6);
        system.assert(acctCountPostTest == 6);
        Integer acctsWithTwoOpps = 0;
        for(Account a : [SELECT Id, (SELECT Id FROM Opportunities) FROM Account]) {
            if (a.Opportunities.size() > 1) acctsWithTwoOpps++;
        }
        system.assert(acctsWithTwoOpps == 2);
    } 
}