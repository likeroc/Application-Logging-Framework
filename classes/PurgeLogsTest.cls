/**
  * @author        Saumil Bapat
  * @date          10/31/2016
  * @description   Test class for PurgeLogs batch jobs
*/
@isTest
private class PurgeLogsTest {


  static testmethod void testExceptionsPurgeBatch() {

    //Initialize the custom setting records
    initializeCustomSettings();

    //Initialize list of exception logs
    List<UTIL_Logging.ExceptionLog> logs = new List<UTIL_Logging.ExceptionLog>();

    //Create 10 Exception log records
    for (Integer i=1; i<=10; i++) {

      //Initialize a custom exception
      Exception e = UTIL_Logging.createMappingException(
          'Test Mapping Error: ' + +' ' + String.ValueOf(i)
      );

      //Create a exception log record
      UTIL_Logging.ExceptionLog log = new UTIL_Logging.ExceptionLog(
        e,
        'PurgeLogsTest',
        'testExceptionsPurgeBatch',
        '',
        'Error'
      );

      //add exception log to list
      logs.add(log);
    }

    //Insert exception logs
    UTIL_Logging.logExceptions(logs);

    //Verify 10 exception logs were created
    Integer logCount= [SELECT COUNT() FROM Exception_Log__c];
    System.assertEquals(logCount, 10);

    //Execute the batch jobs
    Test.startTest();
    PurgeLogs purgeExceptionLogsBatch = new PurgeLogs(PurgeLogs.LogType.EXCEPTION_LOG);
    purgeExceptionLogsBatch.query = 'Select Id from Exception_Log__c';
    Id purgeExceptionLogsBatchId = Database.ExecuteBatch(purgeExceptionLogsBatch);
    Test.stopTest();

    //Verify the logs have been deleted
    logCount= [SELECT COUNT() FROM Exception_Log__c];
    System.assertEquals(logCount, 0);
  }

  static testmethod void testIntegrationPurgeBatch() {

    //Initialize the custom setting records
    initializeCustomSettings();

    //Create integration log
    UTIL_Logging.integrationLogId = UTIL_Logging.createIntegrationLog(
                                                      'INBOUND',
                                                      'Test Payload', 
                                                      'Test Process Name',
                                                      'Test Source Name',
                                                      'Test Transaction Id'
                                                    );

    //Verify a integration logs was created
    Integer logCount= [SELECT COUNT() FROM Integration_Log__c];
    System.assertEquals(logCount, 1);

    //Execute the batch jobs
    Test.startTest();
    PurgeLogs purgeExceptionLogsBatch = new PurgeLogs(PurgeLogs.LogType.INTEGRATION_LOG);
    purgeExceptionLogsBatch.query = 'Select Id from Integration_Log__c';
    Id purgeExceptionLogsBatchId = Database.ExecuteBatch(purgeExceptionLogsBatch);
    Test.stopTest();

    //Verify the logs have been deleted
    logCount= [SELECT COUNT() FROM Integration_Log__c];
    System.assertEquals(logCount, 0);
  }

  private static void initializeCustomSettings()
  {
    //Create exception logging Custom Setting Record
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

    //Create integration log custom setting record
    Integration_Logging__c integrationParams = new Integration_Logging__c(
                                                    Integration_Logs_Purge_Days__c = 30,
                                                    Logging_Enabled__c = true,
                                                    Pay_Load_Max__c = 100000
                                                      );

    //insert Integration_Logging__c
    insert integrationParams;
  }
}
