with RP.GPIO;
with Pico;
with COM.Debug;

with SAPL.Processor;

package body SAPL.Heartbeat is
   use type HAL.UInt32;

   Counter : HAL.UInt32 := 0;
   Counter_Duplicate : HAL.UInt32 := (2 ** 32 - 1);

   State : Boolean := False;

   procedure Initialize is
   begin
      Pico.LED.Configure (RP.GPIO.Output);
      Pico.GP18.Configure (RP.GPIO.Output);
      
      Pico.GP4.Configure (RP.GPIO.Output);
      Pico.GP5.Configure (RP.GPIO.Input);

   end Initialize;

   procedure Update is
   begin
      Pico.GP4.Set;
      if Pico.GP5.Get = True and State = False then
         State := True;
         COM.Debug.Put_Tx_String (State'Image & Character'Val (13) & Character'Val (10));
      elsif Pico.GP5.Get = False and State = True then
         State := False;
         COM.Debug.Put_Tx_String (State'Image & Character'Val (13) & Character'Val (10));
      end if;
      if SAPL.Verify_Duplicate_Variable (Counter, Counter_Duplicate) then
         Pico.LED.Toggle;
         Pico.GP18.Toggle;
         Counter := Counter + 1;
         Counter_Duplicate := Counter xor (2 ** 32 - 1);
         if Counter mod 10 = 0 then
            COM.Debug.Put_Tx_String ("Heartbeat! " & Counter'Image &
               Character'Val (13) & Character'Val (10));
         end if;
      else
         SAPL.Processor.Fail_Safe (SAPL.Data_Corruption);
      end if;
   end Update;

end SAPL.Heartbeat;