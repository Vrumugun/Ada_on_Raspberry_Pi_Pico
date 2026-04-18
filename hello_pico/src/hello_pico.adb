with RP.Device;
with RP.Clock;
with RP.GPIO;
with Pico;

procedure Hello_Pico is
begin
   RP.Clock.Initialize (Pico.XOSC_Frequency);
   RP.Device.Timer.Enable;
   Pico.LED.Configure (RP.GPIO.Output);

   loop
      Pico.LED.Toggle;
      RP.Device.Timer.Delay_Milliseconds (250);
   end loop;
end Hello_Pico;
