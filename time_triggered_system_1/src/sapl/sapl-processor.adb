with RP.Clock;
with RP.Device;
with Pico;
with System.Machine_Code; use System.Machine_Code;
with HAL;

with COM.Debug;

package body SAPL.Processor is
   --  LED_TX   : RP.GPIO.Pin
     --  renames Pico.LED;

   procedure Initialize is
   begin
      RP.Clock.Initialize (Pico.XOSC_Frequency);
      RP.Device.Timer.Enable;
      --  LED_TX.Configure_Output;
      --  LED_TX.Set (True);
   end Initialize;

   procedure Fail_Safe (Error_Code : Fail_Safe_Error_Codes) is
      Time: HAL.UInt32;
   begin
      Disable_Interrupts;
      --  LED_TX.Set (False);
      Time := COM.Debug.Get_Update_Time_Us;
      COM.Debug.Put_Tx_String ("Fail Safe! " & Error_Code'Image & " Time: " & Time'Image &
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

end SAPL.Processor;