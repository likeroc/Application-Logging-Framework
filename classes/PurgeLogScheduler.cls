/**
  * @author        Saumil Bapat
  * @date          10/28/2016
  * @description   Schedulable class to schedule PurgeLogs batch jobs
*/
global class PurgeLogScheduler implements Schedulable{

    global void execute(SchedulableContext sc)
    {
        //Schedule a batch to purge exception logs
        PurgeLogs purgeExceptionLogsBatch = new PurgeLogs(PurgeLogs.LogType.EXCEPTION_LOG);
        Id purgeExceptionLogsBatchId = Database.ExecuteBatch(purgeExceptionLogsBatch);
        
        //Schedule a batch to purge integration logs
        PurgeLogs purgeIntegrationLogsBatch = new PurgeLogs(PurgeLogs.LogType.INTEGRATION_LOG);
        Id purgeIntegrationLogsBatchId = Database.ExecuteBatch(purgeIntegrationLogsBatch);
    }
}