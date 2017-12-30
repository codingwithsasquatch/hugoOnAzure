public static void Run(TimerInfo keepaliveTimer, TraceWriter log)
{
    log.Info($"Keepalive Timer trigger function executed at: {DateTime.Now}" );  
}