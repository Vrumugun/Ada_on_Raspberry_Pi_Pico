with SAPL.Input;
with SAPL.Processor;
with Pico;
with RP.GPIO;
with COM.Debug;

package body SAPL.Output is

   use type HAL.UInt32;

   Output_State : Boolean := False;
   Output_Timer : HAL.UInt32 := 0;
   Max_Output_Timer : constant HAL.UInt32 := 5;

   procedure Initialize is
   begin
      --  Initialization code for output handling
      Pico.GP22.Configure (RP.GPIO.Output);
      Pico.GP26.Configure (RP.GPIO.Input);
   end Initialize;

   procedure Update is
   begin
      --  Update code for output handling
      Control_Output;
      Verify_Output_State;
   end Update;

   procedure Control_Output is
      --  Code to control the output based on the input state
   begin
      if SAPL.Input.Get_Input_State and then not Output_State then
         Output_State := True;
         Pico.GP22.Set;
         COM.Debug.Put_Tx_String (Output_State'Image & Character'Val (13) &
            Character'Val (10));
      elsif not SAPL.Input.Get_Input_State and then Output_State then
         Output_State := False;
         Pico.GP22.Clear;
         COM.Debug.Put_Tx_String (Output_State'Image & Character'Val (13) &
            Character'Val (10));
      end if;
   end Control_Output;

   procedure Verify_Output_State is
      --  Input GP26 reads back the state of output GP22.
   begin
      if Pico.GP26.Get then
         if not Output_State then
            if Output_Timer < Max_Output_Timer then
               Output_Timer := Output_Timer + 1;
            else
               SAPL.Processor.Fail_Safe (SAPL.Output_Error);
            end if;
         else
            Output_Timer := 0;
         end if;
      else
         if Output_State then
            if Output_Timer < Max_Output_Timer then
               Output_Timer := Output_Timer + 1;
            else
               SAPL.Processor.Fail_Safe (SAPL.Output_Error);
            end if;
         else
            Output_Timer := 0;
         end if;
      end if;
   end Verify_Output_State;

end SAPL.Output;