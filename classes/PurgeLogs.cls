/**
  * @author        Saumil Bapat
  * @date          10/28/2016
  * @description   批处理类删除老日志
*/
global class PurgeLogs implements Database.Batchable<sObject>
{
   //删除日志的类型
   global enum LogType{INTEGRATION_LOG, EXCEPTION_LOG}

   //查询日志删除
   global String query;

   //查询日志删除
   global LogType type;

   //构造函数
   global PurgeLogs(LogType type)
   {
      //获取异常日志的设置
      Exception_Logging__c exceptionParams = Exception_Logging__c.getInstance();

      //获取集成日志的设置
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
