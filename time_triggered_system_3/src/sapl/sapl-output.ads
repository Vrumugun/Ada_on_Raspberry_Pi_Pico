package SAPL.Output is

   procedure Initialize;
   procedure Update;
   procedure Set_Output_State (State : Boolean);
   function Get_Output_State return Boolean;

private
   procedure Control_Output;
   procedure Verify_Output_State;

end SAPL.Output;