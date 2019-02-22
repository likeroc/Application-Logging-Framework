1. 1.Salesforce Application Logging Framework

To promote reuse and provide a framework for handling common coding patterns, the team should use the following classes.  They will be created first and reused by the whole team.  Additions to the class functionality will be communicated to the wider team.

In order to use the ApplicationLog class there are 3 things you have to do

1. Create the Application\_Log\_\_c object
2. Create the System\_Setting\_\_c custom setting object
3. Create the ApplicationLogWrapper class
4. Create the ApplicationLog class

| **Artefact** | **Purpose** |
| --- | --- |
| System Setting Custom Setting | Object to hold what types of messages to log and how long to keep them for |
| Application Log Object | Object to hold custom exception messages |
| ApplicationLog | Utility class to provide methods for application logging |
| ApplicationLogWrapper | Wrapper class of exception objects that can be used to log exception messages in bulk for trigger scenarios |

**How the error logging works:**

- The utility class has an overloaded method (LogMessage) to accept a number of parameter options
- A wrapper class (ApplicationLogWrapper) encapsulates all logging attributes
- Triggers can build up a collection of wrapper objects and pass them to the LogMessage method to ensure only 1 DML statement per trigger transaction
  -
    - public static void logMessage(String logLevel, String sourceClass, String sourceFunction, String referenceId, String referenceInfo, String logMessage, String payLoad, Exception ex, long timeTaken)
    - public static void logMessage(ApplicationLogWrapper appLog)
    - public static void logMessage(List\&lt;ApplicationLogWrapper\&gt; appLogs)
- The utility class checks against the System\_Settings\_\_c custom setting to see if the type of message should be logged based on their current values allowing support staff to turn on/off debug levels
- Scheduled nightly batch job to purge records older than x days (from custom setting)

1.
  1. **1.1.** Application Log Object

| **Field** | **Type** | **Required** | **Description** |
| --- | --- | --- | --- |
| Age | Formula | N | Age of the record in days (used to purge the table) |
| Debug Level | Picklist | Y | Error, Info, Warning, Debug |
| Integration Payload | Long Text Area | N | If log is integration related show xml payload |
| Log Code | Text (50) | N | Either the exception error code of custom org code for record |
| Message | Long Text Area | N | Message to log |
| Reference Id | Text (18) | N | The related record id |
| Reference Info | Text (255) | N | The related record info (e.g. Apex Batch Job Id, Contact etc) |
| Source | Text (150) | Y | The originating class (e.g. CustomerManagement) |
| Source Function | Text (200) | Y | The originating function in the class (e.g. UpdateDivision() ) |
| Stack Trace | Long Text Area | N | Raw exception stack trace for unhandled errors |
| Timer | Number (18,0) | N | The time in milliseconds for the transaction (e.g. For integration/batch apex messages it might be the time taken to process) |

1.
  1. **1.2.** System Setting Custom Setting

| **Field** | **Type** | **Required** | **Description** |
| --- | --- | --- | --- |
| Debug | Checkbox | Y | True – log debug messages in this org |
| Info | Checkbox | Y | True – log info messages in this org |
| Warning | Checkbox | Y | True – log warning messages in this org |
| Error | Checkbox | Y | True – log errors in this org |
| Log Purge (Days) | Number (2,0) | Y | The number of days of logs to keep |

1.
  1. **1.3.** ApplicationLogWrapper Class

publicclass ApplicationLogWrapper {

/\*------------------------------------------------------------

Author:        \&lt;company\&gt; Developer

Company:       \&lt;company\&gt;

Description:   A wrapper class for application log messages

Test Class:         GlobalUtility\_Test

History

\&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

------------------------------------------------------------\*/

    public string source {get;set;}

    public string sourceFunction {get;set;}

    public string referenceId {get;set;}

    public string referenceInfo{get;set;}

    public string logMessage {get;set;}

    public string payload {get;set;}

    public Exception ex {get;set;}

    public string debugLevel {get;set;}

    public string logCode {get;set;}

    publiclong timer {get;set;}

}

1.
  1. **1.4.** Application Log

/\*------------------------------------------------------------

Author:        \&lt;Authors Name\&gt;

Company:       \&lt;company\&gt;

Description:   ApplicationLog – log a message to the application log

Test Class:

History

\&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

------------------------------------------------------------\*/

publicwithoutsharingclass ApplicationLog {

publicstaticvoid logMessage(String logLevel, String sourceClass, String sourceFunction, String referenceId, String referenceInfo, String logMessage, String payLoad, Exception ex, long timeTaken) {

    /\*------------------------------------------------------------

    Author:        \&lt;Authors Name\&gt;

    Company:       \&lt;company\&gt;

    Description:   Overloaded Method to log a single record to the application log

    Inputs:        logLevel - Debug, Error, Info, Warning

                   sourceClass - Originating trigger or utility class

                   sourceFunction - Method in class above that caused the message

                   referneceId - Process Identifier (e.g. Job Id)

                   referenceInfo - Process information

                   payLoad - Optional based on integration messages

                   ex - the standard exception object for errors

                   timeTaken - The time in milliseconds of the transaction

    History

    \&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

    ------------------------------------------------------------\*/

        ApplicationLogWrapper msg = new ApplicationLogWrapper();

        msg.source = sourceClass;

        msg.logMessage = logMessage;

        msg.sourceFunction = sourceFunction;

        msg.referenceId = referenceId;

        msg.referenceInfo = referenceInfo;

        msg.payload = payLoad;

        msg.debugLevel = logLevel;

        msg.ex = ex;

        msg.Timer = timeTaken;

        // System.Debug(&#39;@@@AppMsg 1&#39;);

        logMessage( msg );

    }

    publicstaticvoid logMessage(ApplicationLogWrapper appLog)

    {

    /\*------------------------------------------------------------

    Author:        \&lt;Authors Name\&gt;

    Company:       \&lt;company\&gt;

    Description:   Overloaded Method to log a single record to the application log table

    Inputs:        The application log wrapper object

    History

    \&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

    ------------------------------------------------------------\*/

        List\&lt;ApplicationLogWrapper\&gt; appLogs = new List\&lt;ApplicationLogWrapper\&gt;();

        appLogs.add ( appLog );

        // System.Debug(&#39;@@@AppMsg 2&#39;);

        logMessage ( appLogs );

    }

    publicstaticvoid logMessage(List\&lt;ApplicationLogWrapper\&gt; appLogs)

    {

    /\*------------------------------------------------------------

    Author:        \&lt;Authors Name\&gt;

    Company:       \&lt;company\&gt;

    Description:   Overloaded Method to log multiple records to the application log

                   Called directly from trigger context to prevent governor limit   exceptions

    Inputs:        The application log wrapper object

    History

    \&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

    ------------------------------------------------------------\*/

        List\&lt;Application\_Log\_\_c\&gt; insertAppLogs = new List\&lt;Application\_Log\_\_c\&gt;();

        // System.Debug(&#39;@@@AppMsg 3&#39;);

        for(ApplicationLogWrapper appLog : appLogs){

            Application\_Log\_\_c log = new Application\_Log\_\_c();

            log.Source\_\_c = appLog.source;

            log.Source\_Function\_\_c = appLog.sourceFunction;

            log.Reference\_Id\_\_c = appLog.referenceId;

            log.Reference\_Information\_\_c = appLog.referenceInfo;

            log.Message\_\_c = appLog.logMessage;

            log.Integration\_Payload\_\_c = appLog.payload;

            if(appLog.ex != null){

                log.Stack\_Trace\_\_c = appLog.ex.getStackTraceString();

                log.Message\_\_c = applog.ex.getMessage();

                //log.Exception\_Type\_\_c = applog.ex.getTypeName();

            }

            log.Debug\_Level\_\_c = appLog.debugLevel;

            log.Log\_Code\_\_c = appLog.logCode;

            log.Timer\_\_c = appLog.timer;

            boolean validInsert = false;

            if(appLog.debugLevel == GlobalConstants.DEBUG &amp;&amp; System\_Settings\_\_c.getInstance().Debug\_\_c){

                validInsert = true;

            } else if

            (appLog.debugLevel == GlobalConstants.ERROR &amp;&amp; System\_Settings\_\_c.getInstance().Error\_\_c){

                validInsert = true;

            } else if

            (appLog.debugLevel == GlobalConstants.INFO &amp;&amp; System\_Settings\_\_c.getInstance().Info\_\_c){

                validInsert = true;

            } else if

            (appLog.debugLevel == GlobalConstants.WARNING &amp;&amp; System\_Settings\_\_c.getInstance().Warning\_\_c){

                validInsert = true;

            }

            if(validInsert){

                insertAppLogs.add(log);

                System.Debug(&#39;Inserted Log from &#39; + log.source\_\_c + &#39; debug level: &#39; + log.Debug\_Level\_\_c);

            }

        }

        if ( insertAppLogs.size() != 0 ){

            insert insertAppLogs;

        }

    }

}

1.
  1. **1.5.** Purge Application Log

Requires two classes – a batchable class to do the work, and a schedulable class to schedule the job

**purgeApplicationLog**

global class purgeApplicationLog implements Database.Batchable\&lt;sObject\&gt;{

        global final String Query;

    global purgeApplicationLog(String q){

        Query=q;

    }

    global Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator(query);

    }

    global void execute(Database.BatchableContext BC,List\&lt;Application\_Log\_\_c\&gt; scope){

            delete scope;

    }

    global void finish(Database.BatchableContext BC){}

}

**AppLogPurgeScheduler**

global class AppLogPurgeScheduler implements Schedulable{

    global void execute(SchedulableContext sc){

        String logPurgeDays = string.valueof(System\_Settings\_\_c.getInstance().Log\_Purge\_Days\_\_c);

        String query = &#39;select id from Application\_Log\_\_c where LastModifiedDate != LAST\_N\_DAYS:&#39; + logPurgeDays;

        purgeApplicationLog delBatch = new purgeApplicationLog(query);

        Id BatchProcessId = Database.ExecuteBatch(delBatch);

    }

}

**Finally – setup the scheduled APEX job using the UI**

1.
  1. **1.6.** ApplicationLogTest -  Test Class

@IsTest

public with sharing class ApplicationLogTest {

   public class MyException extends Exception{}

   public static testmethod void TestLog() {

Test.startTest();

        try{

               throw new MyException(&#39;some bad stuff just happened&#39;);

        }

        catch(MyException e){

              ApplicationLog.logMessage(&#39;Error&#39;, &#39;ApplicationLogSample&#39;, &#39;SampleMethod&#39;, &#39;Some reference Id&#39;, &#39;Some reference info&#39;, &#39;Some log message details&#39;, &#39;some payload details&#39;, e, 0);

        }

        Test.stopTest();

   }

}

1.
  1. **1.7.** Global Cache

publicclass GlobalCache {

/\*------------------------------------------------------------

Author:        \&lt;Authors Name\&gt;

Company:       \&lt;company\&gt;

Description:   A global utility class for caching data

               Supports:

1. Record Types
2. Profile Names

Test Class:

History

\&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

------------------------------------------------------------\*/

    //maps to hold the record type info

    privatestatic Map\&lt;String, Schema.SObjectType\&gt; gd;

    privatestatic Map\&lt;String,Map\&lt;Id,Schema.RecordTypeInfo\&gt;\&gt; recordTypesById = new Map\&lt;String,Map\&lt;Id,Schema.RecordTypeInfo\&gt;\&gt;();

    privatestatic Map\&lt;String,Map\&lt;String,Schema.RecordTypeInfo\&gt;\&gt; recordTypesByName = new Map\&lt;String,Map\&lt;String,Schema.RecordTypeInfo\&gt;\&gt;();

    privatestatic Map\&lt;String, String\&gt; profileMap = new Map\&lt;String,String\&gt;();

    privatestaticvoid fillMapsForRecordTypeObject(string objectName) {

    /\*------------------------------------------------------------

    Author:        \&lt;Authors Name\&gt;

    Company:       \&lt;company\&gt;

    Description:   Function to fill record type map for objects not in cache

    Inputs:        objectName - The name of the sObject

    Returns:       Nothing

    History

    \&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

    ------------------------------------------------------------\*/

        // get the object map the first time

        if (gd==null) gd = Schema.getGlobalDescribe();

        // get the object description

        if (gd.containsKey(objectName)) {

            Schema.DescribeSObjectResult d = gd.get(objectName).getDescribe();

            recordTypesByName.put(objectName, d.getRecordTypeInfosByName());

            recordTypesById.put(objectName, d.getRecordTypeInfosById());

        }

    }

    publicstatic Id getRecordTypeId(String objectName, String recordTypeName) {

    /\*------------------------------------------------------------

    Author:        \&lt;Authors Name\&gt;

    Company:       \&lt;company\&gt;

    Description:   Gives record type id from a given sObject and record type label

    Inputs:        objectName - The sObject

                   recordTypeName - The name of the record type (NOT the API Name)

    Returns:       The specified record types id value

    History

    \&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

    ------------------------------------------------------------\*/

        // make sure we have this object&#39;s record types mapped

        if (!recordTypesByName.containsKey(objectName))

            fillMapsForRecordTypeObject(objectName);

        // now grab and return the requested id

        Map\&lt;String,Schema.RecordTypeInfo\&gt; rtMap = recordTypesByName.get(objectName);

        if (rtMap != null &amp;&amp; rtMap.containsKey(recordTypeName)) {

            return rtMap.get(recordTypeName).getRecordTypeId();

        } else {

            returnnull;

        }

    }

    publicstatic String getRecordTypeName(String objectName, Id recordTypeId) {

    /\*------------------------------------------------------------

    Author:        \&lt;Authors Name\&gt;

    Company:       \&lt;company\&gt;

    Description:   Gives record type name from a given sObject and record type id

    Inputs:        objectName - The sObject

                   recordTypeId - The id of the record type

    Returns:       The specified record types name value (the label NOT the API name)

    History

    \&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

    ------------------------------------------------------------\*/

        // make sure we have this object&#39;s record types mapped

        if (!recordTypesById.containsKey(objectName))

            fillMapsForRecordTypeObject(objectName);

        // now grab and return the requested id

        Map\&lt;Id,Schema.RecordTypeInfo\&gt; rtMap = recordTypesById.get(objectName);

        if (rtMap != null &amp;&amp; rtMap.containsKey(recordTypeId)) {

            return rtMap.get(recordTypeId).getName();

        } else {

            returnnull;

        }

    }

    publicstatic String getProfileName(String userProfileId) {

    /\*------------------------------------------------------------

    Author:        \&lt;Authors Name\&gt;

    Company:       \&lt;company\&gt;

    Description:   Get the profileName for the userProfileId

    Inputs:        String - the profile id

    Returns:       String - the name of the profile

    History

    \&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

    ------------------------------------------------------------\*/

        if (!profileMap.containsKey(userProfileId)) {

            Profile profileName = [Select Id, Name from Profile where Id=:userProfileId];

            profileMap.put(userProfileId, profileName.Name);

        }

        return profileMap.get(userProfileId);

    }

}

1.
  1. **1.8.** Global Constants

/\*------------------------------------------------------------

Author:        \&lt;Authors Name\&gt;

Company:       \&lt;company\&gt;

Description:   A global constants class

Test Class:

History

\&lt;Date\&gt;      \&lt;Authors Name\&gt;     \&lt;Brief Description of Change\&gt;

------------------------------------------------------------\*/

publicwithsharingclass GlobalConstants {

    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}

    /\*\*\*\*\*\*\*INTEGRATION CONSTANTS\*\*\*\*\*\*\*/

    //GENERAL

    public static final String NONE = &#39;None&#39;;

    public static final String DEBUG = &#39;Debug&#39;;

    public static final String ERROR = &#39;Error&#39;;

    public static final String INFO = &#39;Info&#39;;

    public static final String WARNING = &#39;Warning&#39;;

    //TESTING LITERALS

    public static final String FNAME = &#39;Test&#39;;

    public static final String LNAME = &#39;User&#39;;

    public static final String EMAIL = &#39;testuser@\&lt;company\&gt;.com&#39;;

    public static final String COMPANY = &#39;\&lt;company\&gt;.com&#39;;

    public static final String TITLE = &#39;testuser&#39;;

    public static final String USERNAME = &#39;testuser@\&lt;company\&gt;.com&#39;;

    public static final String ALIAS = &#39;testuser&#39;;

    public static final String LOCALE = &#39;en\_US&#39;;

    public static final String TZSID = &#39;America/Mexico\_City&#39;;

    public static final String EMAILENCODING = &#39;ISO-8859-1&#39;;

    public static final String NICKNAME = &#39;Test User&#39;;

    //PRODUCTS

    public static final String EIS = &#39;EIS&#39;;

    public static final String UBM = &#39;UBM&#39;;

    public static final String DR = &#39;D/R&#39;;

    /\*\*\*\*\*\*\*ERROR MESSAGES\*\*\*\*\*\*\*/

    public static final String MIN\_36\_MO\_TERM = &#39;does not have at least 36 month sow term.&#39;;

}

1. 2.Application Log User Interface
  1. **2.1.** Error Log

The screenshot below shows an example for errors logged by the application that developers are responsible for unit testing as part of their test classes

1.
  1. **2.2.** Debug

The screenshot below shows an example for debug logged by the application that developers are d for unit testing as part of their test classes. In the example below the developer is logging an Apex callout including the payload and timing criteria.


1.
  1. **2.3.** Info

The screenshot below shows an example for information logged by the application that developers are responsible for unit testing as part of their test classes. In the example below the developer is logging information about an Apex batch job for auditing purposes.  They have included time taken for the job to run and some useful attributes for support.
