# codingChallenge2021
Per this coding challenge, a custom REST Apex API has been created and is accessible at:

https://curious-goat-7rtx4v-dev-ed.my.salesforce.com/services/apexrest/Opportunity 
HTTP Method - PATCH

**** NOTE: a Connected App with OAUTH 2.0 authentication was created, so a token is required (session times out after 24 hrs of inactivity) ******

Valid JSON format: 
[
{"pid":1,"email":"x@abc.com","phone":"1234567890","fname":"x","lname":"xx"},
{"pid":2,"email":"y@youAndMe.com","phone":2125550000,"fname":"y","lname":"yy"}
]

When calling this API and providing a valid payload, Salesforce will do the following:
1. if email is not empty in the message, search for an existing contact record with matching email address
2. if email is missing in the message, search for an existing contact in sfdc with matching phone number.
3. if a matching contact is found in sfdc 
  ● create a new opportunity in sfdc under that account , if there is no opportunity with a matching pid.
  ● if there is an opportunity in sfdc with matching pid under that account, update the existing opportunity
5. if no matching email or phone in sfdc, create account/contact for this user and create a new opportunity record under that account for that message.
