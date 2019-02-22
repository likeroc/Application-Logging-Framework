/**
  * @author        Saumil Bapat
  * @date          10/31/2016
  * @description   Test class for PurgeLogs batch jobs
*/
@isTest
private Class UTIL_Logging_Test {
    //Custom Exception Class
    private Class TestException extends Exception {}

    static testMethod void testLogging() {
        //Create Custom Setting Record
        Exception_Logging__c exceptionParams = new Exception_Logging__c(
                                                                Exception_Description_Max__c = 255,
                                                                Exception_Details_Max__c = 255,
                                                                Exception_Logs_Purge_Days__c = 30,
                                                                Logging_Enabled__c = true,
                                                                Info__c = true,
                                                                Warning__c = true,
                                                                Debug__c = true,
                                                                Error__c = true
                                                            );
        //insert Exception_Logging__c
        insert exceptionParams;

        Integration_Logging__c integrationParams = new Integration_Logging__c(
                                                          Integration_Logs_Purge_Days__c = 30,
                                                          Logging_Enabled__c = true,
                                                          Pay_Load_Max__c = 100000
                                                        );

        //insert Integration_Logging__c
        insert integrationParams;

        //Create Test User
        Profile SysAdmin = [Select id from Profile where Name = 'System Administrator' limit 1];
        User testUser = new User(
            firstname = 'testFirstName',
            lastName = 'testLastName',
            email = 'test@test.org',
            Username = 'test@test.org',
            EmailEncodingKey = 'ISO-8859-1',
            Alias ='tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = SysAdmin.Id
        );

        /*Create Integration Log*/
        Map <String,Schema.RecordTypeInfo> integrationLogRecordTypes = Integration_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id inboundRT = integrationLogRecordTypes.get('INBOUND').getRecordTypeId();
        UTIL_Logging.integrationLogId = UTIL_Logging.createIntegrationLog(
                                                inboundRT,
                                                'Test Payload',
                                                'Test Process Name',
                                                'Test Source Name',
                                                'Test Transaction Id'
                                            );

        Exception singleException = UTIL_Logging.createMappingException(
                'Test Mapping Error'
            );

        //Create upsert based exception log
        UTIL_Logging.ExceptionLog singleExceptionLog = new UTIL_Logging.ExceptionLog(
                singleException,
                'UTIL_Logging_Test',
                'testLogging',
                '',
                'Error'
            );

        //Insert exception logs
        UTIL_Logging.logException(singleExceptionLog);

        //Instantiate a new case
        Case c = new Case();

        //Upsert Case
        Database.UpsertResult caseUpsertResults = Database.Upsert(c);

        Exception dmlError = UTIL_Logging.createDMLException(
                'Test DML Error'
            );


        //Create upsert based exception log
        UTIL_Logging.ExceptionLog upsertLog = new UTIL_Logging.ExceptionLog(
                caseUpsertResults,
                'UTIL_Logging_Test',
                'testLogging',
                '',
                'Error'
            );

        //Test exception log based on type
        UTIL_Logging.logException(upsertLog);

        //Test method for multi-exception logging
        List<UTIL_Logging.ExceptionLog> logs = new List<UTIL_Logging.ExceptionLog>();

        //Create 10 Exception log records of each type
        for (Integer i=1; i<=10; i++)
        {
            //Initialize a custom exception
            Exception mappingError = UTIL_Logging.createMappingException(
                'Test Mapping Error: ' + +' ' + String.ValueOf(i)
            );

            //Create a info log record
            UTIL_Logging.ExceptionLog  infoLog = new UTIL_Logging.ExceptionLog(
                mappingError,
                'PurgeLogSchedulerTest',
                'testScheduledPurgeLogs',
                '',
                'Info'
            );
            logs.add(infoLog);

            //Create a info log record
            UTIL_Logging.ExceptionLog  warningLog = new UTIL_Logging.ExceptionLog(
                mappingError,
                'PurgeLogSchedulerTest',
                'testScheduledPurgeLogs',
                '',
                'Warning'
            );
            logs.add(warningLog);

            //Create a debug log record
            UTIL_Logging.ExceptionLog  debugLog = new UTIL_Logging.ExceptionLog(
                dmlError,
                'PurgeLogSchedulerTest',
                'testScheduledPurgeLogs',
                '',
                'Debug'
            );
            logs.add(debugLog);

            //Create a error log record
            UTIL_Logging.ExceptionLog  errorLog = new UTIL_Logging.ExceptionLog(
                dmlError,
                'PurgeLogSchedulerTest',
                'testScheduledPurgeLogs',
                '',
                'Error'
            );
            logs.add(errorLog);


        }
        //Insert exception logs
        UTIL_Logging.logExceptions(logs);
    }

    //test for trying to insert a integration log with a invalid RT
    static testMethod void testInvalidIntegrationRT()
    {
        try
        {
        /*Create Integration Log*/
        UTIL_Logging.integrationLogId = UTIL_Logging.createIntegrationLog(
                                                'Invalid RecordType',
                                                'Test Payload',
                                                'Test Process Name',
                                                'Test Source Name',
                                                'Test Transaction Id'
                                            );

        }
        catch (Exception e)
        {
            System.Debug('~~~Expected Exception: ' + e.getMessage());
        }
    }
}
