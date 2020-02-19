/**
  * @author        Saumil Bapat
  * @date          10/28/2016
  * @description   Schedulable class来预定清理日志工作
*/
global class PurgeLogScheduler implements Schedulable{

    global void execute(SchedulableContext sc)
    {
        //安排批处理以清除异常日志
        PurgeLogs purgeExceptionLogsBatch = new PurgeLogs(PurgeLogs.LogType.EXCEPTION_LOG);
        Id purgeExceptionLogsBatchId = Database.ExecuteBatch(purgeExceptionLogsBatch);
        
        //安排批处理以清除集成日志
        PurgeLogs purgeIntegrationLogsBatch = new PurgeLogs(PurgeLogs.LogType.INTEGRATION_LOG);
        Id purgeIntegrationLogsBatchId = Database.ExecuteBatch(purgeIntegrationLogsBatch);
    }
}
