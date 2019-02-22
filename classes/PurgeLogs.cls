/**
  * @author        Saumil Bapat
  * @date          10/28/2016
  * @description   Batch class to delete old logs
*/
global class PurgeLogs implements Database.Batchable<sObject>
{
   //Type of log to delete
   global enum LogType{INTEGRATION_LOG, EXCEPTION_LOG}

   //Query of logs to delete
   global String query;

   //Query of logs to delete
   global LogType type;

   //Constructor to instantiate the query
   global PurgeLogs(LogType type)
   {
      //Retrieve the exception logging settings
      Exception_Logging__c exceptionParams = Exception_Logging__c.getInstance();

      //Retrieve the integration logging settings
      Integration_Logging__c integrationParams = Integration_Logging__c.getInstance();
      
      if (type == LogType.INTEGRATION_LOG)
      {
         this.query = 'Select Id from Integration_Log__c where LastModifiedDate != LAST_N_DAYS:' + integrationParams.Integration_Logs_Purge_Days__c;
         this.type = LogType.INTEGRATION_LOG;
      }
      if (type == LogType.EXCEPTION_LOG)
      {
         this.query = 'Select Id from Exception_Log__c where LastModifiedDate != LAST_N_DAYS:' + exceptionParams.Exception_Logs_Purge_Days__c;
         this.type = LogType.EXCEPTION_LOG;
      }
   }

   //Start method for the batch
   global Database.QueryLocator start(Database.BatchableContext BC)
   {
      return Database.getQueryLocator(query);
   }

   //Execute method for the batch
   global void execute(Database.BatchableContext BC,List<SObject> scope)
   {
      delete scope;
   }

   //Finish method for the batch
   global void finish(Database.BatchableContext BC){}
}