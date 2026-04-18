with COM.Debug;
with SAPL.Processor;

with RP2040_SVD.Interrupts;
with RP2040_SVD.TIMER; use RP2040_SVD.TIMER;
with RP_Interrupts;
with System;

package body SAPL.Scheduler is
   use type HAL.UInt32;

   Tick_Interval_Us : HAL.UInt32 := 1000;
   Task_List : array (Natural range 1 .. 10) of Scheduler_Task;
   Task_Count : Natural := 0;
   Tick_Count : Natural := 0;
   Total_Tick_Count : Natural := 0;
   Max_Ticks : constant Natural := 1;
   Time_Tick : HAL.UInt32 := 0;
   Time_Last_Tick : HAL.UInt32 := 0;

   Start_Us : HAL.UInt32;
   End_Us   : HAL.UInt32;
   Scheduler_Us  : HAL.UInt32;
   Max_Scheduler_Us : HAL.UInt32 := 0;
   Total_Time_Us : HAL.UInt32 := 0;
   Cycle_Count : HAL.UInt32 := 0;
   Print_Scheduler_Timing : constant Boolean := False;

   procedure Schedule_Next_Alarm;
   procedure Timer_Interrupt_Handler;

   procedure Schedule_Next_Alarm is
      Current_Time : constant HAL.UInt32 := TIMER_Periph.TIMELR;
   begin
      TIMER_Periph.ALARM0 := Current_Time + Tick_Interval_Us;
   end Schedule_Next_Alarm;

   procedure Timer_Interrupt_Handler is
   begin
      TIMER_Periph.INTR.ALARM_0 := True;
      Schedule_Next_Alarm;
      On_Tick;
   end Timer_Interrupt_Handler;

   procedure Initialize (tick_rate_hz : HAL.UInt32 := 1000) is
   begin
      if tick_rate_hz = 0 or else tick_rate_hz > 1_000_000 then
         SAPL.Processor.Fail_Safe (SAPL.Invalid_Tick_Rate);
      end if;

      Tick_Interval_Us := HAL.UInt32 (1_000_000) / tick_rate_hz;

      if Tick_Interval_Us = 0 then
         SAPL.Processor.Fail_Safe (SAPL.Invalid_Tick_Rate);
      end if;

      TIMER_Periph.INTE.ALARM_0 := False;
      TIMER_Periph.INTR.ALARM_0 := True;
   end Initialize;

   procedure Start is
      use RP2040_SVD.Interrupts;
   begin
      RP_Interrupts.Attach_Handler
         (Handler => Timer_Interrupt_Handler'Access,
          Id      => TIMER_IRQ_0_Interrupt,
          Prio    => System.Interrupt_Priority'First);

      TIMER_Periph.DBGPAUSE.DBG :=
         (As_Array => True, Arr => (0 => False, 1 => False));

      TIMER_Periph.INTR.ALARM_0 := True;
      Schedule_Next_Alarm;
      TIMER_Periph.INTE.ALARM_0 := True;
   end Start;

   procedure Dispatch_Tasks is
      Update_Required : Boolean := False;
      Tick_Rate_Hz : constant HAL.UInt32 := 1_000_000 / Tick_Interval_Us;
   begin
      Start_Us := TIMER_Periph.TIMELR;

      SAPL.Processor.Disable_Interrupts;
      if Tick_Count > 0 then
         Update_Required := True;
      end if;
      SAPL.Processor.Enable_Interrupts;

      while Update_Required loop
         for I in 1 .. Task_Count loop
            if Task_List (I).Delay_ticks > 0 then
               Task_List (I).Delay_ticks := Task_List (I).Delay_ticks - 1;
            end if;

            if Task_List (I).Delay_ticks = 0 then
               Task_List (I).Callback.all;
               if Task_List (I).Period_ticks > 0 then
                  Task_List (I).Delay_ticks := Task_List (I).Period_ticks;
               end if;
            end if;
         end loop;

         SAPL.Processor.Disable_Interrupts;
         Tick_Count := Tick_Count - 1;
         if Tick_Count > 0 then
            Update_Required := True;
         else
            Update_Required := False;
         end if;
         SAPL.Processor.Enable_Interrupts;
      end loop;

      End_Us := TIMER_Periph.TIMELR;
      Scheduler_Us := End_Us - Start_Us;
      Total_Time_Us := Total_Time_Us + Scheduler_Us;
      if Scheduler_Us > Max_Scheduler_Us then
         if Print_Scheduler_Timing then
            Max_Scheduler_Us := Scheduler_Us;
            COM.Debug.Put_Tx_String ("Scheduler time: " & Scheduler_Us'Image &
               Character'Val (13) & Character'Val (10));
         end if;
      end if;

      Cycle_Count := Cycle_Count + 1;
      if Cycle_Count > Tick_Rate_Hz then
         if Print_Scheduler_Timing then
            COM.Debug.Put_Tx_String ("Scheduler time: " & Scheduler_Us'Image &
               Character'Val (13) & Character'Val (10));
         end if;
         Cycle_Count := 0;
      end if;

      --  Switch CPU into lower power mode.
      SAPL.Processor.Wait_For_Interrupt;
   end Dispatch_Tasks;

   procedure On_Tick is
   begin
      Tick_Count := Tick_Count + 1;
      Total_Tick_Count := Total_Tick_Count + 1;
      Time_Last_Tick := Time_Tick;
      Time_Tick := TIMER_Periph.TIMELR;

      if Tick_Count > Max_Ticks then
         COM.Debug.Put_Tx_String ("Tick count overflow! Time tick: " &
            Time_Tick'Image & " Time last tick: " & Time_Last_Tick'Image &
            Character'Val (13) & Character'Val (10));
         SAPL.Processor.Fail_Safe (SAPL.Tick_Overflow);
      end if;
   end On_Tick;

   procedure Add_Task (Callback : not null Task_Callback;
      Delay_ticks : Integer; Period_ticks : Integer) is
      new_task : Scheduler_Task;
   begin
      new_task.Callback := Callback;
      --  +1 to account for the current tick
      new_task.Delay_ticks := Delay_ticks + 1;
      new_task.Period_ticks := Period_ticks;

      Task_List (Task_Count + 1) := new_task;
      Task_Count := Task_Count + 1;
   end Add_Task;

   function Get_Total_Tick_Count return Natural is
   begin
      return Total_Tick_Count;
   end Get_Total_Tick_Count;

end SAPL.Scheduler;