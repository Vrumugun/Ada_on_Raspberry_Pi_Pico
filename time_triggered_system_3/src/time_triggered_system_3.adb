with SAPL.Processor;
with SAPL.Scheduler;
with SAPL.Heartbeat;
with SAPL.Watchdog;
with SAPL.Input;
with SAPL.Output;
with SAPL.Version;
with SAPL.State_Machine;
with COM.Debug;
with COM.Cross;

procedure Time_Triggered_System_3 is
   Message : constant String := "Time triggered system 3 - Version: " &
       SAPL.Version.Firmware_Version & Character'Val (13) & Character'Val (10);
begin
   SAPL.Processor.Initialize;
   SAPL.Watchdog.Initialize (1100);
   SAPL.Heartbeat.Initialize;
   SAPL.Input.Initialize;
   SAPL.Output.Initialize;
   SAPL.State_Machine.Initialize;
   COM.Debug.Initialize;
   COM.Cross.Initialize;
   SAPL.Scheduler.Initialize (1000);

   SAPL.Scheduler.Add_Task
      (Callback     => SAPL.Input.Update'Access,
      Delay_ticks  => 0,
      Period_ticks => 1);

   SAPL.Scheduler.Add_Task
      (Callback     => COM.Cross.Update_Rx'Access,
      Delay_ticks  => 0,
      Period_ticks => 1);

   SAPL.Scheduler.Add_Task
      (Callback     => COM.Debug.Update'Access,
      Delay_ticks  => 0,
      Period_ticks => 2);

   SAPL.Scheduler.Add_Task
      (Callback     => COM.Cross.Update_Tx'Access,
      Delay_ticks  => 1,
      Period_ticks => 2);

   SAPL.Scheduler.Add_Task
      (Callback     => SAPL.Output.Update'Access,
      Delay_ticks  => 2,
      Period_ticks => 4);

   SAPL.Scheduler.Add_Task
      (Callback     => SAPL.State_Machine.Update'Access,
      Delay_ticks  => 8,
      Period_ticks => 16);

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
end Time_Triggered_System_3;
