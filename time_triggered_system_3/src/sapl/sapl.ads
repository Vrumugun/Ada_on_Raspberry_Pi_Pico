with HAL;

package SAPL is

   type Fail_Safe_Error_Codes is
      (
         None,
         Watchdog_Expired,
         Invalid_Tick_Rate,
         Tick_Overflow,
         Data_Corruption,
         Output_Error,
         Unknown_Cpu
      );

   function Verify_Duplicate_Variable
      (Value, Value_Duplicate : HAL.UInt32) return Boolean;

end SAPL;