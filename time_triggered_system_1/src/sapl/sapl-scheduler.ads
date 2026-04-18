with HAL;

package SAPL.Scheduler is
   procedure Initialize (tick_rate_hz : HAL.UInt32 := 1000);
   procedure Start;
   procedure Dispatch_Tasks;

   procedure On_Tick;

   type Task_Callback is access procedure;

   type Scheduler_Task is
   record
      --  Task-specific data and state would go here.
      Delay_ticks : Integer;
      Period_ticks : Integer;
      Callback : Task_Callback;
   end record;

   procedure Add_Task (Callback : not null Task_Callback;
      Delay_ticks : Integer; Period_ticks : Integer);

   function Get_Total_Tick_Count return Natural;

end SAPL.Scheduler;