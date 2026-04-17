with RP.Device;
with RP.Clock;
with RP.GPIO;
with Pico;

with HAL; use HAL;

with USB_Serial;

procedure Usb_Test is
   Rx_Message     : String (1 .. 64);
   Rx_Length      : HAL.UInt32;
   Tick_Count     : Natural := 0;
   Send_Period_Ms : constant Natural := 1_000;
   Greeting       : constant String :=
     "Custom USB CDC ready" & Character'Val (13) & Character'Val (10);
begin
   RP.Clock.Initialize (Pico.XOSC_Frequency);
   RP.Device.Timer.Enable;
   Pico.LED.Configure (RP.GPIO.Output);
   Pico.LED.Set;

   RP.Device.Timer.Delay_Milliseconds (1000);
   USB_Serial.Initialize;

   loop
      USB_Serial.Poll;

      if USB_Serial.Connected then
         USB_Serial.Read (Rx_Message, Rx_Length);

         if Rx_Length > 0 then
            USB_Serial.Write (Rx_Message (1 .. Natural (Rx_Length)));
            Pico.LED.Toggle;
         elsif Tick_Count = 0 then
            USB_Serial.Write (Greeting);
            Tick_Count := Send_Period_Ms;
         else
            Tick_Count := Tick_Count - 1;
         end if;
      end if;

      RP.Device.Timer.Delay_Milliseconds (1);
   end loop;
end Usb_Test;
