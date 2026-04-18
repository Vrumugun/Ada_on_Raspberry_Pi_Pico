package SAPL.Input is

   procedure Initialize;
   procedure Update;

   function Get_Input_State return Boolean;

private
   procedure Filter_Input;

end SAPL.Input;