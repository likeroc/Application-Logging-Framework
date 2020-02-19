/**
    * @author        Saumil Bapat
    * @date          10/17/2016
    * @description   UTIL 类用来记录日志
*/
public class UTIL_Logging{

    //集成日志Id
    public static Id integrationLogId;

    public class Mapping_Exception extends Exception {}
    public class DML_Exception extends Exception {}

    public static final String MAPPING_ERROR_TYPE = 'MAPPING DEFINITION ERROR';
    public static final String DML_ERROR_TYPE = 'DML ERROR';
    public static final String DEBUG_LEVEL_ERROR = 'Error';
    public static final String DEBUG_LEVEL_DEBUG = 'Debug';
    public static final String DEBUG_LEVEL_WARN = 'Warning';
    public static final String DEBUG_LEVEL_INFO = 'Info';

    public Class ExceptionLog{
        Exception ex; //Exception Details
        String className; //Origin Class
        String methodName; //Origin Method
        String triggerName; //Origin Trigger
        String debugLevel; //Severity level of the exception
        Database.UpsertResult upResult; //Upsert results for Database.upsert()

        //Constructor when a exception argument
        public ExceptionLog (exception ex, String className, String methodName, String triggerName, String debugLevel)
        {
            this.ex = ex;
            this.className = className;
            this.methodName = methodName;
            this.triggerName = triggerName;
            this.debugLevel = debugLevel;
        }

        //Constructor with a database.upsertResults argument
        public ExceptionLog (Database.UpsertResult upResult, String className, String methodName, String triggerName, String debugLevel)
        {
            this.upResult = upResult;
            this.className = className;
            this.methodName = methodName;
            this.triggerName = triggerName;
            this.debugLevel = debugLevel;
            if(upResult != null && upResult.getErrors() != null)
            {
                //添加一个自定义的DML异常类型
                String dmlErrorMessage = String.valueOf(upResult.getErrors());
                this.ex = UTIL_Logging.createDMLException(dmlErrorMessage);
            }
        }

        //检查当前用户日志是否启用，及具有的debug级别
        public Boolean isLoggingEnabled()
        {
            Exception_Logging__c exceptionParams = Exception_Logging__c.getInstance();
            Boolean loggingEnabled = exceptionParams.Logging_Enabled__c;
            if (debugLevel == 'Error')
            {
                loggingEnabled = loggingEnabled && exceptionParams.Error__c;
            }
            else if (debugLevel == 'Debug')
            {
                loggingEnabled = loggingEnabled && exceptionParams.Debug__c;
            }
            else if (debugLevel == 'Warning')
            {
                loggingEnabled = loggingEnabled && exceptionParams.Warning__c;
            }
            else if (debugLevel == 'Info')
            {
                loggingEnabled = loggingEnabled && exceptionParams.Info__c;
            }
            return loggingEnabled;
        }

        //返回一个新的Exception_Log__c异常记录
        public Exception_Log__c createExceptionLog()
        {
            Exception_Log__c elog;
            try
            {
                elog =  new Exception_Log__c(
                        Class_Name__c = this.className,
                        Method_Name__c = this.methodName,
                        Trigger_Name__c = this.triggerName,
                        Running_User__c = UserInfo.getUserId(),
                        Exception_Type__c = this.ex.getTypeName(),
                        Source_Integration__c = UTIL_Logging.integrationLogId
                    );
                if(this.ex != null)
                {
                    if(this.ex.getTypeName() == UTIL_Logging.MAPPING_ERROR_TYPE)
                    {
                        //mapping Exception
                        eLog.Error_Message__c= ex.getMessage();
                    }

                    else if (this.ex.getTypeName() == UTIL_Logging.DML_ERROR_TYPE)
                    {
                        //DML Exception
                        eLog.Error_Message__c= ex.getMessage();
                    }

                    else
                    {
                        //Standard Exception
                        eLog.Exception_details__c= buildExceptionDetails(ex);
                        eLog.Exception_Description__c = ex.getMessage().left(Integer.ValueOf(Exception_Logging__c.getInstance().Exception_Description_Max__c));
                        eLog.Error_Message__c= ex.getMessage();
                    }
                }
            }
            catch (Exception e)
            {
                System.Debug('~~~UTIL_Logging.createExceptionLog:e: ' + e.getMessage());
            }

            //return eLog
            return eLog;
        }
    }

    public Static void logException(ExceptionLog log)
    {
        System.Debug('~~~UTIL_Logging.logException: ' + log);
        //exception passed in
        Exception ex = log.ex;

        //初始化一条异常日志记录
        Exception_Log__c elog;

        if (log.isLoggingEnabled())
        {
            system.debug('~~~ex: ' + ex);
            system.debug('~~~ex.getMessage(): ' + ex.getMessage());
            eLog = log.createExceptionLog();
        }
        try
        {
            system.debug('~~~eLog: ' + eLog);
            
            if (eLog != null)
                insert eLog;
        }
        catch (Exception e)
        {
            system.debug('~~~e:' + e);
            System.Debug('~~~e.getMessage(): ' + e.getMessage());
        }
    }

    public Static void logExceptions(List<ExceptionLog> logs)
    {
        List<Exception_Log__c> eLogs = new List<Exception_Log__c>();
        for (ExceptionLog log: logs)
        {
            if (log.isLoggingEnabled())
            {
                //exception passed in
                Exception ex = log.ex;

                system.debug('~~~ex: ' + ex);
                system.debug('~~~ex message: ' + ex.getMessage());

                //创建异常日志
                Exception_Log__c eLog = log.createExceptionLog();
                system.debug('~~~Exception Log: ' + eLog);

                //添加一条日志到集合里，准备插入到数据库
                eLogs.add(eLog);
            }
        }
        try
        {
            //insert eLogs
            if (eLogs.size() > 0)
            insert eLogs;
        }
        catch (Exception e)
        {
            system.debug('~~~e: ' + e);
            System.Debug('~~~Logging Exception: ' + e.getMessage());
        }
    }

    public static string buildExceptionDetails(Exception ex)
    {
        string details = ex.getTypeName()+':'+ex.getMessage()+':'+ex.getStackTraceString();
        return details.left(Integer.ValueOf(Exception_Logging__c.getInstance().Exception_Details_Max__c));
    }


    public static Id createIntegrationLog(String logRecordTypeName, String logPayload, String logProcessName, String logSource, String logTransactionId)
    {
        //获取集成日志自定义设置
        Integration_Logging__c integrationParams = Integration_Logging__c.getInstance();

        //如果日志没有启用，返回
        if(!integrationParams.Logging_Enabled__c)
        {
          return null;
        }

        //初始化一条集成日志记录
        Integration_Log__c intlog;

        try
        {
            intLog = new Integration_Log__c();
            intLog.RecordTypeId = Schema.SObjectType.Integration_Log__c.getRecordTypeInfosByName().get(logRecordTypeName).getRecordTypeId();
            intLog.Pay_Load__c = logPayload.left(Integer.ValueOf(integrationParams.Pay_Load_Max__c));
            intLog.Process_Name__c = logProcessName;
            intLog.Source_System__c = logSource;
            intLog.Transaction_Id__c = logTransactionId;

            System.Debug('~~~intLog: ' + intLog);
            insert intLog;
        }
        catch (Exception e)
        {
            //创建一条异常记录
            UTIL_Logging.ExceptionLog log = new UTIL_Logging.ExceptionLog(e,'UTIL_Logging','createIntegrationLogForESBService','','Error');
            UTIL_Logging.logException(log);
        }
        //设置当前集成日志ID
        UTIL_Logging.integrationLogId = intLog.Id;

        //返回日志ID
        return intLog.Id;
    }

    //Create and return a custom mapping exception
    //创建并返回一个自定义的mapping异常
    public static Exception createMappingException(String exMessage)
    {
        Exception mappingException = new UTIL_Logging.Mapping_Exception(UTIL_Logging.MAPPING_ERROR_TYPE);
        mappingException.setMessage(exMessage);
        return mappingException;
    }

    //Create and return a custom dml Exception
    //创建并返回一个自定义dml异常
    public static Exception createDMLException(String exMessage)
    {
        Exception mappingException = new UTIL_Logging.DML_Exception(UTIL_Logging.DML_ERROR_TYPE);
        mappingException.setMessage(exMessage);
        return mappingException;
    }

}
