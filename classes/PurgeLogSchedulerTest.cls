/**
  * @author        Saumil Bapat
  * @date          10/31/2016
  * @description   Test class for PurgeLogs batch jobs
*/
@isTest
private class PurgeLogSchedulerTest {

   // CRON expression: midnight on March 15.
   // Because this is a test, job executes
   // immediately after Test.stopTest().
   public static String CRON_EXP = '0 0 0 15 3 ? 2050';

   static testmethod void testScheduledPurgeLogs() {

     //Initialize the custom settings records
     initializeCustomSettings();

      /*Create Integration Log*/
      UTIL_Logging.integrationLogId = UTIL_Logging.createIntegrationLog(
                                                         'INBOUND',
                                                         'Test Payload',
                                                         'Test Process Name',
                                                         'Test Source Name',
                                                         'Test Transaction Id'
                                                       );

      /*Create Exception Logs*/
      //Initialize list of exception logs
      List<UTIL_Logging.ExceptionLog> logs = new List<UTIL_Logging.ExceptionLog>();

      //Create 10 Exception log records
      for (Integer i=1; i<=10; i++) {

         //Initialize a custom mapping exception
         Exception e = UTIL_Logging.createMappingException(
            'Test Mapping Error: ' + +' ' + String.ValueOf(i)
         );

         //Create a exception log record
         UTIL_Logging.ExceptionLog log = new UTIL_Logging.ExceptionLog(
            e,
            'PurgeLogSchedulerTest',
            'testScheduledPurgeLogs',
            '',
            'Error'
         );

         //add exception log to list
         logs.add(log);
      }

      //Insert exception logs
      UTIL_Logging.logExceptions(logs);

      // Verify the integration logs have been created
      List<Integration_Log__c> integrationLogs = [SELECT Id FROM Integration_Log__c];
      System.assertEquals(integrationLogs.size(),1);

      //Verify the exception logs have been created
      List<Exception_Log__c> exceptionLogs = [SELECT Id FROM Exception_Log__c];
      System.assertEquals(exceptionLogs.size(),10);

      //Initiate the scheduled & batch purge jobs
      Test.startTest();

      // Schedule the test job
      String jobId = System.schedule('testScheduledPurgeLogs', CRON_EXP, new PurgeLogScheduler());

      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same
      System.assertEquals(CRON_EXP, ct.CronExpression);

      // Verify the job has not run
      System.assertEquals(0, ct.TimesTriggered);

      // Verify the next time the job will run
      System.assertEquals('2050-03-15 00:00:00', String.valueOf(ct.NextFireTime));

      //Process the scheduled & batch purge jobs
      Test.stopTest();
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
