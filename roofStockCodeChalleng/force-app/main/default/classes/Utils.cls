public with sharing class Utils {

    public static final String context              = 'Context';
    public static final String phoneContext         = 'Phone';
    public static final String emailContext         = 'Email';
    public static final String phoneAndEmailContext = 'Email and Phone';
    public static final String validity             = 'Validity';
    public static final String valid                = 'Valid';
    public static final String invalid              = 'Invalid';
    public static final String parseExceptionMsg    = '{"Error":"An error occurred while deserializing your request - please ensure your JSON request is valid"}';
    public static final String pidErrorMsg          = '{"Error":"Pid(s) cannot be null"}';
    public static final String pIds                 = 'pIds';
    public static final String emails               = 'Emails';
    public static final String phones               = 'Phones';
    public static final String emailRequests        = 'Email Requests';
    public static final String phoneRequests        = 'Phone Requests';
    public static final String newStage             = 'New';
    public static final Date   twoWeeksFromNow      = (Date.newInstance(System.now().year(), System.now().month(), System.now().day())).addDays(14);
    public static integer      count                = 0;

    
}
