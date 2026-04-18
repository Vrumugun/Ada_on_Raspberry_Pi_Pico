with SAPL.Processor;
with SAPL.Scheduler;
with SAPL.Heartbeat;
with SAPL.Watchdog;
with SAPL.Version;
with COM.Debug;

procedure Time_Triggered_System_1 is
   Message : constant String := "Time triggered system 1 - Version: " &
       SAPL.Version.Firmware_Version & Character'Val (13) & Character'Val (10);
begin
   SAPL.Processor.Initialize;
   SAPL.Watchdog.Initialize (1100);
   SAPL.Heartbeat.Initialize;
   COM.Debug.Initialize;
   SAPL.Scheduler.Initialize (1000);

   SAPL.Scheduler.Add_Task
      (Callback     => COM.Debug.Update'Access,
      Delay_ticks  => 0,
      Period_ticks => 2);

   SAPL.Scheduler.Add_Task
      (Callback     => SAPL.Heartbeat.Update'Access,
      Delay_ticks  => 0,
      Period_ticks => 1000);

   SAPL.Scheduler.Add_Task
      (Callback     => SAPL.Watchdog.Update'Access,
      Delay_ticks  => 1,
      Period_ticks => 1000);

   COM.Debug.Put_Tx_String (Message);

   SAPL.Scheduler.Start;

   loop
      SAPL.Scheduler.Dispatch_Tasks;
   end loop;
end Time_Triggered_System_1;
