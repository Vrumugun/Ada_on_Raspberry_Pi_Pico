package body SAPL is
   use type HAL.UInt32;

   function Verify_Duplicate_Variable
      (Value, Value_Duplicate : HAL.UInt32) return Boolean is
      Temp : constant HAL.UInt32 := Value_Duplicate xor HAL.UInt32'Last;
   begin
      return Value = Temp;
   end Verify_Duplicate_Variable;

end SAPL;