with RP.Watchdog;

package body SAPL.Watchdog is
   procedure Initialize (Timeout_Ms : Positive := 1000) is
   begin
      RP.Watchdog.Configure (Timeout => RP.Watchdog.Milliseconds (Timeout_Ms));
   end Initialize;

   procedure Update is
   begin
      RP.Watchdog.Reload;
   end Update;

end SAPL.Watchdog;