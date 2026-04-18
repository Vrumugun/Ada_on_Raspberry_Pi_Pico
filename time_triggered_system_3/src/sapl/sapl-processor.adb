with RP.Clock;
with RP.Device;
with RP.GPIO;
with Pico;
with System.Machine_Code; use System.Machine_Code;
with HAL;

with COM.Debug;

package body SAPL.Processor is
   Local_Cpu_Id : Cpu_Id := Cpu_Unknown;

   procedure Initialize is
   begin
      RP.Clock.Initialize (Pico.XOSC_Frequency);
      RP.Clock.Enable (RP.Clock.PERI);
      RP.Device.Timer.Enable;
      RP.GPIO.Enable;
      Read_Cpu_Id;
      --  LED_TX.Configure_Output;
      --  LED_TX.Set (True);
   end Initialize;

   procedure Fail_Safe (Error_Code : Fail_Safe_Error_Codes) is
      Time : HAL.UInt32;
   begin
      Disable_Interrupts;
      --  LED_TX.Set (False);
      Time := COM.Debug.Get_Update_Time_Us;
      COM.Debug.Put_Tx_String ("Fail Safe! " & Error_Code'Image &
         " Time: " & Time'Image &
         Character'Val (13) & Character'Val (10));
      loop
         --  for debugging purposes, print the fail safe message.
         COM.Debug.Update;
      end loop;
   end Fail_Safe;

   procedure Disable_Interrupts is
   begin
      Asm ("cpsid i", Volatile => True);
   end Disable_Interrupts;

   procedure Enable_Interrupts is
   begin
      Asm ("cpsie i", Volatile => True);
   end Enable_Interrupts;

   procedure Wait_For_Interrupt is
   begin
      Asm ("wfi", Volatile => True);
   end Wait_For_Interrupt;

   function Get_Cpu_Id return Cpu_Id is
   begin
      return Local_Cpu_Id;
   end Get_Cpu_Id;

   procedure Read_Cpu_Id is
   begin
      Pico.GP2.Configure (RP.GPIO.Input);
      Pico.GP3.Configure (RP.GPIO.Output);
      Pico.GP3.Set;
      if Pico.GP2.Get = True then
         Local_Cpu_Id := Cpu_Top;
         COM.Debug.Put_Tx_String ("CPU TOP" & Character'Val (13) &
            Character'Val (10));
      else
         Local_Cpu_Id := Cpu_Bottom;
         COM.Debug.Put_Tx_String ("CPU BOTTOM" & Character'Val (13) &
            Character'Val (10));
      end if;
   end Read_Cpu_Id;

end SAPL.Processor;